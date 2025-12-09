#!/bin/bash

# setup_ec2.sh
# Script de instalación inicial en EC2
# Ejecutar este script UNA VEZ después del primer deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🛠️  Configurando NewsScrapperEC2 en EC2...${NC}"
echo ""

# 1. Actualizar sistema
echo -e "${GREEN}📦 Actualizando sistema...${NC}"
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Instalar Python 3.11 si no existe
echo -e "${GREEN}🐍 Verificando Python...${NC}"
if ! command -v python3.11 &> /dev/null; then
    echo "Instalando Python 3.11..."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update -y
    sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
else
    echo "Python 3.11 ya está instalado"
fi

# 3. Instalar dependencias del sistema
echo -e "${GREEN}📚 Instalando dependencias del sistema...${NC}"
sudo apt-get install -y \
    python3-pip \
    git \
    curl \
    wget \
    vim \
    htop \
    unzip \
    awscli

# 4. Crear entorno virtual
echo -e "${GREEN}🔧 Creando entorno virtual...${NC}"
cd ~/NewsScrapperEC2
python3.11 -m venv venv

# 5. Activar entorno e instalar dependencias Python
echo -e "${GREEN}📥 Instalando dependencias Python...${NC}"
source venv/bin/activate
pip install --upgrade pip
pip install -r config/requirements.txt

# 6. Crear directorio de datos
echo -e "${GREEN}📁 Creando directorios...${NC}"
mkdir -p data
mkdir -p logs

# 7. Crear archivo .env de ejemplo si no existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Creando archivo .env de ejemplo...${NC}"
    cat > .env << 'EOF'
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_REGION=us-east-1
BUCKET=jd-finance-news
PREFIX=runs/

# OpenAI Configuration
OPENAI_API_KEY=your_openai_key_here

# Email Configuration (opcional)
EMAIL_SENDER=your_email@example.com
EMAIL_PASSWORD=your_app_password
EMAIL_RECIPIENTS=recipient@example.com

# Scraper Configuration
SCRAPER_INTERVAL_HOURS=6
MAX_ARTICLES_PER_RUN=50

# API Configuration (si usas la API)
API_PORT=8000
API_HOST=0.0.0.0
SECRET_NAME=newscrapper-api-secret
EOF
    echo -e "${RED}⚠️  IMPORTANTE: Edita el archivo .env con tus credenciales reales${NC}"
fi

# 8. Configurar AWS CLI
echo -e "${GREEN}☁️  Configurando AWS CLI...${NC}"
if [ ! -f ~/.aws/credentials ]; then
    echo -e "${YELLOW}Ejecuta 'aws configure' manualmente con tus credenciales${NC}"
fi

# 9. Test rápido
echo -e "${GREEN}🧪 Verificando instalación...${NC}"
source venv/bin/activate
python -c "import requests, bs4, boto3; print('✅ Dependencias principales OK')"

echo ""
echo -e "${GREEN}✅ Setup completado!${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo -e "1. Editar .env con tus credenciales: ${GREEN}nano .env${NC}"
echo -e "2. Configurar AWS CLI: ${GREEN}aws configure${NC}"
echo -e "3. Probar scraper manualmente: ${GREEN}./start_scraper.sh${NC}"
echo -e "4. Configurar servicio systemd: ${GREEN}./setup_systemd.sh${NC}"
echo ""
