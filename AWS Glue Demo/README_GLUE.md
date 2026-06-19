# AWS GLUE - DEMO ETL EN LA NUBE

## 📋 Tabla de Contenidos

1. [Introducción a AWS Glue](#introducción-a-aws-glue)
2. [Arquitectura](#arquitectura)
3. [Requisitos](#requisitos)
4. [Instalación](#instalación)
5. [Uso](#uso)
6. [Pruebas Locales](#pruebas-locales)
7. [Despliegue](#despliegue)
8. [Monitoreo](#monitoreo)
9. [Costos](#costos)
10. [Troubleshooting](#troubleshooting)

---

## 🚀 Introducción a AWS Glue

### ¿Qué es AWS Glue?

**AWS Glue** es un servicio ETL totalmente administrado que facilita la preparación y carga de datos para análisis. Es la alternativa en la nube a herramientas como Ab Initio, Talend e Informatica.

### Características Principales

| Característica | Descripción |
|---|---|
| **Serverless** | Sin servidores que administrar |
| **Escalable** | Desde MB hasta TB de datos |
| **Integrado** | Funciona con S3, RDS, Redshift, DynamoDB |
| **Glue Catalog** | Metadatos centralizados |
| **Job Bookmarks** | Procesamiento incremental |
| **Data Quality** | Framework de validación |
| **Visualización** | Interfaz gráfica (Glue Studio) |
| **Precio por uso** | Solo pagas lo que usas |

### Componentes de Glue

```
┌─────────────────────────────────────────────────────────┐
│                    AWS GLUE                             │
├─────────────────────────────────────────────────────────┤
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│ │ Glue Jobs    │  │ Glue Catalog │  │ Glue Studio  │   │
│ │ (PySpark)    │  │ (Metadatos)  │  │ (Visual)     │   │
│ └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                         │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│ │ Crawlers     │  │ Triggers     │  │ Data Quality │   │
│ │ (Auto schema)│  │ (Schedules)  │  │ (Validación) │   │
│ └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 🏗️ Arquitectura

### Flujo Completo

```
┌─────────────┐
│   S3 Input  │  (datos_clientes.csv)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      AWS Glue Job                       │
│  ┌─────────────────────────────────┐    │
│  │ 1. Reader (Read CSV from S3)    │    │
│  ├─────────────────────────────────┤    │
│  │ 2. Transformer (Apply rules)    │    │
│  ├─────────────────────────────────┤    │
│  │ 3. Validator (Quality checks)   │    │
│  ├─────────────────────────────────┤    │
│  │ 4. Writer (Write to S3)         │    │
│  ├─────────────────────────────────┤    │
│  │ 5. Reporter (Generate report)   │    │
│  └─────────────────────────────────┘    │
└──────┬──────────────────────────────────┘
       │
       ├──────────────────┬─────────────────┐
       ▼                  ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  S3 Output   │  │ CloudWatch   │  │   Glue Logs  │
│  (Parquet)   │  │    Metrics   │  │    (Detalle) │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Comparación: Local vs Glue

```
DEMO LOCAL                          AWS GLUE
─────────────────────────────────────────────────────────
Máquina local              →    Servidores AWS escalables
Bash/Python directo        →    PySpark distribuido
Archivos locales           →    S3 (almacenamiento)
Logs en archivo            →    CloudWatch Logs
Sin autoscaling            →    Escalado automático
Costo: $0 (máquina)        →    Costo por uso
Limitado a RAM/CPU         →    Hasta 100 DPUs
```

---

## 📦 Requisitos

### AWS

- [ ] Cuenta AWS activa
- [ ] AWS CLI configurado con credenciales
- [ ] Permisos para: IAM, S3, Glue, CloudWatch

Verificar credenciales:
```bash
aws sts get-caller-identity
```

### Local

Para probar sin AWS:

```bash
# Python 3.8+
python3 --version

# Instalar dependencias (opcional)
pip install boto3 pyspark
```

---

## ⚙️ Instalación

### Opción 1: Script Automatizado (RECOMENDADO)

```bash
# Dar permisos
chmod +x glue_deployment.sh

# Configuración inicial (crea todo)
./glue_deployment.sh setup

# Esto hace:
# ✓ Crea rol IAM de Glue
# ✓ Crea bucket S3
# ✓ Sube script Python a S3
# ✓ Sube datos de ejemplo
# ✓ Crea el Job de Glue
```

### Opción 2: Terraform (Infrastructure as Code)

```bash
# Inicializar Terraform
terraform init

# Ver plan de cambios
terraform plan

# Aplicar cambios
terraform apply

# Destroy (si necesitas eliminar)
terraform destroy
```

### Opción 3: AWS Console

Manualmente a través de la consola de AWS Glue:

1. Crear rol IAM con permisos de Glue y S3
2. Crear bucket S3
3. Subir script `glue_job.py`
4. Crear Job de Glue pointing al script
5. Ejecutar Job

---

## 🎯 Uso

### 1. Pruebas Locales (sin AWS)

```bash
# Ejecutar pruebas sin AWS
python3 test_glue_local.py

# Salida esperada:
# ✓ TEST 1: Reader (5 registros leídos)
# ✓ TEST 2: Transformer (4 registros transformados)
# ✓ TEST 3: Validator (Estadísticas calculadas)
# ✓ TEST 4: Writer (Datos escritos)
# ✓ TEST 5: Quality Checks (Validaciones pasadas)
# 
# RESUMEN: 5 pruebas pasadas
# ✓ El job está listo para desplegar en AWS Glue
```

### 2. Desplegar en AWS Glue

```bash
# Opción A: Con script de despliegue
./glue_deployment.sh setup

# Opción B: Con Terraform
terraform init
terraform apply

# Opción C: Manual (CLI)
aws s3 cp glue_job.py s3://mi-bucket/glue-scripts/
aws glue create-job \
  --name demo-etl-glue \
  --role arn:aws:iam::ACCOUNT:role/GlueJobRole \
  --command Name=pythonshell,ScriptLocation=s3://mi-bucket/glue-scripts/glue_job.py
```

### 3. Ejecutar el Job

```bash
# Opción A: Script de despliegue
./glue_deployment.sh run

# Opción B: AWS CLI
aws glue start-job-run \
  --job-name demo-etl-glue \
  --region us-east-1

# Opción C: AWS Console
# Ir a Glue > Jobs > demo-etl-glue > Run job
```

### 4. Programar Ejecución Automática

```bash
# El script de despliegue crea un trigger diario
# O manualmente con AWS CLI:

aws glue create-trigger \
  --name daily-etl-trigger \
  --type SCHEDULED_BATCH \
  --schedule "cron(0 2 * * ? *)" \
  --actions JobName=demo-etl-glue
```

---

## 🧪 Pruebas Locales

### Ejecutar Tests Locales

```bash
# Sin AWS
python3 test_glue_local.py

# Verifica:
# ✓ Lectura de datos
# ✓ Transformaciones
# ✓ Validaciones
# ✓ Escritura
# ✓ Calidad de datos
# ✓ Reportes
```

### Resultado Esperado

```
╔════════════════════════════════════════════════════════╗
║    PRUEBAS LOCALES - AWS GLUE ETL JOB                ║
╚════════════════════════════════════════════════════════╝

TEST 1: Componente Reader
✓ Se leyeron 5 registros

TEST 2: Componente Transformer
✓ Registros después de filtro: 4
✓ Columnas agregadas: 2

TEST 3: Componente Validator
✓ Total de registros: 4
✓ Monto total: $8,100.75
✓ Monto promedio: $2,025.19
✓ Por categoría: {'Estándar': 2, 'Premium': 2}

TEST 4: Componente Writer
✓ Datos escritos en Parquet

TEST 5: Verificaciones de Calidad
✓ IDs nulos: 0
✓ Emails nulos: 0
✓ Montos negativos: 0

RESUMEN DE PRUEBAS
Total: 5 pruebas
Pasadas: 5
Fallidas: 0

✓ TODAS LAS PRUEBAS PASARON
✓ El job está listo para desplegar en AWS Glue
```

---

## 🚀 Despliegue

### Paso 1: Preparación

```bash
# 1. Configurar AWS CLI
aws configure

# 2. Verificar credenciales
aws sts get-caller-identity

# 3. Ejecutar pruebas locales
python3 test_glue_local.py
```

### Paso 2: Setup Automático

```bash
# Ejecutar setup completo
./glue_deployment.sh setup

# O con variables personalizadas
AWS_REGION=us-west-2 \
S3_BUCKET=mi-bucket-datos \
./glue_deployment.sh setup
```

### Paso 3: Ejecutar Job

```bash
# Ejecutar job
./glue_deployment.sh run

# Monitorea el progreso y muestra logs
```

### Paso 4: Verificar Resultados

```bash
# Ver archivos generados
aws s3 ls s3://mi-bucket-datos/output-data/ --recursive

# Ver reporte JSON
aws s3 cp s3://mi-bucket-datos/output-data/reporte_*.json - | jq '.'
```

---

## 📊 Monitoreo

### CloudWatch Logs

```bash
# Ver logs en tiempo real
aws logs tail /aws-glue/jobs/demo-etl-glue --follow

# Últimos 100 líneas
aws logs tail /aws-glue/jobs/demo-etl-glue --max-items 100

# Desde hace 1 hora
aws logs tail /aws-glue/jobs/demo-etl-glue --since 1h
```

### Métricas de CloudWatch

```bash
# Ver duración del job
aws cloudwatch get-metric-statistics \
  --namespace AWS/Glue \
  --metric-name dpu_seconds \
  --dimensions Name=JobName,Value=demo-etl-glue \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### AWS Glue Metrics

```bash
# Listar ejecutiones del job
aws glue list-job-runs --job-name demo-etl-glue

# Ver detalles de última ejecución
aws glue get-job-run \
  --job-name demo-etl-glue \
  --run-id jr_12345
```

---

## 💰 Costos

### Estimación de Costos

| Componente | Costo | Ejemplo |
|---|---|---|
| **Glue DPU** | $0.44/DPU-hora | 2 workers G.1X = 2 DPUs |
| **Glue Catalog** | $0.15/millón objetos | Sin costo generalmente |
| **S3 Storage** | $0.023/GB | 1GB = $0.023 |
| **Data Transfer** | $0.02/GB | Dentro región = sin costo |

### Ejemplo Mensual

```
Suposición: 10 ejecuciones diarias de 5 minutos

Cálculo:
- 10 jobs/día × 30 días = 300 jobs/mes
- 300 jobs × (5 min ÷ 60 min) × 2 DPUs × $0.44 = ~$4.40
- S3 storage: ~$1.00
- Otros costos: ~$1.00

Total estimado: ~$6-10/mes
```

### Optimizar Costos

```python
# Usar G.1X en vez de G.2X
worker_type = "G.1X"  # Más barato

# Usar Parquet en vez de CSV
format="parquet"  # Comprimido automáticamente

# Job bookmarks habilitados
job_bookmark_option = "job-bookmark-enable"  # Procesa solo datos nuevos

# Glue Studio para crear jobs visuales sin código
# (mejor para equipos no técnicos)
```

---

## 🔧 Troubleshooting

### Problema 1: "Permission denied" para Glue

**Síntoma:**
```
botocore.exceptions.ClientError: An error occurred (AccessDenied)
```

**Solución:**
```bash
# Verificar credenciales
aws sts get-caller-identity

# Verificar permisos IAM
aws iam list-attached-user-policies --user-name mi-usuario

# Crear rol con permisos completos
./glue_deployment.sh setup
```

### Problema 2: Script no encontrado en S3

**Síntoma:**
```
The provided script did not create a DataFrame named job_id_12345
```

**Solución:**
```bash
# Verificar que el script está en S3
aws s3 ls s3://mi-bucket/glue-scripts/

# Subir manualmente
aws s3 cp glue_job.py s3://mi-bucket/glue-scripts/

# Actualizar job
./glue_deployment.sh update
```

### Problema 3: S3 bucket no existe

**Síntoma:**
```
The specified bucket does not exist
```

**Solución:**
```bash
# Crear bucket
aws s3 mb s3://mi-bucket --region us-east-1

# O dejar que el script lo cree
./glue_deployment.sh setup
```

### Problema 4: Job timeout

**Síntoma:**
```
Job execution exceeded timeout of 60 minutes
```

**Solución:**
```bash
# Aumentar timeout
aws glue update-job \
  --name demo-etl-glue \
  --role arn:aws:iam::ACCOUNT:role/GlueJobRole \
  --timeout 120  # Aumentar a 120 minutos

# O aumentar workers para procesamiento más rápido
--number-of-workers 4
--worker-type G.2X
```

### Problema 5: Job ejecutándose lentamente

**Síntoma:**
```
Job takes 20+ minutes
```

**Solución:**
```bash
# Aumentar paralelismo
--worker-type G.2X  # Más CPU/RAM por worker
--number-of-workers 4  # Más workers

# Habilitar job bookmarks
--job-bookmark-option job-bookmark-enable

# Usar formato eficiente
# Parquet en lugar de CSV
```

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [AWS Glue Developer Guide](https://docs.aws.amazon.com/glue/)
- [Glue Python API](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-python.html)
- [PySpark on Glue](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-libraries.html)

### Tutoriales
- [Getting Started with Glue](https://aws.amazon.com/glue/getting-started/)
- [Glue Studio Examples](https://aws.amazon.com/glue/resources/)

### Herramientas
- [AWS Glue Studio](https://console.aws.amazon.com/gluestudio/) - Visual job builder
- [Glue Data Quality](https://docs.aws.amazon.com/glue/latest/dg/data-quality-intro.html)
- [Glue Crawlers](https://docs.aws.amazon.com/glue/latest/dg/crawlers-and-classifiers.html)

---

## 🎓 Mejores Prácticas

### 1. Validación de Datos

```python
# Usar Data Quality Ruleset
quality_checks = {
    'no_null_ids': "ColumnLength(col_id) > 0",
    'valid_emails': "Regex(col_email, '^[^@]+@[^@]+\\\\.[^@]+$')",
    'positive_amounts': "ColumnValues(col_monto, > 0)"
}
```

### 2. Error Handling

```python
try:
    # Procesar
    pass
except Exception as e:
    logger.error(f"Error: {str(e)}")
    # Enviar alerta
    send_alert_to_sns(topic_arn, message=str(e))
```

### 3. Logging

```python
import logging
logger = logging.getLogger("GlueETL")
logger.info("Processing started")
# Logs automáticamente en CloudWatch
```

### 4. Particionamiento

```python
# Para grandes volúmenes, particionar por fecha
df.write.partitionBy("fecha_proceso") \
    .mode("overwrite") \
    .parquet("s3://bucket/output/")
```

---

## 📝 Próximos Pasos

### 1. Agregar Validaciones Avanzadas

```python
# En GlueValidator
def advanced_checks(self, df):
    # Verificar duplicados
    duplicates = df.groupBy("id").count().filter(col("count") > 1)
    
    # Verificar valores outliers
    q1 = df.approxQuantile("monto", [0.25], 0.05)[0]
    q3 = df.approxQuantile("monto", [0.75], 0.05)[0]
```

### 2. Integrar con Más Fuentes

```python
# Leer desde RDS
dyf = glueContext.create_dynamic_frame.from_catalog(
    database="mi_database",
    table_name="customers"
)

# Escribir a Redshift
glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=dyf,
    catalog_connection="redshift_conn",
    connection_options={"dbtable": "target_table"}
)
```

### 3. Usar Glue Studio

- Interfaz visual para no-técnicos
- Drag & drop de transformaciones
- Auto-generación de código

---

**Última actualización**: Junio 2024
**Versión**: 1.0
