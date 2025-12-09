#!/bin/bash

# test_api.sh
# Probar los endpoints de la API

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
HOST="${API_HOST:-localhost}"
PORT="${API_PORT:-8000}"
BASE_URL="http://${HOST}:${PORT}"

# API Key (dejar vacío para testing sin autenticación)
API_KEY="${API_KEY:-}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Test API${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Función para hacer requests
make_request() {
    local endpoint=$1
    local method=${2:-GET}
    local description=$3
    
    echo -e "${YELLOW}📡 Testing: ${description}${NC}"
    echo -e "   Endpoint: ${method} ${endpoint}"
    
    if [ -n "$API_KEY" ]; then
        response=$(curl -s -X "$method" \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            "${BASE_URL}${endpoint}" 2>&1)
    else
        response=$(curl -s -X "$method" \
            -H "Content-Type: application/json" \
            "${BASE_URL}${endpoint}" 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Response:${NC}"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    else
        echo -e "${RED}❌ Error: $response${NC}"
    fi
    echo ""
}

# Test 1: Health check
make_request "/" "GET" "Root endpoint (health check)"

# Test 2: Health endpoint
make_request "/health" "GET" "Health check"

# Test 3: Latest resumen (puede fallar sin API key)
make_request "/resumen/latest" "GET" "Obtener último resumen"

# Test 4: RSS list
make_request "/rss/list" "GET" "Listar feeds RSS"

# Test 5: Resumen por fecha
FECHA=$(date +%Y-%m-%d)
make_request "/resumen/${FECHA}" "GET" "Obtener resumen de hoy (${FECHA})"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}💡 Tip: Para probar con autenticación:${NC}"
echo -e "   export API_KEY='tu-api-key'${NC}"
echo -e "   ./test_api.sh${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
