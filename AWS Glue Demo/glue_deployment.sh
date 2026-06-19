#!/bin/bash

###############################################################################
# glue_deployment.sh - Script para desplegar Job en AWS Glue
# Uso: ./glue_deployment.sh [create|update|delete|run|describe]
###############################################################################

set -e

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# Variables de ambiente
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"
GLUE_JOB_NAME="demo-etl-glue"
GLUE_ROLE_NAME="GlueJobRole"
S3_BUCKET="${S3_BUCKET:-mi-bucket-datos}"
S3_SCRIPTS_PATH="s3://${S3_BUCKET}/glue-scripts"
S3_INPUT_PATH="s3://${S3_BUCKET}/input-data/datos_clientes.csv"
S3_OUTPUT_PATH="s3://${S3_BUCKET}/output-data"
GLUE_SCRIPT_LOCAL="glue_job.py"
GLUE_VERSION="4.0"
WORKER_TYPE="G.1X"
NUM_WORKERS="2"
MONTO_MINIMO="1000"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCIONES
# ============================================================================

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step() {
    echo -e "${YELLOW}=>${NC} $1"
}

check_requirements() {
    print_header "Verificando requisitos"
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI no instalado"
        exit 1
    fi
    print_success "AWS CLI instalado"
    
    # Verificar credenciales
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        print_error "Credenciales de AWS no válidas"
        exit 1
    fi
    print_success "Credenciales de AWS válidas"
    
    # Verificar archivo local del script
    if [ ! -f "$GLUE_SCRIPT_LOCAL" ]; then
        print_error "Archivo $GLUE_SCRIPT_LOCAL no encontrado"
        exit 1
    fi
    print_success "Script Glue encontrado: $GLUE_SCRIPT_LOCAL"
    
    echo ""
}

create_iam_role() {
    print_header "Creando rol IAM para Glue (si no existe)"
    
    # Verificar si el rol ya existe
    if aws iam get-role --role-name "$GLUE_ROLE_NAME" --profile "$AWS_PROFILE" 2>/dev/null; then
        print_info "Rol ya existe: $GLUE_ROLE_NAME"
        return 0
    fi
    
    print_step "Creando rol IAM..."
    
    # Crear rol
    TRUST_POLICY='{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "glue.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }'
    
    aws iam create-role \
        --role-name "$GLUE_ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    print_success "Rol creado: $GLUE_ROLE_NAME"
    
    # Adjuntar políticas
    print_step "Adjuntando políticas..."
    
    aws iam attach-role-policy \
        --role-name "$GLUE_ROLE_NAME" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole" \
        --profile "$AWS_PROFILE"
    
    # Política personalizada para S3
    S3_POLICY='{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ],
          "Resource": "arn:aws:s3:::'${S3_BUCKET}'/*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket"
          ],
          "Resource": "arn:aws:s3:::'${S3_BUCKET}'"
        }
      ]
    }'
    
    aws iam put-role-policy \
        --role-name "$GLUE_ROLE_NAME" \
        --policy-name "GlueS3Access" \
        --policy-document "$S3_POLICY" \
        --profile "$AWS_PROFILE"
    
    print_success "Políticas adjuntadas"
    
    echo ""
}

create_s3_bucket() {
    print_header "Creando bucket S3 (si no existe)"
    
    # Verificar si el bucket existe
    if aws s3 ls "s3://${S3_BUCKET}" --profile "$AWS_PROFILE" 2>/dev/null; then
        print_info "Bucket ya existe: $S3_BUCKET"
    else
        print_step "Creando bucket S3..."
        
        if [ "$AWS_REGION" = "us-east-1" ]; then
            aws s3 mb "s3://${S3_BUCKET}" \
                --profile "$AWS_PROFILE"
        else
            aws s3 mb "s3://${S3_BUCKET}" \
                --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION" \
                --profile "$AWS_PROFILE"
        fi
        
        print_success "Bucket creado: $S3_BUCKET"
    fi
    
    echo ""
}

upload_script() {
    print_header "Subiendo script Glue a S3"
    
    print_step "Subiendo $GLUE_SCRIPT_LOCAL..."
    
    aws s3 cp "$GLUE_SCRIPT_LOCAL" "$S3_SCRIPTS_PATH/" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    print_success "Script subido a: $S3_SCRIPTS_PATH/"
    
    echo ""
}

