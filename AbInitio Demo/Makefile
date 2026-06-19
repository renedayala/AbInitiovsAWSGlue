.PHONY: help setup run-bash run-python clean view-output view-logs

SHELL := /bin/bash
PYTHON := python3
BASH := bash

# Directorios
INPUT_DIR := /tmp/input_data
OUTPUT_DIR := /tmp/output_data
LOG_DIR := /tmp/logs
ARCHIVE_DIR := /tmp/archive

# Colores para output
GREEN := \033[0;32m
BLUE := \033[0;34m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)    DEMO AB INITIO - ETL EN RHEL/LINUX$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Comandos disponibles:$(NC)"
	@echo ""
	@echo "  $(YELLOW)make setup$(NC)         - Crear directorios y preparar ambiente"
	@echo "  $(YELLOW)make run-bash$(NC)      - Ejecutar demo en Bash"
	@echo "  $(YELLOW)make run-python$(NC)    - Ejecutar demo en Python (POO)"
	@echo "  $(YELLOW)make view-output$(NC)   - Ver archivos generados"
	@echo "  $(YELLOW)make view-logs$(NC)     - Ver logs de ejecución"
	@echo "  $(YELLOW)make clean$(NC)         - Limpiar archivos generados"
	@echo "  $(YELLOW)make help$(NC)          - Mostrar esta ayuda"
	@echo ""
	@echo "$(GREEN)Ejemplo de uso:$(NC)"
	@echo "  $(BLUE)$$ make setup$(NC)"
	@echo "  $(BLUE)$$ make run-python$(NC)"
	@echo "  $(BLUE)$$ make view-output$(NC)"
	@echo ""

setup:
	@echo "$(GREEN)[SETUP]$(NC) Creando directorios necesarios..."
	@mkdir -p $(INPUT_DIR)
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(LOG_DIR)
	@mkdir -p $(ARCHIVE_DIR)
	@chmod +x abinitio_demo.sh
	@chmod +x abinitio_demo.py
	@echo "$(GREEN)[OK]$(NC) Directorios creados:"
	@echo "  - Entrada: $(INPUT_DIR)"
	@echo "  - Salida: $(OUTPUT_DIR)"
	@echo "  - Logs: $(LOG_DIR)"
	@echo "  - Archivo: $(ARCHIVE_DIR)"
	@echo ""

run-bash: setup
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)EJECUTANDO DEMO BASH$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@$(BASH) ./abinitio_demo.sh
	@echo ""
	@echo "$(GREEN)[COMPLETADO]$(NC) Ver resultados con: $(YELLOW)make view-output$(NC)"

run-python: setup
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)EJECUTANDO DEMO PYTHON (POO)$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@$(PYTHON) ./abinitio_demo.py
	@echo ""
	@echo "$(GREEN)[COMPLETADO]$(NC) Ver resultados con: $(YELLOW)make view-output$(NC)"

view-output:
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)ARCHIVOS GENERADOS EN: $(OUTPUT_DIR)$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if [ -d "$(OUTPUT_DIR)" ] && [ -n "$$(ls -A $(OUTPUT_DIR) 2>/dev/null)" ]; then \
		echo "$(GREEN)Listado de archivos:$(NC)"; \
		ls -lh $(OUTPUT_DIR)/; \
		echo ""; \
		echo "$(YELLOW)Primeras líneas del CSV:$(NC)"; \
		head -5 $(OUTPUT_DIR)/datos_transformados_*.csv 2>/dev/null | head -20; \
		echo ""; \
		echo "$(YELLOW)Reporte de calidad (JSON):$(NC)"; \
		cat $(OUTPUT_DIR)/reporte_*.json 2>/dev/null | head -30; \
	else \
		echo "$(RED)[ERROR]$(NC) No hay archivos generados. Ejecuta: $(YELLOW)make run-python$(NC)"; \
	fi
	@echo ""

view-logs:
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)LOGS DE EJECUCIÓN: $(LOG_DIR)$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if [ -d "$(LOG_DIR)" ] && [ -n "$$(ls -A $(LOG_DIR) 2>/dev/null)" ]; then \
		echo "$(GREEN)Archivos de log:$(NC)"; \
		ls -lh $(LOG_DIR)/; \
		echo ""; \
		echo "$(YELLOW)Contenido del último log:$(NC)"; \
		tail -50 $(LOG_DIR)/*.log 2>/dev/null; \
	else \
		echo "$(RED)[ERROR]$(NC) No hay logs disponibles."; \
	fi
	@echo ""

clean:
	@echo "$(YELLOW)Limpiando archivos generados...$(NC)"
	@rm -rf $(INPUT_DIR)
	@rm -rf $(OUTPUT_DIR)
	@rm -rf $(LOG_DIR)
	@rm -rf $(ARCHIVE_DIR)
	@echo "$(GREEN)[OK]$(NC) Directorios limpios."
	@echo ""

# Target para examinar la configuración
examine-config:
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)CONFIGURACIÓN DEL PIPELINE$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if command -v jq &> /dev/null; then \
		cat pipeline_config.json | jq '.pipeline | {name, version, description, componentes: (.components | length)}'; \
	else \
		cat pipeline_config.json; \
	fi
	@echo ""

# Target para estadísticas
stats:
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)ESTADÍSTICAS DEL DEMO$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Tamaño de archivos:$(NC)"
	@du -sh $(INPUT_DIR) $(OUTPUT_DIR) $(LOG_DIR) 2>/dev/null || echo "  (Sin archivos generados aún)"
	@echo ""
	@echo "$(YELLOW)Cantidad de líneas de código:$(NC)"
	@wc -l *.sh *.py 2>/dev/null | tail -1
	@echo ""

.DEFAULT_GOAL := help
