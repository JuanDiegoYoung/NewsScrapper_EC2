#!/bin/bash

# stop_service_mac.sh
# Detener el servicio de scraping en macOS

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⏹️  Deteniendo servicio NewsScrapperEC2...${NC}"
echo ""

# Descargar el servicio
launchctl unload ~/Library/LaunchAgents/com.newscrapper.ec2.plist 2>/dev/null

# Verificar
if launchctl list | grep -q "com.newscrapper.ec2"; then
    echo -e "${RED}⚠️  El servicio aún está activo${NC}"
else
    echo -e "${GREEN}✅ Servicio detenido${NC}"
fi
