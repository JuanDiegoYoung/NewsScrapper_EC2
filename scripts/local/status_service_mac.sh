#!/bin/bash

# status_service_mac.sh
# Ver el estado del servicio en macOS

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Estado del Servicio${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar si está cargado
if launchctl list | grep -q "com.newscrapper.ec2"; then
    echo -e "${GREEN}✅ Servicio: ACTIVO${NC}"
    echo ""
    
    # Información del servicio
    launchctl list | grep com.newscrapper.ec2 | while read pid status name; do
        if [ "$pid" != "-" ]; then
            echo -e "${GREEN}🔄 Última ejecución: PID $pid${NC}"
        else
            echo -e "${YELLOW}⏳ Esperando próxima ejecución${NC}"
        fi
    done
else
    echo -e "${RED}❌ Servicio: INACTIVO${NC}"
    echo ""
    echo -e "${YELLOW}Para iniciar: ./start_service_mac.sh${NC}"
fi

echo ""
echo -e "${YELLOW}📊 Configuración:${NC}"
echo "  Frecuencia: Diaria a las 9:00 AM (hora local)"
echo "  Zona horaria: Uruguay (UTC-3)"
echo ""

# Últimos logs
if [ -f "logs/scraper.log" ]; then
    echo -e "${YELLOW}📝 Últimas 5 líneas del log:${NC}"
    tail -5 logs/scraper.log | sed 's/^/  /'
    echo ""
fi

# Archivos en S3
echo -e "${YELLOW}☁️  Últimos archivos en S3:${NC}"
aws s3 ls s3://jd-finance-news/runs/ --recursive --human-readable 2>/dev/null | tail -3 | sed 's/^/  /' || echo "  No se pudo acceder a S3"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
