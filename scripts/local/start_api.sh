#!/bin/bash

# start_api.sh
# Iniciar el servidor FastAPI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Iniciar API${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar que existe el entorno virtual
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Error: No existe el entorno virtual${NC}"
    echo -e "${YELLOW}Ejecuta: python3 -m venv venv && source venv/bin/activate && pip install -r config/requirements.txt${NC}"
    exit 1
fi

# Activar entorno virtual
echo -e "${YELLOW}🔧 Activando entorno virtual...${NC}"
source venv/bin/activate

# Cargar variables de entorno
if [ -f ".env" ]; then
    echo -e "${YELLOW}🔑 Cargando variables de entorno...${NC}"
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}⚠️  Advertencia: No se encontró archivo .env${NC}"
fi

# Configurar puerto y host
PORT="${API_PORT:-8000}"
HOST="${API_HOST:-0.0.0.0}"

echo ""
echo -e "${GREEN}🚀 Iniciando servidor FastAPI...${NC}"
echo -e "${YELLOW}   Host: ${HOST}${NC}"
echo -e "${YELLOW}   Puerto: ${PORT}${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ API disponible en: http://${HOST}:${PORT}${NC}"
echo -e "${GREEN}📚 Documentación: http://${HOST}:${PORT}/docs${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Presiona Ctrl+C para detener el servidor${NC}"
echo ""

# Iniciar uvicorn
cd src/api
python -m uvicorn api:app --host "$HOST" --port "$PORT" --reload
