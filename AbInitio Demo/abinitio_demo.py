#!/usr/bin/env python3

"""
DEMO AB INITIO EN PYTHON
Simula la arquitectura de componentes de Ab Initio
- Reader: Lee el archivo CSV
- Transformer: Transforma los datos
- Writer: Escribe en directorio de destino
- Logger: Registra operaciones
"""

import csv
import os
import sys
import json
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any
from abc import ABC, abstractmethod


class Component(ABC):
    """Clase base para componentes Ab Initio"""
    
    def __init__(self, name: str):
        self.name = name
        self.logger = logging.getLogger(name)
    
    @abstractmethod
    def execute(self, data: Any) -> Any:
        """Ejecutar componente"""
        pass


class CSVReader(Component):
    """Componente Reader: Lee archivos CSV"""
    
    def __init__(self, filepath: str, name: str = "CSVReader"):
        super().__init__(name)
        self.filepath = filepath
    
    def execute(self, data=None) -> List[Dict[str, str]]:
        """Lee CSV y retorna lista de diccionarios"""
        try:
            self.logger.info(f"Leyendo archivo: {self.filepath}")
            
            if not os.path.exists(self.filepath):
                raise FileNotFoundError(f"Archivo no encontrado: {self.filepath}")
            
            records = []
            with open(self.filepath, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    records.append(row)
            
            self.logger.info(f"✓ Se leyeron {len(records)} registros")
            return records
        
        except Exception as e:
            self.logger.error(f"✗ Error al leer CSV: {e}")
            raise


class DataTransformer(Component):
    """Componente Transformer: Procesa y transforma datos"""
    
    def __init__(self, name: str = "DataTransformer"):
        super().__init__(name)
    
    def execute(self, records: List[Dict]) -> List[Dict]:
        """Transforma registros según reglas de negocio"""
        try:
            self.logger.info("Iniciando transformación de datos")
            transformed = []
            
            for record in records:
                # Validar y transformar
                try:
                    monto = float(record['monto'])
                    
                    # Filtrar: solo montos > 1000
                    if monto > 1000:
                        # Agregar categoría
                        if monto > 2000:
                            categoria = "Premium"
                        else:
                            categoria = "Estándar"
                        
                        record['categoria'] = categoria
                        record['monto_formateado'] = f"${monto:,.2f}"
                        record['fecha_proceso'] = datetime.now().strftime("%Y-%m-%d")
                        record['estado'] = "Procesado"
                        
                        transformed.append(record)
                
                except ValueError:
                    self.logger.warning(f"Monto inválido para {record['id']}")
                    continue
            
            self.logger.info(f"✓ {len(transformed)} registros transformados")
            return transformed
        
        except Exception as e:
            self.logger.error(f"✗ Error en transformación: {e}")
            raise


class DataValidator(Component):
    """Componente Validator: Valida integridad de datos"""
    
    def __init__(self, name: str = "DataValidator"):
        super().__init__(name)
    
    def execute(self, records: List[Dict]) -> Dict[str, Any]:
        """Valida registros y genera reporte"""
        try:
            self.logger.info("Iniciando validación de datos")
            
            total_registros = len(records)
            total_monto = sum(float(r['monto']) for r in records)
            monto_promedio = total_monto / total_registros if total_registros > 0 else 0
            
            # Contar por categoría
            categorias = {}
            for record in records:
                cat = record.get('categoria', 'Sin categoría')
                categorias[cat] = categorias.get(cat, 0) + 1
            
            reporte = {
                'timestamp': datetime.now().isoformat(),
                'total_registros': total_registros,
                'total_monto': f"${total_monto:,.2f}",
                'monto_promedio': f"${monto_promedio:,.2f}",
                'por_categoria': categorias,
                'estado_validacion': 'APROBADO'
            }
            
            self.logger.info(f"✓ Validación completada: {total_registros} registros")
            return reporte
        
        except Exception as e:
            self.logger.error(f"✗ Error en validación: {e}")
            raise


class CSVWriter(Component):
    """Componente Writer: Escribe CSV en directorio de destino"""
    
    def __init__(self, output_dir: str, name: str = "CSVWriter"):
        super().__init__(name)
        self.output_dir = output_dir
    
    def execute(self, records: List[Dict]) -> str:
        """Escribe registros transformados en CSV"""
        try:
            self.logger.info(f"Escribiendo archivo a: {self.output_dir}")
            
            # Crear directorio si no existe
            Path(self.output_dir).mkdir(parents=True, exist_ok=True)
            
            if not records:
                raise ValueError("No hay registros para escribir")
            
            # Nombre del archivo con timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"datos_transformados_{timestamp}.csv"
            filepath = os.path.join(self.output_dir, filename)
            
            # Escribir CSV
            fieldnames = list(records[0].keys())
            with open(filepath, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(records)
            
            self.logger.info(f"✓ Archivo escrito: {filepath}")
            return filepath
        
        except Exception as e:
            self.logger.error(f"✗ Error al escribir CSV: {e}")
            raise


class ReportGenerator(Component):
    """Componente que genera reportes de procesamiento"""
    
    def __init__(self, output_dir: str, name: str = "ReportGenerator"):
        super().__init__(name)
        self.output_dir = output_dir
    
    def execute(self, data: Dict[str, Any]) -> str:
        """Genera reporte JSON"""
        try:
            self.logger.info("Generando reporte")
            
            Path(self.output_dir).mkdir(parents=True, exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            report_file = os.path.join(self.output_dir, f"reporte_{timestamp}.json")
            
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            
            self.logger.info(f"✓ Reporte generado: {report_file}")
            return report_file
        
        except Exception as e:
            self.logger.error(f"✗ Error generando reporte: {e}")
            raise


class ETLPipeline:
    """Pipeline ETL que orquesta los componentes"""
    
    def __init__(self, log_dir: str = "/tmp/logs"):
        self.log_dir = log_dir
        self._configure_logging()
        self.logger = logging.getLogger("ETLPipeline")
    
    def _configure_logging(self):
        """Configura logging"""
        Path(self.log_dir).mkdir(parents=True, exist_ok=True)
        
        log_file = os.path.join(self.log_dir, f"pipeline_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
    
    def run(self, input_file: str, output_dir: str):
        """Ejecuta el pipeline ETL completo"""
        try:
            self.logger.info("=" * 60)
            self.logger.info("INICIANDO PIPELINE ETL - DEMO AB INITIO")
            self.logger.info("=" * 60)
            
            # 1. LECTURA
            reader = CSVReader(input_file)
            raw_data = reader.execute()
            
            # 2. TRANSFORMACIÓN
            transformer = DataTransformer()
            transformed_data = transformer.execute(raw_data)
            
            # 3. VALIDACIÓN
            validator = DataValidator()
            quality_report = validator.execute(transformed_data)
            
            # 4. ESCRITURA
            writer = CSVWriter(output_dir)
            output_file = writer.execute(transformed_data)
            
            # 5. REPORTE
            report_gen = ReportGenerator(output_dir)
            report_file = report_gen.execute(quality_report)
            
            self.logger.info("=" * 60)
            self.logger.info("PIPELINE COMPLETADO EXITOSAMENTE")
            self.logger.info(f"Archivo de salida: {output_file}")
            self.logger.info(f"Reporte de calidad: {report_file}")
            self.logger.info("=" * 60)
            
            return {
                'status': 'SUCCESS',
                'output_file': output_file,
                'report_file': report_file,
                'quality_report': quality_report
            }
        
        except Exception as e:
            self.logger.error(f"Error en pipeline: {e}", exc_info=True)
            return {'status': 'FAILED', 'error': str(e)}


def main():
    """Función principal"""
    # Directorios
    input_dir = "/tmp/input_data"
    output_dir = "/tmp/output_data"
    log_dir = "/tmp/logs"
    
    # Crear directorio de entrada
    Path(input_dir).mkdir(parents=True, exist_ok=True)
    
    # Crear archivo CSV de ejemplo
    csv_file = os.path.join(input_dir, "datos_clientes.csv")
    
    if not os.path.exists(csv_file):
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['id', 'nombre', 'email', 'ciudad', 'monto'])
            writer.writeheader()
            writer.writerows([
                {'id': '1', 'nombre': 'Juan Perez', 'email': 'juan@example.com', 'ciudad': 'Mexico', 'monto': '1500.00'},
                {'id': '2', 'nombre': 'Maria Garcia', 'email': 'maria@example.com', 'ciudad': 'Guadalajara', 'monto': '2300.50'},
                {'id': '3', 'nombre': 'Carlos Lopez', 'email': 'carlos@example.com', 'ciudad': 'Monterrey', 'monto': '890.75'},
                {'id': '4', 'nombre': 'Ana Martinez', 'email': 'ana@example.com', 'ciudad': 'Mexico', 'monto': '3200.00'},
                {'id': '5', 'nombre': 'Roberto Sanchez', 'email': 'roberto@example.com', 'ciudad': 'Puebla', 'monto': '1100.25'},
            ])
    
    # Ejecutar pipeline
    pipeline = ETLPipeline(log_dir)
    result = pipeline.run(csv_file, output_dir)
    
    # Mostrar resultado
    print("\n" + "=" * 60)
    print("RESULTADO DEL PIPELINE")
    print("=" * 60)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
