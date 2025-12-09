#!/bin/bash

# monitor.sh
# Script para monitorear el estado del NewsScrapperEC2 en EC2

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Monitor de Estado${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Función para verificar estado de servicio
check_service() {
    local service=$1
    local name=$2
    
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "${name}: ${GREEN}✅ Activo${NC}"
        return 0
    elif systemctl is-enabled --quiet $service 2>/dev/null; then
        echo -e "${name}: ${YELLOW}⚠️  Habilitado pero no corriendo${NC}"
        return 1
    else
        echo -e "${name}: ${RED}❌ Inactivo${NC}"
        return 2
    fi
}

# Estado de servicios
echo -e "${YELLOW}📊 Estado de Servicios:${NC}"
check_service newscrapper-ec2.timer "Timer de Scraper"
check_service newscrapper-ec2.service "Scraper Job"
check_service newscrapper-ec2-api.service "API Service"
echo ""

# Próxima ejecución del timer
if systemctl is-active --quiet newscrapper-ec2.timer 2>/dev/null; then
    echo -e "${YELLOW}⏰ Próxima Ejecución:${NC}"
    systemctl status newscrapper-ec2.timer 2>/dev/null | grep "Trigger:" || echo "  N/A"
    echo ""
fi

# Última ejecución
if systemctl list-units newscrapper-ec2.service &>/dev/null; then
    echo -e "${YELLOW}🕐 Última Ejecución:${NC}"
    systemctl status newscrapper-ec2.service 2>/dev/null | grep "Active:" || echo "  Nunca ejecutado"
    echo ""
fi

# Espacio en disco
echo -e "${YELLOW}💾 Espacio en Disco:${NC}"
df -h $HOME 2>/dev/null | tail -1 | awk '{print "  Usado: " $3 " / " $2 " (" $5 ")"}' || echo "  N/A"
echo ""

# Uso de memoria
echo -e "${YELLOW}🧠 Uso de Memoria:${NC}"
free -h 2>/dev/null | grep Mem | awk '{print "  Usado: " $3 " / " $2}' || echo "  N/A"
echo ""

# Archivos en data
if [ -d "$HOME/NewsScrapperEC2/data" ]; then
    echo -e "${YELLOW}📁 Archivos de Datos:${NC}"
    ls -lh $HOME/NewsScrapperEC2/data/*.json* 2>/dev/null | tail -5 | awk '{print "  " $9 " (" $5 ")"}' || echo "  No hay archivos"
    echo ""
fi

# Últimos logs
if [ -d "$HOME/NewsScrapperEC2/logs" ]; then
    echo -e "${YELLOW}📝 Últimos Logs (últimas 5 líneas):${NC}"
    if [ -f "$HOME/NewsScrapperEC2/logs/scraper.log" ]; then
        tail -5 $HOME/NewsScrapperEC2/logs/scraper.log 2>/dev/null | sed 's/^/  /' || echo "  No hay logs disponibles"
    else
        echo "  No hay logs disponibles"
    fi
    echo ""
fi

# Procesos Python relacionados
echo -e "${YELLOW}🐍 Procesos Python Activos:${NC}"
PROCS=$(pgrep -fa "scrape_and_summarize\|uvicorn.*api:app" 2>/dev/null || echo "")
if [ -z "$PROCS" ]; then
    echo "  Ninguno"
else
    echo "$PROCS" | sed 's/^/  /'
fi
echo ""

# Comandos útiles
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}💡 Comandos Útiles:${NC}"
echo -e "  Ver logs en tiempo real:  ${GREEN}sudo journalctl -u newscrapper-ec2 -f${NC}"
echo -e "  Ejecutar manualmente:     ${GREEN}./start_scraper.sh${NC}"
echo -e "  Reiniciar timer:          ${GREEN}sudo systemctl restart newscrapper-ec2.timer${NC}"
echo -e "  Ver estado detallado:     ${GREEN}sudo systemctl status newscrapper-ec2.timer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
