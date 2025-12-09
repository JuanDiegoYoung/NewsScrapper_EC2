#!/bin/bash

# stop_scraper.sh
# Detener el servicio de scraping

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⏹️  Deteniendo NewsScrapperEC2...${NC}"
echo ""

# Verificar si el timer está corriendo
if sudo systemctl is-active --quiet newscrapper-ec2.timer; then
    echo -e "${GREEN}Deteniendo timer...${NC}"
    sudo systemctl stop newscrapper-ec2.timer
    echo "✅ Timer detenido"
fi

# Verificar si hay un job corriendo
if sudo systemctl is-active --quiet newscrapper-ec2.service; then
    echo -e "${GREEN}Deteniendo job en ejecución...${NC}"
    sudo systemctl stop newscrapper-ec2.service
    echo "✅ Job detenido"
fi

# Verificar si la API está corriendo
if sudo systemctl is-active --quiet newscrapper-ec2-api.service; then
    echo -e "${GREEN}Deteniendo API...${NC}"
    sudo systemctl stop newscrapper-ec2-api.service
    echo "✅ API detenida"
fi

# También matar cualquier proceso Python relacionado
SCRAPER_PIDS=$(pgrep -f "scrape_and_summarize.py" || true)
if [ ! -z "$SCRAPER_PIDS" ]; then
    echo -e "${YELLOW}Matando procesos adicionales...${NC}"
    kill $SCRAPER_PIDS 2>/dev/null || true
    echo "✅ Procesos adicionales detenidos"
fi

echo ""
echo -e "${GREEN}✅ NewsScrapperEC2 detenido completamente${NC}"
echo ""
echo -e "${YELLOW}Para ver el estado:${NC}"
echo "  sudo systemctl status newscrapper-ec2.timer"
echo "  sudo systemctl status newscrapper-ec2-api"
echo ""
