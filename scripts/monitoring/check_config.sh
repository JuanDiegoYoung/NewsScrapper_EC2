#!/bin/bash

# check_config.sh
# Script para verificar que toda la configuración esté correcta antes de deployar

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${GREEN}🔍 Verificando configuración de NewsScrapperEC2${NC}"
echo ""

# Verificar archivo .env
echo -e "${YELLOW}1. Verificando archivo .env...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}   ✗ Archivo .env no encontrado${NC}"
    echo -e "${YELLOW}   → Copia .env.example a .env y completa las credenciales${NC}"
    ((ERRORS++))
else
    source .env
    echo -e "${GREEN}   ✓ Archivo .env existe${NC}"
    
    # Verificar variables críticas
    if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "your_openai_key_here" ]; then
        echo -e "${RED}   ✗ OPENAI_API_KEY no configurada${NC}"
        ((ERRORS++))
    else
        echo -e "${GREEN}   ✓ OPENAI_API_KEY configurada${NC}"
    fi
    
    if [ -z "$BUCKET" ] || [ "$BUCKET" = "your-bucket-here" ]; then
        echo -e "${YELLOW}   ⚠ BUCKET no configurado (requerido para S3)${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}   ✓ BUCKET configurado: $BUCKET${NC}"
    fi
    
    if [ -z "$AWS_REGION" ]; then
        echo -e "${YELLOW}   ⚠ AWS_REGION no configurado, usando us-east-1${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}   ✓ AWS_REGION configurado: $AWS_REGION${NC}"
    fi
fi
echo ""

# Verificar estructura de directorios
echo -e "${YELLOW}2. Verificando estructura de directorios...${NC}"
REQUIRED_DIRS=("src/scraper" "src/api" "config" "data" "logs")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}   ✓ $dir existe${NC}"
    else
        echo -e "${RED}   ✗ $dir no existe${NC}"
        ((ERRORS++))
    fi
done
echo ""

# Verificar archivos Python
echo -e "${YELLOW}3. Verificando archivos Python...${NC}"
REQUIRED_FILES=(
    "src/scraper/scrape_and_summarize.py"
    "src/scraper/save_bucket.py"
    "src/api/api.py"
    "config/config.py"
    "config/logger_utils.py"
)
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}   ✓ $file existe${NC}"
    else
        echo -e "${RED}   ✗ $file no existe${NC}"
        ((ERRORS++))
    fi
done
echo ""

# Verificar scripts
echo -e "${YELLOW}4. Verificando scripts de deployment...${NC}"
REQUIRED_SCRIPTS=(
    "deploy_ec2.sh"
    "setup_ec2.sh"
    "setup_systemd.sh"
    "start_scraper.sh"
    "stop_scraper.sh"
    "monitor.sh"
)
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}   ✓ $script existe y es ejecutable${NC}"
        else
            echo -e "${YELLOW}   ⚠ $script existe pero no es ejecutable${NC}"
            echo -e "${YELLOW}     → Ejecuta: chmod +x $script${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}   ✗ $script no existe${NC}"
        ((ERRORS++))
    fi
done
echo ""

# Verificar requirements.txt
echo -e "${YELLOW}5. Verificando dependencias...${NC}"
if [ -f "config/requirements.txt" ]; then
    echo -e "${GREEN}   ✓ requirements.txt existe${NC}"
    DEPS=("boto3" "fastapi" "uvicorn" "requests" "beautifulsoup4" "feedparser")
    for dep in "${DEPS[@]}"; do
        if grep -q "$dep" config/requirements.txt; then
            echo -e "${GREEN}   ✓ $dep en requirements.txt${NC}"
        else
            echo -e "${RED}   ✗ $dep no encontrado en requirements.txt${NC}"
            ((ERRORS++))
        fi
    done
else
    echo -e "${RED}   ✗ requirements.txt no encontrado${NC}"
    ((ERRORS++))
fi
echo ""

# Verificar Python (si estamos en el servidor)
echo -e "${YELLOW}6. Verificando Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}   ✓ Python instalado: $PYTHON_VERSION${NC}"
    
    # Verificar versión mínima (3.8)
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    if [ "$PYTHON_MINOR" -lt 8 ]; then
        echo -e "${RED}   ✗ Python 3.$PYTHON_MINOR es muy antiguo, se requiere 3.8+${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}   ⚠ Python3 no encontrado (normal si estás en local)${NC}"
    ((WARNINGS++))
fi
echo ""

# Verificar AWS CLI (si está disponible)
echo -e "${YELLOW}7. Verificando AWS CLI...${NC}"
if command -v aws &> /dev/null; then
    echo -e "${GREEN}   ✓ AWS CLI instalado${NC}"
    if aws sts get-caller-identity &> /dev/null; then
        echo -e "${GREEN}   ✓ AWS credentials configuradas${NC}"
    else
        echo -e "${YELLOW}   ⚠ AWS credentials no configuradas o inválidas${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}   ⚠ AWS CLI no encontrado (instalar en EC2)${NC}"
    ((WARNINGS++))
fi
echo ""

# Resumen
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las verificaciones pasaron!${NC}"
    echo -e "${GREEN}   Listo para deployar con: ./deploy_ec2.sh${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS advertencias encontradas${NC}"
    echo -e "${YELLOW}   Revisa las advertencias pero puedes continuar${NC}"
else
    echo -e "${RED}❌ $ERRORS errores encontrados${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}   $WARNINGS advertencias adicionales${NC}"
    fi
    echo -e "${RED}   Corrige los errores antes de deployar${NC}"
fi
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

exit $ERRORS
