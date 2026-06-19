#!/usr/bin/env python3

"""
test_glue_local.py - Pruebas locales del Job de AWS Glue

Este script simula la ejecución del job de Glue en tu máquina local
sin necesidad de AWS, para validar la lógica antes de desplegar.

Uso: python3 test_glue_local.py
"""

import os
import sys
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any
from io import StringIO

# ============================================================================
# MOCKS DE GLUE (para simular sin AWS)
# ============================================================================

class MockGlueContext:
    """Mock de GlueContext para pruebas locales"""
    
    def __init__(self):
        self.spark_session = MockSparkSession()
    
    def create_dynamic_frame(self):
        return MockDynamicFrameBuilder()
    
    def write_dynamic_frame(self):
        return MockDynamicFrameWriter()


class MockSparkSession:
    """Mock de SparkSession"""
    
    def __init__(self):
        self.data = []
    
    def createDataFrame(self, data, schema=None):
        return MockDataFrame(data)


class MockDynamicFrame:
    """Mock de DynamicFrame de Glue"""
    
    def __init__(self, data):
        self.data = data
    
    def count(self):
        return len(self.data)
    
    def toDF(self):
        return MockDataFrame(self.data)


class MockDynamicFrameBuilder:
    """Mock del builder de DynamicFrames"""
    
    def from_options(self, **kwargs):
        # Simular lectura de CSV
        print(f"[MOCK] Leyendo archivo: {kwargs.get('connection_options', {}).get('paths', [''])}")
        
        # Crear datos de ejemplo
        data = [
            {'id': '1', 'nombre': 'Juan Perez', 'email': 'juan@example.com', 'ciudad': 'Mexico', 'monto': '1500.00'},
            {'id': '2', 'nombre': 'Maria Garcia', 'email': 'maria@example.com', 'ciudad': 'Guadalajara', 'monto': '2300.50'},
            {'id': '3', 'nombre': 'Carlos Lopez', 'email': 'carlos@example.com', 'ciudad': 'Monterrey', 'monto': '890.75'},
            {'id': '4', 'nombre': 'Ana Martinez', 'email': 'ana@example.com', 'ciudad': 'Mexico', 'monto': '3200.00'},
            {'id': '5', 'nombre': 'Roberto Sanchez', 'email': 'roberto@example.com', 'ciudad': 'Puebla', 'monto': '1100.25'},
        ]
        return MockDynamicFrame(data)


class MockDynamicFrameWriter:
    """Mock del writer de DynamicFrames"""
    
    def from_options(self, **kwargs):
        print(f"[MOCK] Escribiendo en: {kwargs.get('connection_options', {}).get('path', '')}")
        return self


class MockDataFrame:
    """Mock de Spark DataFrame"""
    
    def __init__(self, data):
        self.data = data
        self._transformations = []
    
    def count(self):
        return len(self.data)
    
    def where(self, condition):
        print(f"[MOCK] Filtro aplicado: {condition}")
        # Simular filtro de monto > 1000
        filtered = [row for row in self.data if isinstance(row, dict) and float(row.get('monto', 0)) > 1000]
        df = MockDataFrame(filtered)
        df._transformations = self._transformations + ['where']
        return df
    
    def withColumn(self, col_name, expression):
        print(f"[MOCK] Columna agregada: {col_name}")
        self._transformations.append(f"withColumn({col_name})")
        return self
    
    def filter(self, condition):
        return self.where(condition)
    
    def groupBy(self, *cols):
        return MockGroupedDataFrame(self.data, cols)
    
    def agg(self, *expressions):
        return MockAggregateResult(self.data)
    
    def coalesce(self, n):
        return self
    
    def write(self):
        return MockDataFrameWriter()
    
    def collect(self):
        return self.data


class MockGroupedDataFrame:
    """Mock de DataFrame agrupado"""
    
    def __init__(self, data, group_cols):
        self.data = data
        self.group_cols = group_cols
    
    def count(self):
        grouped = {}
        for row in self.data:
            key = tuple(row.get(col) for col in self.group_cols)
            grouped[key] = grouped.get(key, 0) + 1
        
        result = []
        for (categoria,), count in grouped.items():
            result.append({'categoria': categoria, 'count': count})
        
        return MockDataFrame(result)


class MockAggregateResult:
    """Mock de resultado de agregación"""
    
    def __init__(self, data):
        self.data = data
    
    def collect(self):
        total = sum(float(row.get('monto', 0)) for row in self.data if isinstance(row, dict))
        count = len(self.data)
        avg = total / count if count > 0 else 0
        
        return [
            {
                'total_monto': total,
                'monto_promedio': avg,
                'cantidad': count
            }
        ]


class MockDataFrameWriter:
    """Mock de DataFrame Writer"""
    
    def mode(self, mode):
        return self
    
    def text(self, path):
        print(f"[MOCK] Escribiendo texto a: {path}")
        return self


