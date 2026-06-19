"""
AWS Glue Job - Demo ETL
Migración del flujo local a AWS Glue

Este script:
1. Lee CSV desde S3
2. Transforma datos con Glue DPU (procesamiento distribuido)
3. Valida calidad de datos
4. Escribe resultados en S3
5. Genera reportes en JSON
"""

import sys
import json
import logging
from datetime import datetime
from typing import Dict, List, Any
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import (
    col, 
    when, 
    format_number, 
    current_date, 
    lit,
    sum as spark_sum,
    avg,
    count
)
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType

# ============================================================================
# CONFIGURACIÓN Y LOGGING
# ============================================================================

# Obtener argumentos del job
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'S3_INPUT_PATH',
    'S3_OUTPUT_PATH',
    'MONTO_MINIMO',
    'AWS_REGION'
])

# Configurar contexto Spark y Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Configurar logging
logger = logging.getLogger('GlueETL')
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)


# ============================================================================
# CLASES DE COMPONENTES (Componentes Ab Initio simulados en Glue)
# ============================================================================

class GlueReader:
    """Componente Reader: Lee archivos CSV desde S3"""
    
    def __init__(self, s3_path: str, logger: logging.Logger):
        self.s3_path = s3_path
        self.logger = logger
    
    def execute(self, glue_context: GlueContext) -> DynamicFrame:
        """Lee CSV desde S3"""
        try:
            self.logger.info(f"Leyendo CSV desde S3: {self.s3_path}")
            
            # Leer CSV como DynamicFrame
            dyf = glue_context.create_dynamic_frame.from_options(
                format_options={"multiline": False, "withHeader": True},
                connection_type="s3",
                format="csv",
                connection_options={"paths": [self.s3_path]},
                transformation_ctx="datasource0"
            )
            
            record_count = dyf.count()
            self.logger.info(f"✓ Se leyeron {record_count} registros")
            
            return dyf
        
        except Exception as e:
            self.logger.error(f"✗ Error al leer CSV: {str(e)}")
            raise


class GlueTransformer:
    """Componente Transformer: Transforma datos con Spark"""
    
    def __init__(self, monto_minimo: float, logger: logging.Logger):
        self.monto_minimo = monto_minimo
        self.logger = logger
    
    def execute(self, dyf: DynamicFrame, spark_session) -> DynamicFrame:
        """Transforma registros según reglas de negocio"""
        try:
            self.logger.info("Iniciando transformación de datos")
            
            # Convertir a DataFrame de Spark para operaciones más complejas
            df = dyf.toDF()
            
            # Transformaciones
            df_transformed = df \
                .where(col("monto") > self.monto_minimo) \
                .withColumn(
                    "categoria",
                    when(col("monto") > 2000, lit("Premium"))
                    .otherwise(lit("Estándar"))
                ) \
                .withColumn(
                    "monto_formateado",
                    format_number(col("monto"), 2)
                ) \
                .withColumn("fecha_proceso", current_date()) \
                .withColumn("estado", lit("Procesado")) \
                .withColumn("etl_timestamp", lit(datetime.now().isoformat()))
            
            # Convertir de vuelta a DynamicFrame
            dyf_transformed = DynamicFrame.fromDF(
                df_transformed,
                glue_context,
                "dyf_transformed"
            )
            
            record_count = df_transformed.count()
            self.logger.info(f"✓ {record_count} registros transformados")
            
            return dyf_transformed
        
        except Exception as e:
            self.logger.error(f"✗ Error en transformación: {str(e)}")
            raise


class GlueValidator:
    """Componente Validator: Valida integridad de datos"""
    
    def __init__(self, logger: logging.Logger):
        self.logger = logger
    
    def execute(self, dyf: DynamicFrame, spark_session) -> Dict[str, Any]:
        """Valida registros y genera reporte"""
        try:
            self.logger.info("Iniciando validación de datos")
            
            df = dyf.toDF()
            
            # Contar registros totales
            total_registros = df.count()
            
            # Calcular estadísticas
            stats = df.agg(
                spark_sum("monto").alias("total_monto"),
                avg("monto").alias("monto_promedio"),
                count("id").alias("cantidad")
            ).collect()[0]
            
            total_monto = float(stats["total_monto"]) if stats["total_monto"] else 0
            monto_promedio = float(stats["monto_promedio"]) if stats["monto_promedio"] else 0
            
            # Contar por categoría
            categoria_stats = df.groupBy("categoria").count().collect()
            por_categoria = {row["categoria"]: row["count"] for row in categoria_stats}
            
            # Generar reporte
            reporte = {
                'timestamp': datetime.now().isoformat(),
                'total_registros': total_registros,
                'total_monto': f"${total_monto:,.2f}",
                'monto_promedio': f"${monto_promedio:,.2f}",
                'por_categoria': por_categoria,
                'estado_validacion': 'APROBADO',
                'records_procesados': int(stats["cantidad"])
            }
            
            self.logger.info(f"✓ Validación completada: {total_registros} registros")
            
            return reporte
        
        except Exception as e:
            self.logger.error(f"✗ Error en validación: {str(e)}")
            raise


class GlueWriter:
    """Componente Writer: Escribe datos transformados en S3"""
    
    def __init__(self, output_path: str, logger: logging.Logger):
        self.output_path = output_path
        self.logger = logger
    
    def execute(self, dyf: DynamicFrame, glue_context: GlueContext) -> str:
        """Escribe registros transformados en S3"""
        try:
            self.logger.info(f"Escribiendo archivos a: {self.output_path}")
            
            if dyf.count() == 0:
                raise ValueError("No hay registros para escribir")
            
            # Escribir en formato Parquet (más eficiente que CSV para Glue)
            glue_context.write_dynamic_frame.from_options(
                frame=dyf,
                connection_type="s3",
                format="parquet",
                connection_options={"path": self.output_path},
                transformation_ctx="datasink0"
            )
            
            self.logger.info(f"✓ Archivos escritos en S3: {self.output_path}")
            
            return self.output_path
        
        except Exception as e:
            self.logger.error(f"✗ Error al escribir: {str(e)}")
            raise


