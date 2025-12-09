#!/bin/bash

# deploy_ec2.sh
# Script para deployar NewsScrapperEC2 en EC2
# Uso: ./deploy_ec2.sh <EC2_IP>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validar argumentos
if [ "$#" -ne 1 ]; then
    echo -e "${RED}Error: Se requiere la IP del servidor EC2${NC}"
    echo "Uso: $0 <EC2_IP>"
    echo "Ejemplo: $0 54.123.456.789"
    echo ""
    
    # Intentar leer de ec2_info.txt
    if [ -f "$PROJECT_ROOT/deployment/ec2_info.txt" ]; then
        source "$PROJECT_ROOT/deployment/ec2_info.txt"
        echo -e "${YELLOW}💡 IP encontrada en ec2_info.txt: ${ELASTIC_IP}${NC}"
        read -p "¿Usar esta IP? (y/n): " USE_SAVED
        if [ "$USE_SAVED" = "y" ]; then
            EC2_HOST=$ELASTIC_IP
        else
            exit 1
        fi
    else
        exit 1
    fi
else
    EC2_HOST=$1
fi

EC2_USER="ubuntu"
REMOTE_DIR="/home/$EC2_USER/NewsScrapperEC2"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Deployment a EC2${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Servidor: ${EC2_HOST}${NC}"
echo ""

# Cambiar al directorio del proyecto
cd "$PROJECT_ROOT"

# 1. Crear tarball del proyecto
echo -e "${GREEN}📦 Empaquetando proyecto...${NC}"
tar -czf /tmp/newscrapper.tar.gz \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.git' \
    --exclude='venv' \
    --exclude='*.log' \
    --exclude='data/*.json' \
    --exclude='data/*.jsonl' \
    --exclude='deployment/ec2_info.txt' \
    --exclude='*.tar.gz' \
    src/ config/ scripts/ docs/ tests/ .env.example .gitignore README.md

echo -e "${GREEN}✅ Proyecto empaquetado${NC}"

# 2. Copiar archivo al servidor
echo ""
echo -e "${GREEN}📤 Copiando archivos a EC2...${NC}"
scp /tmp/newscrapper.tar.gz ${EC2_USER}@${EC2_HOST}:~/

# 3. Ejecutar comandos remotos
echo -e "${GREEN}🔧 Configurando en servidor remoto...${NC}"
ssh ${EC2_USER}@${EC2_HOST} << 'ENDSSH'
set -e

# Crear directorio si no existe
mkdir -p ~/NewsScrapperEC2
cd ~/NewsScrapperEC2

# Descomprimir archivos
echo "Descomprimiendo archivos..."
tar -xzf ~/newscrapper.tar.gz -C .
rm ~/newscrapper.tar.gz

# Hacer ejecutables los scripts
chmod +x setup_ec2.sh setup_systemd.sh start_scraper.sh stop_scraper.sh monitor.sh quick_update.sh

echo "✅ Archivos copiados exitosamente"
echo ""
echo "Siguiente paso: Ejecutar en el servidor EC2:"
echo "  cd ~/NewsScrapperEC2"
echo "  ./setup_ec2.sh"
ENDSSH

# 4. Limpiar archivo local
rm newscrapper.tar.gz

echo ""
echo -e "${GREEN}✅ Deployment completado!${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos en el servidor EC2:${NC}"
echo -e "1. ssh ${EC2_USER}@${EC2_HOST}"
echo -e "2. cd ~/NewsScrapperEC2"
echo -e "3. ./setup_ec2.sh"
echo -e "4. Configurar variables de entorno en .env"
echo -e "5. ./setup_systemd.sh    # Para configurar servicio automático"
echo ""