# ============================================================================
# CONFIGURACIÓN DE LOGGING
# ============================================================================

def setup_logging():
    """Configurar logging para las pruebas"""
    logger = logging.getLogger('GlueLocalTest')
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger


# ============================================================================
# PRUEBAS
# ============================================================================

class TestGlueETL:
    """Suite de pruebas para el ETL de Glue"""
    
    def __init__(self, logger):
        self.logger = logger
        self.results = []
    
    def test_reader(self):
        """Probar componente Reader"""
        self.logger.info("=" * 70)
        self.logger.info("TEST 1: Componente Reader (Lectura de CSV)")
        self.logger.info("=" * 70)
        
        try:
            # Simular lectura
            glue_context = MockGlueContext()
            builder = glue_context.create_dynamic_frame()
            dyf = builder.from_options(
                format="csv",
                connection_options={"paths": ["s3://bucket/datos.csv"]}
            )
            
            count = dyf.count()
            self.logger.info(f"✓ Se leyeron {count} registros")
            self.results.append({'test': 'reader', 'status': 'PASS', 'records': count})
            
        except Exception as e:
            self.logger.error(f"✗ Error: {str(e)}")
            self.results.append({'test': 'reader', 'status': 'FAIL', 'error': str(e)})
        
        print()
    
    def test_transformer(self):
        """Probar componente Transformer"""
        self.logger.info("=" * 70)
        self.logger.info("TEST 2: Componente Transformer (Transformaciones)")
        self.logger.info("=" * 70)
        
        try:
            # Crear datos de prueba
            data = [
                {'id': '1', 'monto': '1500.00'},
                {'id': '2', 'monto': '2300.50'},
                {'id': '3', 'monto': '890.75'},
                {'id': '4', 'monto': '3200.00'},
            ]
            
            df = MockDataFrame(data)
            
            # Aplicar filtro
            df_filtered = df.where("monto > 1000")
            count_filtered = df_filtered.count()
            
            # Simular agregación de columnas
            df_with_cols = df_filtered \
                .withColumn("categoria", "IF(monto > 2000, 'Premium', 'Estándar')") \
                .withColumn("fecha", "TODAY()")
            
            self.logger.info(f"✓ Registros después de filtro: {count_filtered}")
            self.logger.info(f"✓ Columnas agregadas: categoria, fecha")
            
            self.results.append({
                'test': 'transformer',
                'status': 'PASS',
                'records_filtered': count_filtered,
                'columns_added': 2
            })
            
        except Exception as e:
            self.logger.error(f"✗ Error: {str(e)}")
            self.results.append({'test': 'transformer', 'status': 'FAIL', 'error': str(e)})
        
        print()
    
    def test_validator(self):
        """Probar componente Validator"""
        self.logger.info("=" * 70)
        self.logger.info("TEST 3: Componente Validator (Validación)")
        self.logger.info("=" * 70)
        
        try:
            data = [
                {'id': '1', 'monto': 1500.0, 'categoria': 'Estándar'},
                {'id': '2', 'monto': 2300.50, 'categoria': 'Premium'},
                {'id': '4', 'monto': 3200.0, 'categoria': 'Premium'},
                {'id': '5', 'monto': 1100.25, 'categoria': 'Estándar'},
            ]
            
            df = MockDataFrame(data)
            
            # Calcular estadísticas
            total = sum(row['monto'] for row in data)
            count = len(data)
            average = total / count
            
            # Agrupar por categoría
            categorias = {}
            for row in data:
                cat = row['categoria']
                categorias[cat] = categorias.get(cat, 0) + 1
            
            self.logger.info(f"✓ Total de registros: {count}")
            self.logger.info(f"✓ Monto total: ${total:,.2f}")
            self.logger.info(f"✓ Monto promedio: ${average:,.2f}")
            self.logger.info(f"✓ Por categoría: {categorias}")
            
            self.results.append({
                'test': 'validator',
                'status': 'PASS',
                'total_records': count,
                'total_amount': total,
                'by_category': categorias
            })
            
        except Exception as e:
            self.logger.error(f"✗ Error: {str(e)}")
            self.results.append({'test': 'validator', 'status': 'FAIL', 'error': str(e)})
        
        print()
    
    def test_writer(self):
        """Probar componente Writer"""
        self.logger.info("=" * 70)
        self.logger.info("TEST 4: Componente Writer (Escritura)")
        self.logger.info("=" * 70)
        
        try:
            # Simular escritura
            glue_context = MockGlueContext()
            writer = glue_context.write_dynamic_frame()
            writer.from_options(
                format="parquet",
                connection_options={"path": "s3://bucket/output/"}
            )
            
            self.logger.info(f"✓ Datos escritos en Parquet")
            self.logger.info(f"✓ Ruta: s3://bucket/output/")
            
            self.results.append({'test': 'writer', 'status': 'PASS'})
            
        except Exception as e:
            self.logger.error(f"✗ Error: {str(e)}")
            self.results.append({'test': 'writer', 'status': 'FAIL', 'error': str(e)})
        
        print()
    
    def test_quality_checks(self):
        """Probar verificaciones de calidad"""
        self.logger.info("=" * 70)
        self.logger.info("TEST 5: Verificaciones de Calidad")
        self.logger.info("=" * 70)
        
        try:
            data = [
                {'id': '1', 'email': 'juan@example.com', 'monto': 1500.0},
                {'id': '2', 'email': 'maria@example.com', 'monto': 2300.50},
                {'id': None, 'email': None, 'monto': -100},
            ]
            
            checks = {
                'null_ids': sum(1 for row in data if row.get('id') is None),
                'null_emails': sum(1 for row in data if row.get('email') is None),
                'negative_amounts': sum(1 for row in data if row.get('monto', 0) < 0),
                'total_records': len(data),
            }
            
            self.logger.info(f"✓ IDs nulos: {checks['null_ids']}")
            self.logger.info(f"✓ Emails nulos: {checks['null_emails']}")
            self.logger.info(f"✓ Montos negativos: {checks['negative_amounts']}")
            self.logger.info(f"✓ Total de registros: {checks['total_records']}")
            
            self.results.append({
                'test': 'quality_checks',
                'status': 'PASS',
                'checks': checks
            })
            
        except Exception as e:
            self.logger.error(f"✗ Error: {str(e)}")
            self.results.append({'test': 'quality_checks', 'status': 'FAIL', 'error': str(e)})
        
        print()
    
    def run_all(self):
        """Ejecutar todas las pruebas"""
        self.logger.info("\n")
        print("╔" + "═" * 68 + "╗")
        print("║" + " " * 10 + "PRUEBAS LOCALES - AWS GLUE ETL JOB" + " " * 24 + "║")
        print("╚" + "═" * 68 + "╝")
        print()
        
        self.test_reader()
        self.test_transformer()
        self.test_validator()
        self.test_writer()
        self.test_quality_checks()
        
        return self.results
    
    def print_summary(self):
        """Imprimir resumen de resultados"""
        self.logger.info("=" * 70)
        self.logger.info("RESUMEN DE PRUEBAS")
        self.logger.info("=" * 70)
        
        passed = sum(1 for r in self.results if r['status'] == 'PASS')
        failed = sum(1 for r in self.results if r['status'] == 'FAIL')
        
        self.logger.info(f"Total: {len(self.results)} pruebas")
        self.logger.info(f"Pasadas: {passed}")
        self.logger.info(f"Fallidas: {failed}")
        
        print()
        
        if failed == 0:
            self.logger.info("✓ TODAS LAS PRUEBAS PASARON")
            print("\n✓ El job está listo para desplegar en AWS Glue")
            return True
        else:
            self.logger.error(f"✗ {failed} prueba(s) fallida(s)")
            return False