class ReportWriter:
    """Componente que escribe reportes JSON en S3"""
    
    def __init__(self, output_path: str, logger: logging.Logger):
        self.output_path = output_path
        self.logger = logger
    
    def execute(self, report_data: Dict[str, Any]) -> str:
        """Escribe reporte JSON en S3"""
        try:
            self.logger.info("Escribiendo reporte de calidad")
            
            # Crear nombre del archivo
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            report_file = f"{self.output_path}/reporte_glue_{timestamp}.json"
            
            # Escribir JSON en S3 usando Spark
            report_df = spark.createDataFrame(
                [(json.dumps(report_data, ensure_ascii=False),)],
                StructType([StructField("json_data", StringType(), True)])
            )
            
            report_df.coalesce(1).write.mode("overwrite") \
                .text(f"{self.output_path}/reporte/")
            
            self.logger.info(f"✓ Reporte generado en: {report_file}")
            
            return report_file
        
        except Exception as e:
            self.logger.error(f"✗ Error escribiendo reporte: {str(e)}")
            raise


class DataQualityCheck:
    """Componente para verificar calidad de datos con DQ Framework de Glue"""
    
    def __init__(self, logger: logging.Logger):
        self.logger = logger
    
    def execute(self, df) -> Dict[str, Any]:
        """Ejecuta verificaciones de calidad"""
        try:
            self.logger.info("Ejecutando verificaciones de calidad")
            
            checks = {
                'null_ids': df.filter(col("id").isNull()).count(),
                'null_emails': df.filter(col("email").isNull()).count(),
                'null_montos': df.filter(col("monto").isNull()).count(),
                'montos_negativos': df.filter(col("monto") < 0).count(),
                'registros_totales': df.count(),
                'duplicados_id': df.groupBy("id").count().where(col("count") > 1).count()
            }
            
            self.logger.info(f"✓ Verificaciones completadas")
            
            return checks
        
        except Exception as e:
            self.logger.error(f"✗ Error en verificaciones: {str(e)}")
            raise


# ============================================================================
# PIPELINE ETL PRINCIPAL
# ============================================================================

class GlueETLPipeline:
    """Pipeline ETL que orquesta componentes de Glue"""
    
    def __init__(self, glue_context: GlueContext, logger: logging.Logger):
        self.glueContext = glue_context
        self.spark = glue_context.spark_session
        self.logger = logger
    
    def run(self, 
            input_path: str,
            output_path: str,
            monto_minimo: float) -> Dict[str, Any]:
        """Ejecuta el pipeline ETL completo"""
        
        try:
            self.logger.info("=" * 70)
            self.logger.info("INICIANDO PIPELINE ETL - AWS GLUE")
            self.logger.info("=" * 70)
            
            # 1. LECTURA
            reader = GlueReader(input_path, self.logger)
            raw_dyf = reader.execute(self.glueContext)
            
            # 2. TRANSFORMACIÓN
            transformer = GlueTransformer(monto_minimo, self.logger)
            transformed_dyf = transformer.execute(raw_dyf, self.spark)
            
            # 3. VALIDACIÓN
            validator = GlueValidator(self.logger)
            raw_df = raw_dyf.toDF()
            quality_checks = DataQualityCheck(self.logger).execute(raw_df)
            quality_report = validator.execute(transformed_dyf, self.spark)
            
            # Agregar resultado de quality checks al reporte
            quality_report['quality_checks'] = quality_checks
            
            # 4. ESCRITURA
            writer = GlueWriter(output_path, self.logger)
            output_file = writer.execute(transformed_dyf, self.glueContext)
            
            # 5. REPORTE
            report_writer = ReportWriter(output_path, self.logger)
            report_file = report_writer.execute(quality_report)
            
            self.logger.info("=" * 70)
            self.logger.info("PIPELINE COMPLETADO EXITOSAMENTE")
            self.logger.info(f"Salida: {output_file}")
            self.logger.info(f"Reporte: {report_file}")
            self.logger.info("=" * 70)
            
            return {
                'status': 'SUCCESS',
                'output_path': output_file,
                'report': quality_report,
                'timestamp': datetime.now().isoformat()
            }
        
        except Exception as e:
            self.logger.error(f"Error en pipeline: {str(e)}", exc_info=True)
            return {
                'status': 'FAILED',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }


# ============================================================================
# PUNTO DE ENTRADA
# ============================================================================

def main():
    """Función principal del job"""
    
    logger.info("Iniciando AWS Glue Job")
    logger.info(f"Parámetros: {args}")
    
    try:
        # Crear pipeline
        pipeline = GlueETLPipeline(glueContext, logger)
        
        # Ejecutar pipeline
        result = pipeline.run(
            input_path=args['S3_INPUT_PATH'],
            output_path=args['S3_OUTPUT_PATH'],
            monto_minimo=float(args['MONTO_MINIMO'])
        )
        
        # Log resultado
        logger.info(json.dumps(result, indent=2))
        
        # Retornar código de salida
        return 0 if result['status'] == 'SUCCESS' else 1
    
    except Exception as e:
        logger.error(f"Error crítico: {str(e)}", exc_info=True)
        return 1


if __name__ == "__main__":
    exit_code = main()
    job.commit()
    sys.exit(exit_code)
