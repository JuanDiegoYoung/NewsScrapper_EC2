#!/bin/bash

# setup_systemd.sh
# Configurar NewsScrapperEC2 como servicio systemd con timer
# Ejecutar después de setup_ec2.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

USER=$(whoami)
WORKING_DIR="$HOME/NewsScrapperEC2"

echo -e "${GREEN}⚙️  Configurando servicio systemd...${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "$WORKING_DIR" ]; then
    echo -e "${RED}Error: Directorio $WORKING_DIR no existe${NC}"
    exit 1
fi

# 1. Crear servicio systemd
echo -e "${GREEN}📝 Creando archivo de servicio...${NC}"
sudo tee /etc/systemd/system/newscrapper-ec2.service > /dev/null << EOF
[Unit]
Description=NewsScrapperEC2 - News Scraping and Summarization Service
After=network.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$WORKING_DIR
Environment="PATH=$WORKING_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=$WORKING_DIR"
ExecStart=$WORKING_DIR/venv/bin/python src/scraper/scrape_and_summarize.py
StandardOutput=append:$WORKING_DIR/logs/scraper.log
StandardError=append:$WORKING_DIR/logs/scraper_error.log

[Install]
WantedBy=multi-user.target
EOF

# 2. Crear timer systemd (ejecutar diariamente a las 9 AM hora Uruguay)
echo -e "${GREEN}⏰ Creando timer...${NC}"
sudo tee /etc/systemd/system/newscrapper-ec2.timer > /dev/null << 'EOF'
[Unit]
Description=NewsScrapperEC2 Timer - Run daily at 9 AM Uruguay Time (12 PM UTC)
Requires=newscrapper-ec2.service

[Timer]
OnCalendar=*-*-* 12:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 3. Crear servicio para la API (opcional)
echo -e "${GREEN}🌐 Creando servicio API...${NC}"
sudo tee /etc/systemd/system/newscrapper-ec2-api.service > /dev/null << EOF
[Unit]
Description=NewsScrapperEC2 API - FastAPI Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKING_DIR
Environment="PATH=$WORKING_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=$WORKING_DIR"
ExecStart=$WORKING_DIR/venv/bin/uvicorn src.api.api:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10
StandardOutput=append:$WORKING_DIR/logs/api.log
StandardError=append:$WORKING_DIR/logs/api_error.log

[Install]
WantedBy=multi-user.target
EOF

# 4. Recargar systemd
echo -e "${GREEN}🔄 Recargando systemd...${NC}"
sudo systemctl daemon-reload

# 5. Habilitar servicios
echo -e "${GREEN}✅ Habilitando servicios...${NC}"
sudo systemctl enable newscrapper-ec2.timer
# No habilitamos la API por defecto, el usuario decide si la necesita

echo ""
echo -e "${GREEN}✅ Configuración de systemd completada!${NC}"
echo ""
echo -e "${YELLOW}Comandos útiles:${NC}"
echo ""
echo -e "${GREEN}Scraper (timer cada 6 horas):${NC}"
echo "  Iniciar timer:     sudo systemctl start newscrapper-ec2.timer"
echo "  Ver estado:        sudo systemctl status newscrapper-ec2.timer"
echo "  Ver logs:          sudo journalctl -u newscrapper-ec2 -f"
echo "  Ejecutar ahora:    sudo systemctl start newscrapper-ec2"
echo "  Detener:           sudo systemctl stop newscrapper-ec2.timer"
echo ""
echo -e "${GREEN}API (opcional):${NC}"
echo "  Iniciar API:       sudo systemctl start newscrapper-ec2-api"
echo "  Habilitar autostart: sudo systemctl enable newscrapper-ec2-api"
echo "  Ver logs:          sudo journalctl -u newscrapper-ec2-api -f"
echo "  Detener:           sudo systemctl stop newscrapper-ec2-api"
echo ""
echo -e "${YELLOW}Para iniciar el scraper automático:${NC}"
echo -e "${GREEN}sudo systemctl start newscrapper-ec2.timer${NC}"
echo ""