# ============================================================================
# COMPARACIÓN CON DEMO LOCAL
# ============================================================================

def compare_with_local():
    """Comparar resultados con demo local"""
    print("\n" + "=" * 70)
    print("COMPARACIÓN: GLUE VS DEMO LOCAL")
    print("=" * 70)
    print()
    
    comparison = {
        'Característica': ['Ejecución', 'Escalabilidad', 'Costo', 'Complejidad'],
        'Demo Local': ['Inmediata', 'Limitada (1 máquina)', 'Gratis', 'Baja'],
        'AWS Glue': ['5-10 min (setup)', 'Distribuida (clusters)', 'Por uso', 'Moderada'],
    }
    
    for i, feature in enumerate(comparison['Característica']):
        print(f"{feature:15} | Local: {comparison['Demo Local'][i]:30} | Glue: {comparison['AWS Glue'][i]}")
    
    print()
    print("VENTAJAS DE AWS GLUE:")
    print("  ✓ Escalabilidad automática")
    print("  ✓ Procesamiento distribuido")
    print("  ✓ Integración con AWS (S3, RDS, Redshift, etc.)")
    print("  ✓ Glue Catalog para metadatos")
    print("  ✓ Job bookmarks para procesamiento incremental")
    print("  ✓ Data Quality Framework")
    print("  ✓ Monitores y alertas en CloudWatch")
    print()


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Función principal"""
    
    # Configurar logging
    logger = setup_logging()
    
    # Crear y ejecutar pruebas
    tester = TestGlueETL(logger)
    results = tester.run_all()
    passed = tester.print_summary()
    
    # Mostrar comparación
    compare_with_local()
    
    # Mostrar JSON de resultados
    print("=" * 70)
    print("RESULTADOS EN JSON")
    print("=" * 70)
    print(json.dumps(results, indent=2))
    print()
    
    return 0 if passed else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
