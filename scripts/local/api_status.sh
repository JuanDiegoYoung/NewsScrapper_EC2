#!/bin/bash

# api_status.sh
# Ver el estado del servidor API

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Estado API${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar si está corriendo
PID=$(ps aux | grep '[u]vicorn api:app' | awk '{print $2}')

if [ -n "$PID" ]; then
    echo -e "${GREEN}✅ API: ACTIVA${NC}"
    echo -e "   PID: $PID"
    echo -e "   Puerto: 8000"
    echo ""
    
    # Test de conectividad
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Conectividad: OK${NC}"
    else
        echo -e "${RED}❌ Conectividad: FALLO${NC}"
    fi
else
    echo -e "${RED}❌ API: INACTIVA${NC}"
    echo ""
    echo -e "${YELLOW}Para iniciar: ./start_api.sh${NC}"
fi

echo ""
echo -e "${YELLOW}📚 Documentación:${NC}"
echo "   Swagger UI: http://localhost:8000/docs"
echo "   ReDoc: http://localhost:8000/redoc"

echo ""
echo -e "${YELLOW}🔑 API Key (desde Secrets Manager):${NC}"
echo "   api-newscrapper-key01"

echo ""
echo -e "${YELLOW}📝 Endpoints disponibles:${NC}"
echo "   GET  /                  - Health check"
echo "   GET  /health            - Health status"
echo "   GET  /resumen/latest    - Último resumen"
echo "   GET  /resumen/{fecha}   - Resumen por fecha"
echo "   GET  /historico         - Todo el histórico"
echo "   GET  /rss/list          - Feeds RSS"
echo "   POST /scrape/run        - Forzar scraping"

if [ -f "logs/api.log" ]; then
    echo ""
    echo -e "${YELLOW}📝 Últimas 5 líneas del log:${NC}"
    tail -5 logs/api.log | sed 's/^/  /'
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
