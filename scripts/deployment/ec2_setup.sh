#!/bin/bash

# ec2_setup.sh
# Script completo para crear y configurar instancia EC2 con IP elástica

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   NewsScrapperEC2 - Configuración EC2${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ Error: AWS CLI no está instalado${NC}"
    exit 1
fi

# Verificar credenciales
echo -e "${YELLOW}🔑 Verificando credenciales AWS...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ Error: Credenciales AWS inválidas${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Credenciales válidas${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${BLUE}   Cuenta: ${ACCOUNT_ID}${NC}"
echo ""

# Configuración
echo -e "${YELLOW}📋 Configuración de la instancia:${NC}"
read -p "Nombre de la instancia [newscrapper-ec2]: " INSTANCE_NAME
INSTANCE_NAME=${INSTANCE_NAME:-newscrapper-ec2}

read -p "Tipo de instancia [t3.micro]: " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.micro}

read -p "Región [us-east-1]: " REGION
REGION=${REGION:-us-east-1}

read -p "Key pair name (debe existir) [juan-keypair]: " KEY_NAME
KEY_NAME=${KEY_NAME:-juan-keypair}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Resumen de configuración:${NC}"
echo -e "  Nombre: ${INSTANCE_NAME}"
echo -e "  Tipo: ${INSTANCE_TYPE}"
echo -e "  Región: ${REGION}"
echo -e "  Key: ${KEY_NAME}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "¿Continuar? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Cancelado"
    exit 0
fi

# Obtener AMI de Ubuntu más reciente
echo ""
echo -e "${YELLOW}🔍 Buscando AMI de Ubuntu 22.04...${NC}"
AMI_ID=$(aws ec2 describe-images \
    --region $REGION \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

echo -e "${GREEN}✅ AMI seleccionado: ${AMI_ID}${NC}"

# Crear Security Group
echo ""
echo -e "${YELLOW}🔐 Creando Security Group...${NC}"
SG_NAME="${INSTANCE_NAME}-sg"
SG_ID=$(aws ec2 create-security-group \
    --region $REGION \
    --group-name $SG_NAME \
    --description "Security group for NewsScrapperEC2" \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --region $REGION \
    --group-names $SG_NAME \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

echo -e "${GREEN}✅ Security Group: ${SG_ID}${NC}"

# Configurar reglas del Security Group
echo -e "${YELLOW}🔓 Configurando reglas de firewall...${NC}"

# SSH (22)
aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "  Puerto 22 ya configurado"

# API (8000)
aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --protocol tcp \
    --port 8000 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "  Puerto 8000 ya configurado"

# HTTP (80) - para futuro nginx
aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "  Puerto 80 ya configurado"

# HTTPS (443) - para futuro nginx con SSL
aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "  Puerto 443 ya configurado"

echo -e "${GREEN}✅ Reglas configuradas${NC}"

# Crear instancia EC2
echo ""
echo -e "${YELLOW}🚀 Creando instancia EC2...${NC}"

INSTANCE_ID=$(aws ec2 run-instances \
    --region $REGION \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}✅ Instancia creada: ${INSTANCE_ID}${NC}"

# Esperar a que la instancia esté corriendo
echo ""
echo -e "${YELLOW}⏳ Esperando a que la instancia esté lista...${NC}"
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID
echo -e "${GREEN}✅ Instancia corriendo${NC}"

# Obtener IP pública temporal
PUBLIC_IP=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${BLUE}   IP temporal: ${PUBLIC_IP}${NC}"

# Asignar IP elástica
echo ""
echo -e "${YELLOW}🌐 Asignando IP elástica...${NC}"

ALLOCATION_ID=$(aws ec2 allocate-address \
    --region $REGION \
    --domain vpc \
    --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$INSTANCE_NAME-eip}]" \
    --query 'AllocationId' \
    --output text)

echo -e "${GREEN}✅ IP elástica asignada: ${ALLOCATION_ID}${NC}"

# Asociar IP elástica a la instancia
aws ec2 associate-address \
    --region $REGION \
    --instance-id $INSTANCE_ID \
    --allocation-id $ALLOCATION_ID

ELASTIC_IP=$(aws ec2 describe-addresses \
    --region $REGION \
    --allocation-ids $ALLOCATION_ID \
    --query 'Addresses[0].PublicIp' \
    --output text)

echo -e "${GREEN}✅ IP elástica asociada: ${ELASTIC_IP}${NC}"

# Guardar información
cat > deployment/ec2_info.txt << EOF
# Información de la instancia EC2
INSTANCE_ID=${INSTANCE_ID}
INSTANCE_NAME=${INSTANCE_NAME}
ELASTIC_IP=${ELASTIC_IP}
ALLOCATION_ID=${ALLOCATION_ID}
REGION=${REGION}
KEY_NAME=${KEY_NAME}
SECURITY_GROUP=${SG_ID}
AMI_ID=${AMI_ID}
CREATED=$(date)
EOF

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Instancia EC2 creada exitosamente!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📊 Información de la instancia:${NC}"
echo -e "  ID: ${INSTANCE_ID}"
echo -e "  IP Elástica: ${ELASTIC_IP}"
echo -e "  Región: ${REGION}"
echo -e "  Tipo: ${INSTANCE_TYPE}"
echo ""
echo -e "${YELLOW}📝 Próximos pasos:${NC}"
echo ""
echo -e "${GREEN}1. Conectarse por SSH:${NC}"
echo -e "   ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${ELASTIC_IP}"
echo ""
echo -e "${GREEN}2. Desplegar la aplicación:${NC}"
echo -e "   ./deploy ${ELASTIC_IP}"
echo ""
echo -e "${GREEN}3. Configurar DNS (opcional):${NC}"
echo -e "   Apuntar tu dominio a: ${ELASTIC_IP}"
echo ""
echo -e "${YELLOW}💡 La información se guardó en: deployment/ec2_info.txt${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
