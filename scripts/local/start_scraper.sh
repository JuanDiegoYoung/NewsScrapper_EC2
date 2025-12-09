#!/bin/bash

# start_scraper.sh
# Ejecutar el scraper manualmente para pruebas

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Iniciando NewsScrapperEC2...${NC}"
echo ""

# Cambiar al directorio del script
cd "$(dirname "$0")"

# Verificar que existe el entorno virtual
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}⚠️  Entorno virtual no encontrado. Ejecuta ./setup_ec2.sh primero${NC}"
    exit 1
fi

# Verificar que existe .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado. Configura tus credenciales primero${NC}"
    exit 1
fi

# Activar entorno virtual
source venv/bin/activate

# Cargar variables de entorno
export $(grep -v '^#' .env | xargs)

# Configurar PYTHONPATH
export PYTHONPATH=$PWD

# Crear directorio de logs si no existe
mkdir -p logs

# Ejecutar scraper
echo -e "${GREEN}📰 Scrapeando noticias...${NC}"
python src/scraper/scrape_and_summarize.py 2>&1 | tee -a logs/scraper_manual.log

echo ""
echo -e "${GREEN}✅ Scraping completado!${NC}"
echo -e "Revisa los logs en: ${YELLOW}logs/scraper_manual.log${NC}"
echo ""
