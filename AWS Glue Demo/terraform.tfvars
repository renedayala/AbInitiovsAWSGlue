# ============================================================================
# terraform.tfvars - Valores de variables para Terraform
# ============================================================================

# Región de AWS
aws_region = "us-east-1"

# Ambiente (dev, staging, prod)
environment = "dev"

# Nombre del proyecto
project_name = "demo-etl-glue"

# Nombre del bucket S3 (será agregado: -<ACCOUNT_ID>)
s3_bucket_name = "demo-etl-glue-data"

# Nombre del job de Glue
glue_job_name = "etl-csv-transform"

# Tipo de worker
# Opciones: G.1X (1 DPU), G.2X (2 DPU), Z.2X (2 DPU + 128 GB RAM)
worker_type = "G.1X"

# Número de workers (mínimo 2)
num_workers = 2

# Versión de Glue (4.0 es la más reciente con PySpark 3.x)
glue_version = "4.0"

# Timeout del job en minutos
job_timeout = 60
