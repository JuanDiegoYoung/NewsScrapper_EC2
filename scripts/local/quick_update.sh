#!/bin/bash

# quick_update.sh
# Script rápido para actualizar solo el código Python sin reinstalar dependencias
# Útil para cambios menores

set -e

if [ "$#" -ne 2 ]; then
    echo "Error: Se requieren 2 argumentos"
    echo "Uso: $0 <EC2_USER> <EC2_HOST>"
    exit 1
fi

EC2_USER=$1
EC2_HOST=$2

echo "🚀 Actualizando código en EC2..."

# Crear tarball solo del código fuente
tar -czf update.tar.gz \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    src/ config/config.py config/logger_utils.py

# Copiar y desplegar
scp update.tar.gz ${EC2_USER}@${EC2_HOST}:~/

ssh ${EC2_USER}@${EC2_HOST} << 'ENDSSH'
cd ~/NewsScrapperEC2
tar -xzf ~/update.tar.gz
rm ~/update.tar.gz

# Reiniciar servicios si están corriendo
if sudo systemctl is-active --quiet newscrapper-ec2.timer; then
    sudo systemctl restart newscrapper-ec2.timer
    echo "✅ Timer reiniciado"
fi

if sudo systemctl is-active --quiet newscrapper-ec2-api.service; then
    sudo systemctl restart newscrapper-ec2-api.service
    echo "✅ API reiniciada"
fi
ENDSSH

rm update.tar.gz

echo "✅ Actualización completada!"
