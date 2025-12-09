#!/bin/bash

# backup.sh
# Crear backup de datos y logs

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_DIR="$HOME/backups/newscrapper"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="newscrapper_backup_${DATE}.tar.gz"

echo -e "${GREEN}📦 Creando backup de NewsScrapperEC2...${NC}"
echo ""

# Crear directorio de backups
mkdir -p $BACKUP_DIR

# Crear backup
echo -e "${YELLOW}Empaquetando archivos...${NC}"
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    data/ logs/ .env 2>/dev/null || true

SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
echo -e "${GREEN}✅ Backup creado: $BACKUP_FILE ($SIZE)${NC}"
echo -e "Ubicación: ${YELLOW}$BACKUP_DIR/$BACKUP_FILE${NC}"
echo ""

# Limpiar backups antiguos (mantener últimos 10)
echo -e "${YELLOW}Limpiando backups antiguos...${NC}"
cd $BACKUP_DIR
ls -t newscrapper_backup_*.tar.gz | tail -n +11 | xargs rm -f 2>/dev/null || true
REMAINING=$(ls -1 newscrapper_backup_*.tar.gz 2>/dev/null | wc -l)
echo -e "${GREEN}Backups actuales: $REMAINING${NC}"
echo ""

# Opcional: Subir a S3
if [ ! -z "$BUCKET" ] && command -v aws &> /dev/null; then
    echo -e "${YELLOW}¿Subir backup a S3? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Subiendo a S3...${NC}"
        aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$BUCKET/backups/" && \
            echo -e "${GREEN}✅ Backup subido a S3${NC}" || \
            echo -e "${RED}❌ Error subiendo a S3${NC}"
    fi
fi

echo -e "${GREEN}✅ Backup completado!${NC}"
