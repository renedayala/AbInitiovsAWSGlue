#!/bin/bash

###############################################################################
# QUICK START - AWS GLUE DEMO ETL
# Guía de inicio rápido en 5 pasos
###############################################################################

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# ============================================================================
# PASO 1: VERIFICAR REQUISITOS
# ============================================================================

step_1_check_requirements() {
    print_header "PASO 1: Verificar Requisitos"
    
    local missing=0
    
    # AWS CLI
    if command -v aws &> /dev/null; then
        print_success "AWS CLI instalado"
    else
        print_error "AWS CLI NO instalado"
        echo "Instalar desde: https://aws.amazon.com/cli/"
        missing=$((missing + 1))
    fi
    
    # Python
    if command -v python3 &> /dev/null; then
        version=$(python3 --version | cut -d' ' -f2)
        print_success "Python $version instalado"
    else
        print_error "Python NO instalado"
        missing=$((missing + 1))
    fi
    
    # Terraform (opcional)
    if command -v terraform &> /dev/null; then
        print_success "Terraform instalado"
    else
        print_step "Terraform NO encontrado (optional para Terraform deploy)"
    fi
    
    # AWS Credentials
    if aws sts get-caller-identity &> /dev/null; then
        account=$(aws sts get-caller-identity --query Account --output text)
        print_success "Credenciales AWS válidas (Cuenta: $account)"
    else
        print_error "Credenciales AWS NO configuradas"
        echo "Ejecuta: aws configure"
        missing=$((missing + 1))
    fi
    
    echo ""
    
    if [ $missing -gt 0 ]; then
        print_error "Faltan $missing requisitos"
        return 1
    else
        print_success "Todos los requisitos satisfechos"
        return 0
    fi
}

# ============================================================================
# PASO 2: PRUEBAS LOCALES
# ============================================================================

step_2_local_tests() {
    print_header "PASO 2: Ejecutar Pruebas Locales (sin AWS)"
    
    print_step "Corriendo tests locales..."
    
    if [ -f "test_glue_local.py" ]; then
        python3 test_glue_local.py
        echo ""
        print_success "Pruebas locales pasadas"
    else
        print_error "test_glue_local.py no encontrado"
        return 1
    fi
}

# ============================================================================
# PASO 3: DESPLEGAR EN AWS
# ============================================================================

step_3_deploy_to_aws() {
    print_header "PASO 3: Desplegar en AWS Glue"
    
    echo -e "${YELLOW}¿Qué método prefieres?${NC}"
    echo "1) Script de despliegue (recomendado)"
    echo "2) Terraform"
    echo "3) Saltar (deploy manual)"
    echo ""
    read -p "Selecciona (1-3): " choice
    
    case $choice in
        1)
            print_step "Usando script de despliegue..."
            if [ -f "glue_deployment.sh" ]; then
                chmod +x glue_deployment.sh
                ./glue_deployment.sh setup
                print_success "Despliegue completado con script"
            else
                print_error "glue_deployment.sh no encontrado"
                return 1
            fi
            ;;
        2)
            print_step "Usando Terraform..."
            if command -v terraform &> /dev/null; then
                terraform init
                terraform apply
                print_success "Despliegue completado con Terraform"
            else
                print_error "Terraform no instalado"
                return 1
            fi
            ;;
        3)
            print_step "Despliegue manual"
            echo "Sigue los pasos en README_GLUE.md > Despliegue"
            ;;
    esac
}

# ============================================================================
# PASO 4: EJECUTAR JOB
# ============================================================================

step_4_run_job() {
    print_header "PASO 4: Ejecutar Job en AWS Glue"
    
    print_step "Iniciando ejecución del job..."
    
    if [ -f "glue_deployment.sh" ]; then
        ./glue_deployment.sh run
        print_success "Job ejecutado"
    else
        echo "Ejecuta manualmente:"
        echo "  aws glue start-job-run --job-name demo-etl-glue"
    fi
}

# ============================================================================
# PASO 5: VERIFICAR RESULTADOS
# ============================================================================

