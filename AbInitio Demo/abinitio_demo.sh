#!/bin/bash

###############################################################################
# DEMO: Flujo Ab Initio Simulado en RHEL
# Propósito: Leer CSV, procesar datos, mover a directorio del sistema
###############################################################################

# Configuración de directorios
SOURCE_DIR="/tmp/input_data"
PROCESS_DIR="/tmp/processed_data"
TARGET_DIR="/opt/data_warehouse"  # Directorio de RHEL (requiere permisos)
LOG_DIR="/var/log/abinitio_demo"
ARCHIVE_DIR="/tmp/archive"

# Crear directorios necesarios
create_directories() {
    echo "[INFO] Creando directorios necesarios..."
    mkdir -p "$SOURCE_DIR"
    mkdir -p "$PROCESS_DIR"
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$LOG_DIR"
    
    # Para directorio de sistema, usar /tmp si no tienes permisos root
    if [ ! -d "$TARGET_DIR" ]; then
        echo "[WARN] $TARGET_DIR no existe. Usando /tmp/output_data"
        TARGET_DIR="/tmp/output_data"
        mkdir -p "$TARGET_DIR"
    fi
}

# Crear archivo CSV de ejemplo
create_sample_csv() {
    echo "[INFO] Creando archivo CSV de ejemplo..."
    cat > "$SOURCE_DIR/datos_clientes.csv" << 'EOF'
id,nombre,email,ciudad,monto
1,Juan Perez,juan@example.com,Mexico,1500.00
2,Maria Garcia,maria@example.com,Guadalajara,2300.50
3,Carlos Lopez,carlos@example.com,Monterrey,890.75
4,Ana Martinez,ana@example.com,Mexico,3200.00
5,Roberto Sanchez,roberto@example.com,Puebla,1100.25
EOF
    echo "[OK] CSV creado en: $SOURCE_DIR/datos_clientes.csv"
}

# Validar archivo CSV
validate_csv() {
    local csv_file=$1
    echo "[INFO] Validando CSV: $csv_file"
    
    if [ ! -f "$csv_file" ]; then
        echo "[ERROR] Archivo no existe: $csv_file"
        return 1
    fi
    
    # Verificar que tenga encabezados y datos
    local lines=$(wc -l < "$csv_file")
    if [ "$lines" -lt 2 ]; then
        echo "[ERROR] CSV inválido (menos de 2 líneas)"
        return 1
    fi
    
    echo "[OK] CSV válido ($lines líneas)"
    return 0
}

# Transformar datos (filtrar y agregar columna)
transform_csv() {
    local input_file=$1
    local output_file=$2
    
    echo "[INFO] Transformando datos..."
    
    # Leer encabezado
    local header=$(head -1 "$input_file")
    
    # Agregar nueva columna y filtrar montos > 1000
    {
        echo "$header,categoria,fecha_proceso"
        tail -n +2 "$input_file" | while IFS=',' read -r id nombre email ciudad monto; do
            # Filtrar: solo registros con monto > 1000
            if (( $(echo "$monto > 1000" | bc -l) )); then
                # Categorizar por monto
                if (( $(echo "$monto > 2000" | bc -l) )); then
                    categoria="Premium"
                else
                    categoria="Estándar"
                fi
                fecha=$(date '+%Y-%m-%d')
                echo "$id,$nombre,$email,$ciudad,$monto,$categoria,$fecha"
            fi
        done
    } > "$output_file"
    
    echo "[OK] Datos transformados. Salida: $output_file"
}

# Generar reporte de calidad
generate_quality_report() {
    local input_file=$1
    local report_file=$2
    
    echo "[INFO] Generando reporte de calidad..."
    
    {
        echo "=== REPORTE DE CALIDAD DE DATOS ==="
        echo "Fecha: $(date)"
        echo ""
        echo "Archivo procesado: $(basename $input_file)"
        echo "Total de registros: $(tail -n +2 $input_file | wc -l)"
        echo "Monto total procesado: $(tail -n +2 $input_file | cut -d',' -f5 | paste -sd+ | bc)"
        echo "Monto promedio: $(tail -n +2 $input_file | cut -d',' -f5 | awk '{sum+=$1; count++} END {printf "%.2f", sum/count}')"
        echo ""
        echo "Registros por categoría:"
        tail -n +2 $input_file | cut -d',' -f6 | sort | uniq -c
        echo ""
        echo "Estado: OK"
    } > "$report_file"
    
    cat "$report_file"
}

# Mover archivo a directorio destino
move_to_destination() {
    local source_file=$1
    local dest_dir=$2
    
    echo "[INFO] Moviendo archivo a directorio de destino..."
    
    # Crear backup en archivo
    local backup_name="${SOURCE_DIR}/backup_$(date '+%Y%m%d_%H%M%S').csv"
    cp "$source_file" "$backup_name"
    echo "[OK] Backup creado: $backup_name"
    
    # Mover archivo al directorio destino
    cp "$source_file" "$dest_dir/"
    echo "[OK] Archivo copiado a: $dest_dir/"
    
    # Guardar en archivo
    local final_name="$(basename $source_file .csv)_$(date '+%Y%m%d_%H%M%S').csv"
    mv "$source_file" "$dest_dir/$final_name"
    echo "[OK] Archivo final: $dest_dir/$final_name"
}

# Registrar en log de auditoría
audit_log() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_DIR/audit.log"
}

# Ejecutar flujo completo
main() {
    echo "=========================================="
    echo "  DEMO AB INITIO - FLUJO DE DATOS RHEL"
    echo "=========================================="
    echo ""
    
    audit_log "Iniciando flujo de procesamiento"
    
    create_directories
    create_sample_csv
    
    if validate_csv "$SOURCE_DIR/datos_clientes.csv"; then
        transform_csv "$SOURCE_DIR/datos_clientes.csv" "$PROCESS_DIR/datos_transformados.csv"
        generate_quality_report "$PROCESS_DIR/datos_transformados.csv" "$LOG_DIR/reporte_calidad.txt"
        move_to_destination "$PROCESS_DIR/datos_transformados.csv" "$TARGET_DIR"
        audit_log "Flujo completado exitosamente"
        
        echo ""
        echo "=========================================="
        echo "[ÉXITO] Flujo completado"
        echo "Archivo final en: $TARGET_DIR"
        echo "Logs disponibles en: $LOG_DIR"
        echo "=========================================="
    else
        audit_log "Error en validación de CSV"
        echo "[ERROR] Flujo fallido"
        exit 1
    fi
}

# Ejecutar
main "$@"
