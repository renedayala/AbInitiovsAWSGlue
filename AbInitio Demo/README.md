# DEMO AB INITIO - ETL EN RHEL/LINUX

## 📋 Tabla de Contenidos

1. [Introducción a Ab Initio](#introducción-a-ab-initio)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Requisitos](#requisitos)
4. [Instalación](#instalación)
5. [Uso](#uso)
6. [Archivos Generados](#archivos-generados)
7. [Conceptos de Ab Initio](#conceptos-de-ab-initio)
8. [Comparación con Herramientas Similares](#comparación-con-herramientas-similares)

---

## 🚀 Introducción a Ab Initio

### ¿Qué es Ab Initio?

**Ab Initio** es una plataforma empresarial de **integración de datos** y **procesamiento de información** especializada en:

- **ETL (Extract, Transform, Load)**: Extrae datos de múltiples fuentes, los transforma según reglas de negocio, y los carga en destinos.
- **Parallelización**: Procesa millones de registros en paralelo para máximo rendimiento.
- **Componentes visuales**: Interfaz gráfica basada en "graphs" con componentes reutilizables.
- **Escalabilidad empresarial**: Maneja flujos complejos de datos en entornos de producción.

### Características Principales

| Característica | Descripción |
|---|---|
| **Lenguaje nativo** | DMX (Data Manipulation eXpressions) |
| **Arquitectura** | Basada en componentes y graphs |
| **Procesamiento** | Paralelo y distribuido |
| **Fuentes soportadas** | Archivos, Bases de Datos, APIs, Message Queues |
| **Escalabilidad** | Terabytes de datos |
| **Seguridad** | Auditoría completa, tracking de datos |

### Componentes Típicos de Ab Initio

```
[Source] → [Transformer] → [Validator] → [Sink]
            ↓
         [Lookup]
            ↓
        [Join/Aggregation]
```

---

## 📁 Estructura del Proyecto

```
.
├── abinitio_demo.sh           # Demo en Bash (simple)
├── abinitio_demo.py           # Demo en Python (POO, recomendado)
├── pipeline_config.json       # Configuración del flujo
├── Makefile                   # Automatización
├── README.md                  # Este archivo
└── DIRECTORIOS GENERADOS:
    ├── /tmp/input_data/       # Archivos de entrada (CSV)
    ├── /tmp/output_data/      # Archivos procesados
    ├── /tmp/logs/             # Logs de ejecución
    └── /tmp/archive/          # Backups
```

---

## 📦 Requisitos

### Mínimos
- **Sistema Operativo**: RHEL/CentOS 7+, Ubuntu 18.04+, Debian 10+
- **Bash**: 4.0+
- **Python**: 3.6+ (para demo Python)

### Verificar

```bash
# Verificar bash
bash --version

# Verificar python
python3 --version

# Verificar make
make --version
```

---

## ⚙️ Instalación

### 1. Clonar o descargar archivos

```bash
# Navega a tu directorio de trabajo
cd /home/usuario/ab-initio-demo

# Asegúrate que los archivos estén en el directorio actual
ls -la *.sh *.py *.json Makefile
```

### 2. Dar permisos de ejecución

```bash
chmod +x abinitio_demo.sh
chmod +x abinitio_demo.py
```

### 3. (Opcional) Instalar dependencias adicionales

```bash
# Para RHEL/CentOS
sudo yum install -y python3 make

# Para Ubuntu/Debian
sudo apt-get install -y python3 make

# Para mejor visualización de JSON
sudo yum install -y jq  # RHEL/CentOS
sudo apt-get install -y jq  # Ubuntu/Debian
```

---

## 🎯 Uso

### Opción 1: Usando Make (RECOMENDADO)

```bash
# Ver todos los comandos disponibles
make help

# Preparar el ambiente
make setup

# Ejecutar demo en Python (POO)
make run-python

# Ejecutar demo en Bash (simple)
make run-bash

# Ver archivos generados
make view-output

# Ver logs
make view-logs

# Limpiar archivos
make clean
```

### Opción 2: Ejecución Manual

#### Demo en Python (RECOMENDADO)

```bash
# Ejecutar directamente
python3 abinitio_demo.py

# Con output en archivo de log
python3 abinitio_demo.py > ejecucion.log 2>&1

# Ver el log en tiempo real
tail -f ejecucion.log
```

#### Demo en Bash

```bash
# Ejecutar directamente
bash abinitio_demo.sh

# Con output en archivo de log
bash abinitio_demo.sh > ejecucion.log 2>&1
```

### Opción 3: Ejecución Automática (Cron)

```bash
# Editar crontab
crontab -e

# Agregar línea para ejecutar diariamente a las 2 AM
0 2 * * * cd /home/usuario/ab-initio-demo && make run-python >> /tmp/logs/cron.log 2>&1
```

---

## 📊 Archivos Generados

### Archivos CSV

Ubicación: `/tmp/output_data/`

Ejemplo de archivo generado:

```csv
id,nombre,email,ciudad,monto,categoria,monto_formateado,fecha_proceso,estado
1,Juan Perez,juan@example.com,Mexico,1500.00,Estándar,$1,500.00,2024-06-18,Procesado
2,Maria Garcia,maria@example.com,Guadalajara,2300.50,Premium,$2,300.50,2024-06-18,Procesado
4,Ana Martinez,ana@example.com,Mexico,3200.00,Premium,$3,200.00,2024-06-18,Procesado
5,Roberto Sanchez,roberto@example.com,Puebla,1100.25,Estándar,$1,100.25,2024-06-18,Procesado
```

### Archivos de Reporte (JSON)

Ubicación: `/tmp/output_data/reporte_*.json`

```json
{
  "timestamp": "2024-06-18T14:30:45.123456",
  "total_registros": 4,
  "total_monto": "$7,900.25",
  "monto_promedio": "$1,975.06",
  "por_categoria": {
    "Estándar": 2,
    "Premium": 2
  },
  "estado_validacion": "APROBADO"
}
```

### Logs de Ejecución

Ubicación: `/tmp/logs/`

```
2024-06-18 14:30:45,123 - ETLPipeline - INFO - ============================================================
2024-06-18 14:30:45,124 - ETLPipeline - INFO - INICIANDO PIPELINE ETL - DEMO AB INITIO
2024-06-18 14:30:45,125 - CSVReader - INFO - Leyendo archivo: /tmp/input_data/datos_clientes.csv
2024-06-18 14:30:45,126 - CSVReader - INFO - ✓ Se leyeron 5 registros
2024-06-18 14:30:45,127 - DataTransformer - INFO - Iniciando transformación de datos
2024-06-18 14:30:45,128 - DataTransformer - INFO - ✓ 4 registros transformados
...
```

---

## 🧠 Conceptos de Ab Initio

### 1. Componentes (Components)

Bloques de construcción reutilizables:

```python
class Component(ABC):
    """Componente base de Ab Initio"""
    @abstractmethod
    def execute(self, data):
        """Procesa datos"""
        pass
```

**Tipos de componentes:**
- **Readers**: Leen datos (CSVReader, DatabaseReader)
- **Transformers**: Procesan datos (Filter, Join, Aggregate)
- **Validators**: Validan integridad
- **Writers**: Escriben datos (CSVWriter, DatabaseWriter)
- **Lookups**: Búsquedas de referencia

### 2. Graphs (Flujos)

Definen el flujo de datos conectando componentes:

```
Reader → Transformer → Validator → Writer → Reporter
         ↓
      Lookup Table
```

### 3. Expresiones DMX

En Ab Initio real, usarías expresiones como:

```dmx
// Filtro
monto > 1000

// Campo calculado
IF(monto > 2000, 'Premium', 'Standard')

// Agregación
SUM(monto)
GROUP BY ciudad
```

En nuestro demo Python, lo simulamos con Python puro:

```python
if monto > 1000:
    categoria = "Premium" if monto > 2000 else "Estándar"
```

### 4. Lineage (Rastreo de Datos)

Rastrea de dónde vino cada dato:

```
datos_clientes.csv → [Reader] → id_cliente → [Transformer] → reporte_final.csv
                               → nombre    → [Validator]
                               → monto     → [Writer]
```

### 5. Manejo de Errores

**Estrategias:**
- `STOP_ON_ERROR`: Detener si hay error
- `CONTINUE_ON_ERROR`: Continuar registrando errores
- `REJECT_RECORD`: Rechazar registro inválido
- `REDIRECT_TO_SINK`: Enviar a flujo alterno

---

## 📈 Flujo de Datos Explicado

### Paso 1: LECTURA (Reader)

```
Archivo CSV → Leer línea por línea → Lista de diccionarios
"id,nombre,monto"
"1,Juan,1500"     →  {id:1, nombre:Juan, monto:1500}
"2,Maria,2300"    →  {id:2, nombre:Maria, monto:2300}
"3,Carlos,890"    →  {id:3, nombre:Carlos, monto:890}
```

### Paso 2: TRANSFORMACIÓN (Transformer)

```
Aplicar reglas de negocio:
- Filtrar: solo monto > 1000
- Agregar: categoría según monto
- Calcular: moneda formateada
- Marcar: fecha de procesamiento

Entrada: {id:1, nombre:Juan, monto:1500}
Salida: {id:1, nombre:Juan, monto:1500, categoria:Estándar, 
         monto_formateado:$1,500.00, fecha_proceso:2024-06-18}
```

### Paso 3: VALIDACIÓN (Validator)

```
Verificar integridad:
- id no nulo
- email válido (regex)
- monto es número
- Generar reporte de calidad

✓ Registros válidos: 4
✗ Registros rechazados: 1 (Carlos: monto < 1000)
```

### Paso 4: ESCRITURA (Writer)

```
Escribir en CSV:
id,nombre,email,ciudad,monto,categoria,monto_formateado,fecha_proceso,estado
1,Juan Perez,juan@example.com,Mexico,1500.00,Estándar,$1,500.00,2024-06-18,Procesado
2,Maria Garcia,maria@example.com,Guadalajara,2300.50,Premium,$2,300.50,2024-06-18,Procesado
...
```

### Paso 5: REPORTE (ReportGenerator)

```
Generar reporte de ejecución:
{
  "total_registros": 4,
  "total_monto": "$7,900.25",
  "por_categoria": {"Estándar": 2, "Premium": 2}
}
```

---

## 🔄 Comparación con Herramientas Similares

| Aspecto | Ab Initio | Talend | Informatica | Apache Spark |
|---------|-----------|--------|-------------|--------------|
| **Tipo** | ETL Empresarial | ETL/ELT | ETL/MDM | Framework de Datos |
| **Lenguaje** | DMX | Java/Python | Propio | Scala/Python/Java |
| **Interfaz** | Gráfica (Graph) | Gráfica (Job) | Gráfica | CLI/Notebooks |
| **Parallelización** | Nativa | Sí | Sí | Excelente |
| **Curva Aprendizaje** | Media-Alta | Media | Alta | Alta |
| **Licencia** | Comercial | Abierta/Comercial | Comercial | Abierta |
| **Escalabilidad** | Terabytes | Terabytes | Petabytes | Petabytes |
| **Cloud Native** | No | Sí (Cloud) | Sí | Sí |

---

## 🔧 Solución de Problemas

### Problema: "Permission denied: ./abinitio_demo.sh"

**Solución:**
```bash
chmod +x abinitio_demo.sh abinitio_demo.py
```

### Problema: "No module named 'csv'" (Python)

**Solución:**
```bash
# csv está en la librería estándar, asegúrate de usar Python 3
python3 --version  # Debe ser 3.6+
python3 abinitio_demo.py
```

### Problema: "Permission denied: /tmp/output_data"

**Solución:**
```bash
# Cambiar permisos del directorio
chmod 777 /tmp/output_data
# O usar un directorio en home
mkdir -p ~/output_data
```

### Problema: Logs no se generan

**Solución:**
```bash
# Crear directorio de logs
mkdir -p /tmp/logs
chmod 777 /tmp/logs

# Ejecutar con output visto
python3 abinitio_demo.py 2>&1 | tee /tmp/logs/output.log
```

---

## 📚 Recursos Adicionales

### Documentación Oficial Ab Initio
- [Ab Initio Portal](https://www.abinitio.com)
- [Community Edition](https://www.abinitio.com/en/products/community-edition)

### Alternativas Open Source
- **Apache NiFi**: Flujos visuales con garantía de entrega
- **Apache Airflow**: Orquestación de flujos en Python
- **Talend Open Studio**: ETL abierto con interfaz gráfica

### Tutoriales Relacionados
```bash
# En tu entorno RHEL/Linux
man bash       # Manual de bash
man python3    # Manual de Python
man crontab    # Programación de tareas
```

---

## 📝 Próximos Pasos

### 1. Personalizar el Demo

Edita `abinitio_demo.py`:

```python
# Cambiar origen de datos
reader = CSVReader("/tu/archivo.csv")

# Cambiar transformaciones
# Modifica la clase DataTransformer

# Cambiar destino
writer = CSVWriter("/tu/directorio/destino")
```

### 2. Integrar con Bases de Datos

```python
# Agregar DatabaseWriter
class DatabaseWriter(Component):
    def execute(self, records):
        # INSERT INTO tabla VALUES (...)
        pass
```

### 3. Agregar Validaciones Complejas

```python
# Extender DataValidator
class AdvancedValidator(Component):
    def execute(self, records):
        # Validación con regex, duplicados, etc.
        pass
```

### 4. Programación con Cron

```bash
# Ejecutar cada día a las 2 AM
0 2 * * * /home/usuario/ab-initio-demo/run.sh
```

---

## 📞 Soporte

Para preguntas o problemas:

1. Revisa la sección "Solución de Problemas"
2. Verifica los logs en `/tmp/logs/`
3. Ejecuta `make help` para ver comandos disponibles
4. Consulta la documentación oficial de Ab Initio

---

## 📄 Licencia

Este demo es educativo y de código abierto. Libre para usar y modificar.

---

**Última actualización**: Junio 2024
**Versión**: 1.0