upload_sample_data() {
    print_header "Subiendo datos de ejemplo a S3"
    
    # Crear CSV de ejemplo si no existe
    if [ ! -f "datos_clientes.csv" ]; then
        print_step "Creando datos de ejemplo..."
        
        cat > datos_clientes.csv << 'EOF'
id,nombre,email,ciudad,monto
1,Juan Perez,juan@example.com,Mexico,1500.00
2,Maria Garcia,maria@example.com,Guadalajara,2300.50
3,Carlos Lopez,carlos.lopez@example.com,Monterrey,890.75
4,Ana Martinez,ana@example.com,Mexico,3200.00
5,Roberto Sanchez,roberto@example.com,Puebla,1100.25
6,Laura Jimenez,laura@example.com,Veracruz,2800.00
7,Miguel Hernandez,miguel@example.com,Cancun,4100.50
8,Sofia Ramirez,sofia@example.com,Toluca,950.00
9,Diego Castro,diego@example.com,Querétaro,1750.75
10,Valentina Morales,valentina@example.com,Mexico,3500.00
EOF
    fi
    
    print_step "Subiendo datos de ejemplo..."
    
    aws s3 cp datos_clientes.csv "s3://${S3_BUCKET}/input-data/" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    print_success "Datos subidos a: s3://${S3_BUCKET}/input-data/"
    
    echo ""
}

create_glue_job() {
    print_header "Creando Job de AWS Glue"
    
    # Obtener ARN del rol
    ROLE_ARN=$(aws iam get-role --role-name "$GLUE_ROLE_NAME" \
        --profile "$AWS_PROFILE" \
        --query 'Role.Arn' --output text)
    
    print_step "Usando rol: $ROLE_ARN"
    
    # Crear o actualizar job
    SCRIPT_S3_PATH="${S3_SCRIPTS_PATH}/$(basename ${GLUE_SCRIPT_LOCAL})"
    
    print_step "Creando job: $GLUE_JOB_NAME"
    print_info "Script: $SCRIPT_S3_PATH"
    print_info "Entrada: $S3_INPUT_PATH"
    print_info "Salida: $S3_OUTPUT_PATH"
    
    # Verificar si el job ya existe
    if aws glue get-job --name "$GLUE_JOB_NAME" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" 2>/dev/null; then
        
        print_info "Job ya existe, actualizando..."
        
        aws glue update-job \
            --name "$GLUE_JOB_NAME" \
            --role "$ROLE_ARN" \
            --command Name=pythonshell,ScriptLocation="$SCRIPT_S3_PATH" \
            --default-arguments "{
                \"--job-bookmark-option\": \"job-bookmark-enable\",
                \"--S3_INPUT_PATH\": \"$S3_INPUT_PATH\",
                \"--S3_OUTPUT_PATH\": \"$S3_OUTPUT_PATH\",
                \"--MONTO_MINIMO\": \"$MONTO_MINIMO\",
                \"--AWS_REGION\": \"$AWS_REGION\"
            }" \
            --max-retries 1 \
            --timeout 2880 \
            --glue-version "$GLUE_VERSION" \
            --worker-type "$WORKER_TYPE" \
            --number-of-workers "$NUM_WORKERS" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"
        
        print_success "Job actualizado"
    else
        aws glue create-job \
            --name "$GLUE_JOB_NAME" \
            --role "$ROLE_ARN" \
            --command Name=pythonshell,ScriptLocation="$SCRIPT_S3_PATH" \
            --default-arguments "{
                \"--job-bookmark-option\": \"job-bookmark-enable\",
                \"--S3_INPUT_PATH\": \"$S3_INPUT_PATH\",
                \"--S3_OUTPUT_PATH\": \"$S3_OUTPUT_PATH\",
                \"--MONTO_MINIMO\": \"$MONTO_MINIMO\",
                \"--AWS_REGION\": \"$AWS_REGION\"
            }" \
            --max-retries 1 \
            --timeout 2880 \
            --glue-version "$GLUE_VERSION" \
            --worker-type "$WORKER_TYPE" \
            --number-of-workers "$NUM_WORKERS" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"
        
        print_success "Job creado: $GLUE_JOB_NAME"
    fi
    
    echo ""
}

