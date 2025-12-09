#!/bin/bash

# test_local.sh
# Script para probar el scraper localmente antes de deployar

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🧪 Testing NewsScrapperEC2 Localmente${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "src/scraper/scrape_and_summarize.py" ]; then
    echo -e "${RED}Error: Ejecuta este script desde el directorio raíz del proyecto${NC}"
    exit 1
fi

# Verificar Python
echo -e "${YELLOW}1. Verificando Python...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python3 no encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python encontrado: $(python3 --version)${NC}"
echo ""

# Verificar entorno virtual
echo -e "${YELLOW}2. Configurando entorno virtual...${NC}"
if [ ! -d "venv" ]; then
    echo "Creando entorno virtual..."
    python3 -m venv venv
fi
source venv/bin/activate
echo -e "${GREEN}✓ Entorno virtual activado${NC}"
echo ""

# Instalar dependencias
echo -e "${YELLOW}3. Instalando dependencias...${NC}"
pip install -q --upgrade pip
pip install -q -r config/requirements.txt
echo -e "${GREEN}✓ Dependencias instaladas${NC}"
echo ""

# Verificar .env
echo -e "${YELLOW}4. Verificando configuración...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado, creando desde .env.example${NC}"
    cp .env.example .env
    echo -e "${RED}⚠️  IMPORTANTE: Edita .env con tus credenciales antes de continuar${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Archivo .env encontrado${NC}"
echo ""

# Verificar credenciales básicas
echo -e "${YELLOW}5. Verificando credenciales...${NC}"
source .env
if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "your_openai_key_here" ]; then
    echo -e "${RED}⚠️  OPENAI_API_KEY no configurada en .env${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Credenciales básicas configuradas${NC}"
echo ""

# Crear directorios
echo -e "${YELLOW}6. Creando directorios...${NC}"
mkdir -p data logs
echo -e "${GREEN}✓ Directorios creados${NC}"
echo ""

# Test de importación
echo -e "${YELLOW}7. Probando imports...${NC}"
export PYTHONPATH=$PWD
python3 -c "
try:
    from src.scraper.scrape_and_summarize import run_once
    from src.scraper.save_bucket import upload_results_to_s3
    from config.logger_utils import get_logger
    print('✅ Todos los imports OK')
except Exception as e:
    print(f'❌ Error en imports: {e}')
    exit(1)
"
echo ""

# Ejecutar scraper (modo test - solo 2 artículos)
echo -e "${YELLOW}8. Ejecutando scraper (modo test - 2 artículos)...${NC}"
echo -e "${YELLOW}   Esto puede tomar 1-2 minutos...${NC}"
echo ""

python3 << 'PYEOF'
import sys
from pathlib import Path
sys.path.append(str(Path.cwd()))
from src.scraper.scrape_and_summarize import run_once

try:
    results = run_once(top_n=2)
    print(f"\n✅ Test exitoso: {len(results)} artículos procesados")
    for i, r in enumerate(results, 1):
        print(f"\n{i}. {r['title'][:80]}")
        print(f"   URL: {r['link']}")
        print(f"   Resumen: {r['summary'][:150]}...")
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYEOF

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Todos los tests pasaron!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Siguiente paso:${NC}"
echo -e "  ${GREEN}./deploy_ec2.sh ubuntu ec2-host.amazonaws.com${NC}"
echo ""
