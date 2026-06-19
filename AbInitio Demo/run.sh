#!/bin/bash

###############################################################################
# run.sh - Script de inicio para Demo Ab Initio
# Uso: ./run.sh [bash|python|help]
###############################################################################

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/logs"

# Funciones
print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
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

check_prerequisites() {
    print_header "Verificando requisitos"
    
    local missing=0
    
    # Verificar bash
    if command -v bash &> /dev/null; then
        bash_version=$(bash --version | head -1)
        print_success "Bash: $bash_version"
    else
        print_error "Bash no encontrado"
        missing=$((missing + 1))
    fi
    
    # Verificar Python (solo para modo python)
    if [ "$1" = "python" ] || [ -z "$1" ]; then
        if command -v python3 &> /dev/null; then
            python_version=$(python3 --version)
            print_success "Python: $python_version"
        else
            print_error "Python3 no encontrado"
            missing=$((missing + 1))
        fi
    fi
    
    # Verificar Make
    if command -v make &> /dev/null; then
        make_version=$(make --version | head -1)
        print_success "Make: $make_version"
    else
        print_error "Make no encontrado (opcional)"
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

create_directories() {
    print_header "Preparando directorios"
    
    mkdir -p /tmp/input_data
    mkdir -p /tmp/output_data
    mkdir -p /tmp/logs
    mkdir -p /tmp/archive
    
    print_success "Directorios creados"
    echo ""
}

run_bash_demo() {
    print_header "Ejecutando Demo Bash"
    
    if [ ! -f "$SCRIPT_DIR/abinitio_demo.sh" ]; then
        print_error "Archivo abinitio_demo.sh no encontrado"
        return 1
    fi
    
    bash "$SCRIPT_DIR/abinitio_demo.sh"
    return $?
}

run_python_demo() {
    print_header "Ejecutando Demo Python"
    
    if [ ! -f "$SCRIPT_DIR/abinitio_demo.py" ]; then
        print_error "Archivo abinitio_demo.py no encontrado"
        return 1
    fi
    
    python3 "$SCRIPT_DIR/abinitio_demo.py"
    return $?
}

show_results() {
    print_header "Resultados"
    
    if [ -d "/tmp/output_data" ] && [ -n "$(ls -A /tmp/output_data 2>/dev/null)" ]; then
        echo -e "${YELLOW}Archivos generados:${NC}"
        ls -lh /tmp/output_data/
        
        echo ""
        echo -e "${YELLOW}Primeros registros del CSV:${NC}"
        head -3 /tmp/output_data/datos_transformados_*.csv 2>/dev/null | head -10
        
        echo ""
        echo -e "${YELLOW}Reporte de calidad:${NC}"
        if command -v jq &> /dev/null; then
            cat /tmp/output_data/reporte_*.json 2>/dev/null | jq '.' | head -20
        else
            cat /tmp/output_data/reporte_*.json 2>/dev/null | head -20
        fi
    else
        print_info "No hay resultados. Ejecuta primero: ./run.sh python"
    fi
    echo ""
}

show_logs() {
    print_header "Logs"
    
    if [ -d "$LOG_DIR" ] && [ -n "$(ls -A $LOG_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}Últimas líneas del log:${NC}"
        tail -20 "$LOG_DIR"/*.log 2>/dev/null
    else
        print_info "No hay logs disponibles"
    fi
    echo ""
}

show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║          DEMO AB INITIO - ETL EN RHEL/LINUX              ║
╚════════════════════════════════════════════════════════════╝

USO:
  ./run.sh [OPCIÓN]

OPCIONES:
  python        Ejecutar demo en Python (recomendado)
  bash          Ejecutar demo en Bash
  results       Ver resultados de última ejecución
  logs          Ver logs de ejecución
  clean         Limpiar archivos generados
  help          Mostrar esta ayuda
  (ninguna)     Ejecutar demo Python por defecto

EJEMPLOS:
  ./run.sh python          # Ejecutar demo en Python
  ./run.sh bash            # Ejecutar demo en Bash
  ./run.sh results         # Ver archivos generados
  ./run.sh logs            # Ver logs
  ./run.sh clean           # Limpiar

DIRECTORIOS:
  /tmp/input_data/         Archivos de entrada
  /tmp/output_data/        Archivos procesados
  /tmp/logs/              Logs de ejecución
  /tmp/archive/           Backups

REQUISITOS:
  - Bash 4.0+
  - Python 3.6+ (para demo Python)
  - Make (opcional, para usar Makefile)

ARCHIVOS:
  abinitio_demo.py        Demo en Python (POO)
  abinitio_demo.sh        Demo en Bash
  pipeline_config.json    Configuración del flujo
  Makefile                Automatización (usar: make help)
  README.md               Documentación completa

Para más información: cat README.md

EOF
}

cleanup() {
    print_header "Limpiando"
    
    rm -rf /tmp/input_data /tmp/output_data /tmp/logs /tmp/archive
    print_success "Archivos limpios"
    echo ""
}

# Main
main() {
    local mode="${1:-python}"
    
    case "$mode" in
        help)
            show_help
            ;;
        python)
            check_prerequisites python || exit 1
            create_directories
            run_python_demo
            local result=$?
            if [ $result -eq 0 ]; then
                print_success "Demo completada exitosamente"
                echo ""
                echo -e "${YELLOW}Para ver resultados ejecuta:${NC} ./run.sh results"
                echo ""
            fi
            exit $result
            ;;
        bash)
            check_prerequisites bash || exit 1
            create_directories
            run_bash_demo
            local result=$?
            if [ $result -eq 0 ]; then
                print_success "Demo completada exitosamente"
                echo ""
                echo -e "${YELLOW}Para ver resultados ejecuta:${NC} ./run.sh results"
                echo ""
            fi
            exit $result
            ;;
        results)
            show_results
            ;;
        logs)
            show_logs
            ;;
        clean)
            cleanup
            ;;
        *)
            print_error "Opción no reconocida: $mode"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar
main "$@"
