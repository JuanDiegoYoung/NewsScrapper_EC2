# NewsScrapperEC2 - Guía Rápida de Deployment

## 📋 Checklist Pre-Deployment

### En AWS Console:
- [ ] Instancia EC2 creada (Ubuntu 22.04 LTS, t3.medium o superior)
- [ ] Security Group configurado (SSH desde tu IP)
- [ ] Par de claves .pem descargado
- [ ] IAM Role creado con permisos para S3, Secrets Manager (opcional)
- [ ] Bucket S3 creado (ej: `jd-finance-news`)

### En tu máquina local:
- [ ] OpenAI API Key disponible
- [ ] AWS credentials configuradas
- [ ] SSH configurado a la instancia EC2

## 🚀 Deployment en 5 Pasos

### Paso 1: Deployment Local → EC2
```bash
cd /ruta/a/NewsScrapperEC2
./deploy_ec2.sh ubuntu ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
```

### Paso 2: Setup en EC2
```bash
ssh -i "tu-clave.pem" ubuntu@ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
cd ~/NewsScrapperEC2
./setup_ec2.sh
```
⏱️ Tiempo: ~5-10 minutos

### Paso 3: Configurar Credenciales
```bash
nano .env
```

Completa:
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
OPENAI_API_KEY=sk-...
BUCKET=jd-finance-news
```

Configura AWS CLI:
```bash
aws configure
```

### Paso 4: Test Manual
```bash
./start_scraper.sh
```
✅ Verifica que se scrapen artículos exitosamente

### Paso 5: Activar Servicio Automático
```bash
./setup_systemd.sh
sudo systemctl start newscrapper-ec2.timer
```

## ✅ Verificación Post-Deployment

```bash
# Estado del servicio
sudo systemctl status newscrapper-ec2.timer

# Monitoreo completo
./monitor.sh

# Ver logs en tiempo real
sudo journalctl -u newscrapper-ec2 -f
```

## 📊 Comandos Esenciales

```bash
# Ver próxima ejecución
systemctl list-timers newscrapper-ec2.timer

# Ejecutar manualmente
sudo systemctl start newscrapper-ec2

# Reiniciar timer
sudo systemctl restart newscrapper-ec2.timer

# Ver últimos logs
sudo journalctl -u newscrapper-ec2 -n 50

# Estado del sistema
./monitor.sh
```

## 🔄 Workflow de Actualización

```bash
# Cambios menores (solo código)
./quick_update.sh ubuntu ec2-host.amazonaws.com

# Cambios mayores (con dependencias)
./deploy_ec2.sh ubuntu ec2-host.amazonaws.com
# En EC2: pip install -r config/requirements.txt
```

## 🐛 Troubleshooting Rápido

### Scraper no ejecuta
```bash
# Ver errores
sudo journalctl -u newscrapper-ec2 -n 50 --no-pager

# Test manual
cd ~/NewsScrapperEC2
source venv/bin/activate
export PYTHONPATH=$PWD
python src/scraper/scrape_and_summarize.py
```

### Error de AWS credentials
```bash
# Verificar
aws sts get-caller-identity

# Reconfigurar
aws configure
```

### Error de OpenAI
```bash
# Verificar key
cat .env | grep OPENAI

# Test
python -c "import os; os.environ['OPENAI_API_KEY']='tu-key'; import openai"
```

## 🌐 Habilitar API (Opcional)

```bash
# Iniciar API
sudo systemctl enable newscrapper-ec2-api
sudo systemctl start newscrapper-ec2-api

# Verificar
curl http://localhost:8000/health

# Ver logs
sudo journalctl -u newscrapper-ec2-api -f
```

## 📈 Métricas Clave

Después del primer scraping exitoso, deberías ver:
- ✅ Archivo en S3: `s3://jd-finance-news/runs/dt=YYYY-MM-DD/run=xxx.jsonl`
- ✅ Logs en: `~/NewsScrapperEC2/logs/scraper.log`
- ✅ Timer activo: `sudo systemctl is-active newscrapper-ec2.timer` → `active`

## 💡 Tips de Producción

1. **Usa IAM Role** en lugar de Access Keys
2. **Configura CloudWatch** para alertas
3. **Backup logs** regularmente
4. **Revisa logs** después de cada ejecución
5. **Monitorea S3** para verificar uploads
6. **Actualiza dependencias** mensualmente

## 📞 Contacto y Soporte

Si algo falla:
1. Revisa los logs: `sudo journalctl -u newscrapper-ec2 -n 100`
2. Ejecuta: `./monitor.sh`
3. Verifica: `./start_scraper.sh` manualmente
4. Chequea el README.md completo

---

**Setup time**: ~20 minutos  
**Primera ejecución**: ~2-3 minutos  
**Ejecución recurrente**: Cada 6 horas  
**Costo aproximado EC2**: ~$30-50/mes (t3.medium)
