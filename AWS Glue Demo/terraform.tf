# ============================================================================
# main.tf - Infraestructura AWS Glue con Terraform
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "demo-etl-glue"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# ============================================================================
# VARIABLES
# ============================================================================

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "demo-etl-glue"
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
  default     = "demo-etl-glue-data"
}

variable "glue_job_name" {
  description = "Nombre del job de Glue"
  type        = string
  default     = "etl-csv-transform"
}

variable "worker_type" {
  description = "Tipo de worker para Glue"
  type        = string
  default     = "G.1X"
  validation {
    condition     = contains(["G.1X", "G.2X", "Z.2X"], var.worker_type)
    error_message = "Worker type debe ser G.1X, G.2X o Z.2X"
  }
}

variable "num_workers" {
  description = "Número de workers"
  type        = number
  default     = 2
  validation {
    condition     = var.num_workers >= 2 && var.num_workers <= 100
    error_message = "Número de workers debe estar entre 2 y 100"
  }
}

variable "glue_version" {
  description = "Versión de Glue"
  type        = string
  default     = "4.0"
}

variable "job_timeout" {
  description = "Timeout del job en minutos"
  type        = number
  default     = 60
}

# ============================================================================
# S3 BUCKET
# ============================================================================

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.s3_bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_sse" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Crear directorios en S3
resource "aws_s3_object" "input_dir" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "input-data/"
}

resource "aws_s3_object" "output_dir" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "output-data/"
}

resource "aws_s3_object" "scripts_dir" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "glue-scripts/"
}

resource "aws_s3_object" "logs_dir" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "glue-logs/"
}

# ============================================================================
# IAM ROLE PARA GLUE
# ============================================================================

resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-glue-role"
  }
}

# Adjuntar política de Glue service
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Política personalizada para S3
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "${var.project_name}-glue-s3-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Política para CloudWatch Logs
resource "aws_iam_role_policy" "glue_logs_policy" {
  name = "${var.project_name}-glue-logs-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"
      }
    ]
  })
}

# ============================================================================
# GLUE JOB
# ============================================================================

resource "aws_glue_job" "etl_job" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${aws_s3_bucket.data_bucket.id}/glue-scripts/glue_job.py"
    python_version  = "3.9"
  }

  default_arguments = {
    "--S3_INPUT_PATH"  = "s3://${aws_s3_bucket.data_bucket.id}/input-data/"
    "--S3_OUTPUT_PATH" = "s3://${aws_s3_bucket.data_bucket.id}/output-data/"
    "--MONTO_MINIMO"   = "1000"
    "--AWS_REGION"     = var.aws_region
  }

  worker_type           = var.worker_type
  number_of_workers     = var.num_workers
  glue_version          = var.glue_version
  timeout               = var.job_timeout
  max_retries           = 1
  job_bookmark_option   = "job-bookmark-enable"

  tags = {
    Name = var.glue_job_name
  }

  depends_on = [aws_iam_role_policy.glue_s3_policy]
}

# ============================================================================
# GLUE TRIGGER (Opcional - ejecutar por horario)
# ============================================================================

resource "aws_glue_trigger" "daily_trigger" {
  name = "${var.project_name}-daily-trigger"
  type = "SCHEDULED_BATCH"

  schedule = "cron(0 2 * * ? *)"  # Diariamente a las 2 AM UTC

  actions {
    job_name = aws_glue_job.etl_job.name
  }

  tags = {
    Name = "${var.project_name}-daily-trigger"
  }
}

# ============================================================================
# CLOUDWATCH ALARMS
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "glue_job_failure" {
  alarm_name          = "${var.project_name}-glue-job-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "glue_job_failed_runs"
  namespace           = "AWS/Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when Glue job fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobName = aws_glue_job.etl_job.name
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.data_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.data_bucket.arn
}

output "glue_job_name" {
  description = "Nombre del job de Glue"
  value       = aws_glue_job.etl_job.name
}

output "glue_job_arn" {
  description = "ARN del job de Glue"
  value       = aws_glue_job.etl_job.arn
}

output "iam_role_arn" {
  description = "ARN del rol IAM de Glue"
  value       = aws_iam_role.glue_role.arn
}

output "s3_input_path" {
  description = "Ruta de entrada en S3"
  value       = "s3://${aws_s3_bucket.data_bucket.id}/input-data/"
}

output "s3_output_path" {
  description = "Ruta de salida en S3"
  value       = "s3://${aws_s3_bucket.data_bucket.id}/output-data/"
}

output "s3_scripts_path" {
  description = "Ruta de scripts en S3"
  value       = "s3://${aws_s3_bucket.data_bucket.id}/glue-scripts/"
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}
