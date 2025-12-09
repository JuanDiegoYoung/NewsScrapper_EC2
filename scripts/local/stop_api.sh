#!/bin/bash

# stop_api.sh
# Detener el servidor FastAPI

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}⏹️  Deteniendo servidor FastAPI...${NC}"

# Buscar el proceso de uvicorn
PID=$(ps aux | grep '[u]vicorn api:app' | awk '{print $2}')

if [ -z "$PID" ]; then
    echo -e "${YELLOW}⚠️  No se encontró el servidor corriendo${NC}"
    exit 0
fi

# Detener el proceso
kill $PID

# Esperar un momento
sleep 2

# Verificar que se detuvo
if ps -p $PID > /dev/null 2>&1; then
    echo -e "${RED}❌ El proceso no se detuvo, forzando...${NC}"
    kill -9 $PID
fi

echo -e "${GREEN}✅ Servidor detenido${NC}"