step_5_verify_results() {
    print_header "PASO 5: Verificar Resultados"
    
    print_step "Buscando archivos de salida en S3..."
    
    # Obtener nombre del bucket
    bucket=$(aws s3 ls | grep demo-etl-glue | awk '{print $3}' | head -1)
    
    if [ -z "$bucket" ]; then
        print_error "Bucket no encontrado"
        echo "Verifica manualmente en AWS S3 Console"
        return 0
    fi
    
    print_success "Bucket encontrado: $bucket"
    echo ""
    
    print_step "Contenido de output-data/:"
    aws s3 ls "s3://${bucket}/output-data/" --recursive | head -10
    
    echo ""
    print_step "Descargando reporte..."
    
    report=$(aws s3 ls "s3://${bucket}/output-data/" --recursive | grep reporte | head -1 | awk '{print $NF}')
    
    if [ -n "$report" ]; then
        aws s3 cp "s3://${bucket}/${report}" /tmp/reporte.json
        
        echo ""
        print_success "Contenido del reporte:"
        cat /tmp/reporte.json | python3 -m json.tool 2>/dev/null || cat /tmp/reporte.json
    else
        print_step "Reporte no encontrado aún (job puede estar en progreso)"
    fi
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

show_menu() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════╗
║        AWS GLUE - DEMO ETL QUICK START                   ║
╚════════════════════════════════════════════════════════════╝

Pasos:
  1) Verificar requisitos
  2) Ejecutar pruebas locales (sin AWS)
  3) Desplegar en AWS Glue
  4) Ejecutar Job
  5) Verificar resultados
  all) Ejecutar todos los pasos
  help) Mostrar ayuda
  exit) Salir

EOF
}

show_help() {
    cat << 'EOF'

════════════════════════════════════════════════════════════
AWS GLUE QUICK START - AYUDA
════════════════════════════════════════════════════════════

¿QUÉ HACE CADA PASO?

1. Verificar Requisitos
   - Comprueba que tengas AWS CLI, Python, credenciales

2. Pruebas Locales
   - Ejecuta tests SIN AWS (validación local)
   - Toma ~30 segundos

3. Desplegar en AWS
   - Opción A: Script automatizado (recomendado)
   - Opción B: Terraform (Infrastructure as Code)
   - Crea rol IAM, bucket S3, y job de Glue

4. Ejecutar Job
   - Inicia ejecución del job en AWS Glue
   - Monitorea progreso en tiempo real

5. Verificar Resultados
   - Descarga outputs desde S3
   - Muestra reporte JSON

═══════════════════════════════════════════════════════════

REQUISITOS PREVIOS:
  ✓ AWS Account activa
  ✓ AWS CLI configurado (aws configure)
  ✓ Python 3.8+
  ✓ Internet conectado

COSTOS ESTIMADOS:
  - Pruebas locales: $0
  - Un job de Glue (2 workers, 5 min): ~$0.07
  - S3 storage (1 GB): ~$0.023
  Total: ~$0.10 por ejecución

DOCUMENTACIÓN:
  - README_GLUE.md (completa)
  - glue_deployment.sh (script detallado)
  - glue_job.py (código fuente)

═══════════════════════════════════════════════════════════

EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    while true; do
        show_menu
        read -p "Selecciona opción: " option
        
        case $option in
            1)
                step_1_check_requirements || true
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                step_2_local_tests || true
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                step_3_deploy_to_aws || true
                read -p "Presiona Enter para continuar..."
                ;;
            4)
                step_4_run_job || true
                read -p "Presiona Enter para continuar..."
                ;;
            5)
                step_5_verify_results || true
                read -p "Presiona Enter para continuar..."
                ;;
            all)
                step_1_check_requirements || exit 1
                echo ""
                step_2_local_tests || exit 1
                echo ""
                step_3_deploy_to_aws || exit 1
                echo ""
                step_4_run_job || exit 1
                echo ""
                step_5_verify_results
                echo ""
                print_success "¡Todos los pasos completados!"
                break
                ;;
            help)
                show_help
                ;;
            exit)
                print_success "Saliendo..."
                break
                ;;
            *)
                print_error "Opción no válida"
                ;;
        esac
        
        clear
    done
}

# Ejecutar
clear
main
