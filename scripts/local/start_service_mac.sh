#!/bin/bash

# start_service_mac.sh
# Iniciar el servicio de scraping en macOS

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Iniciando servicio NewsScrapperEC2 en macOS...${NC}"
echo ""

# Cargar el servicio
launchctl load ~/Library/LaunchAgents/com.newscrapper.ec2.plist 2>/dev/null || echo "Servicio ya está cargado"

# Verificar estado
if launchctl list | grep -q "com.newscrapper.ec2"; then
    echo -e "${GREEN}✅ Servicio activo${NC}"
    echo ""
    echo -e "${YELLOW}El scraper se ejecutará:${NC}"
    echo "  - Cada 6 horas automáticamente"
    echo "  - Inmediatamente al iniciar el sistema"
    echo ""
    echo -e "${YELLOW}Logs en:${NC}"
    echo "  ~/Documents/NewsScrapperEC2/logs/scraper.log"
    echo "  ~/Documents/NewsScrapperEC2/logs/scraper_error.log"
else
    echo -e "${RED}❌ Error al cargar el servicio${NC}"
    exit 1
fi