run_glue_job() {
    print_header "Ejecutando Job de AWS Glue"
    
    print_step "Iniciando ejecución del job: $GLUE_JOB_NAME"
    
    RUN_ID=$(aws glue start-job-run \
        --job-name "$GLUE_JOB_NAME" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --query 'JobRunId' \
        --output text)
    
    print_success "Job iniciado con ID: $RUN_ID"
    
    # Monitorear ejecución
    print_step "Monitoreando ejecución..."
    
    while true; do
        STATUS=$(aws glue get-job-run \
            --job-name "$GLUE_JOB_NAME" \
            --run-id "$RUN_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" \
            --query 'JobRun.JobRunState' \
            --output text)
        
        echo -ne "\rEstado: $STATUS"
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            echo ""
            print_success "Job completado exitosamente"
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "TIMEOUT" ]; then
            echo ""
            print_error "Job falló con estado: $STATUS"
            
            # Mostrar logs de error
            print_step "Mostrando logs de error..."
            aws logs tail "/aws-glue/jobs/$GLUE_JOB_NAME" \
                --follow --since 5m \
                --profile "$AWS_PROFILE" \
                --region "$AWS_REGION" 2>/dev/null || true
            
            exit 1
        fi
        
        sleep 5
    done
    
    print_step "Mostrando logs de ejecución..."
    aws logs tail "/aws-glue/jobs/$GLUE_JOB_NAME" \
        --since 10m \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" 2>/dev/null || true
    
    echo ""
}

describe_job() {
    print_header "Describiendo Job de AWS Glue"
    
    aws glue get-job \
        --name "$GLUE_JOB_NAME" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --output table
    
    print_step "Últimas ejecuciones:"
    
    aws glue list-job-runs \
        --job-name "$GLUE_JOB_NAME" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --query 'JobRuns[0:5].[Id, JobRunState, StartedOn]' \
        --output table
    
    echo ""
}

delete_job() {
    print_header "Eliminando Job de AWS Glue"
    
    print_step "Eliminando job: $GLUE_JOB_NAME"
    
    aws glue delete-job \
        --name "$GLUE_JOB_NAME" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    
    print_success "Job eliminado"
    
    echo ""
}

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║         DESPLIEGUE DE AWS GLUE - SCRIPT ETL              ║
╚════════════════════════════════════════════════════════════╝

USO:
  ./glue_deployment.sh [COMANDO]

COMANDOS:
  setup          Configurar todo (crear rol, bucket, subir script, crear job)
  create         Crear job de Glue
  update         Actualizar job de Glue
  run            Ejecutar job de Glue
  describe       Describir job y últimas ejecuciones
  delete         Eliminar job de Glue
  logs           Ver logs del último job
  help           Mostrar esta ayuda

EJEMPLOS:
  ./glue_deployment.sh setup              # Configuración inicial
  ./glue_deployment.sh run                # Ejecutar job
  ./glue_deployment.sh describe           # Ver detalles del job

VARIABLES DE AMBIENTE:
  AWS_REGION           Región de AWS (default: us-east-1)
  AWS_PROFILE          Perfil de AWS (default: default)
  S3_BUCKET            Nombre del bucket S3

CONFIGURACIÓN:
  Job: demo-etl-glue
  Worker Type: G.1X (2 workers)
  Glue Version: 4.0
  Timeout: 2880 segundos

EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-setup}"
    
    case "$command" in
        setup)
            check_requirements
            create_iam_role
            create_s3_bucket
            upload_sample_data
            upload_script
            create_glue_job
            print_success "Setup completado"
            print_info "Ejecuta: ./glue_deployment.sh run"
            ;;
        create)
            check_requirements
            create_iam_role
            upload_script
            create_glue_job
            ;;
        update)
            check_requirements
            upload_script
            create_glue_job
            ;;
        run)
            check_requirements
            upload_script
            create_glue_job
            run_glue_job
            ;;
        describe)
            check_requirements
            describe_job
            ;;
        delete)
            check_requirements
            delete_job
            ;;
        logs)
            check_requirements
            print_header "Logs del Job"
            aws logs tail "/aws-glue/jobs/$GLUE_JOB_NAME" \
                --follow \
                --profile "$AWS_PROFILE" \
                --region "$AWS_REGION"
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Comando no reconocido: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
