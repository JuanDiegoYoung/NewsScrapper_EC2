# NewsScrapperEC2

Sistema de scraping y análisis de noticias financieras optimizado para deployment directo en EC2 (sin Docker).

## 🎯 Características

- **Scraping automático** de noticias financieras desde múltiples fuentes RSS
- **Resumen con OpenAI** para análisis conciso de artículos
- **Almacenamiento en S3** para histórico y análisis
- **API FastAPI** para acceso programático a los datos
- **Servicio systemd** para ejecución automatizada cada 6 horas
- **Logs estructurados** en formato JSON para CloudWatch
- **Deployment simplificado** con scripts automatizados

## 📁 Estructura del Proyecto

```
NewsScrapperEC2/
├── src/                      # Código fuente
│   ├── scraper/              # Lógica de scraping
│   │   ├── scrape_and_summarize.py
│   │   └── save_bucket.py
│   └── api/                  # API FastAPI
│       └── api.py
├── config/                   # Configuración
│   ├── config.py
│   ├── logger_utils.py
│   └── requirements.txt
├── data/                     # Datos locales (opcional)
├── logs/                     # Logs del scraper y API
├── deploy_ec2.sh             # Script de deployment
├── setup_ec2.sh              # Setup inicial en EC2
├── setup_systemd.sh          # Configurar servicios
├── start_scraper.sh          # Ejecutar manualmente
├── stop_scraper.sh           # Detener servicios
├── monitor.sh                # Monitorear estado
└── quick_update.sh           # Actualización rápida
```

## 🚀 Quick Start

### 1. Deployment a EC2

Desde tu máquina local:

```bash
# Hacer ejecutables los scripts
chmod +x *.sh

# Deployar a EC2
./deploy_ec2.sh ubuntu ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
```

### 2. Setup en EC2

Conéctate al servidor:

```bash
ssh -i "tu-clave.pem" ubuntu@ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
cd ~/NewsScrapperEC2
```

Ejecuta el setup:

```bash
./setup_ec2.sh
```

### 3. Configurar Credenciales

Edita el archivo `.env`:

```bash
nano .env
```

Completa las variables:

```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AWS_REGION=us-east-1
BUCKET=jd-finance-news
PREFIX=runs/

# OpenAI Configuration
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Email (opcional)
EMAIL_SENDER=your_email@example.com
EMAIL_PASSWORD=your_app_password
EMAIL_RECIPIENTS=recipient@example.com

# Scraper Configuration
SCRAPER_INTERVAL_HOURS=6
MAX_ARTICLES_PER_RUN=50
```

También configura AWS CLI:

```bash
aws configure
```

### 4. Probar Manualmente

```bash
./start_scraper.sh
```

### 5. Configurar Servicio Automático

```bash
./setup_systemd.sh
sudo systemctl start newscrapper-ec2.timer
```

## 📊 Monitoreo

### Ver Estado

```bash
# Ejecutar script de monitoreo
./monitor.sh

# Ver estado de servicios
sudo systemctl status newscrapper-ec2.timer
sudo systemctl status newscrapper-ec2-api
```

### Ver Logs

```bash
# Logs en tiempo real
sudo journalctl -u newscrapper-ec2 -f

# Logs archivados
tail -f logs/scraper.log
tail -f logs/scraper_error.log
```

## 🔄 Actualizar Código

### Actualización Completa

```bash
# Desde tu máquina local
./deploy_ec2.sh ubuntu ec2-host.amazonaws.com
```

### Actualización Rápida (solo código Python)

```bash
# Desde tu máquina local
./quick_update.sh ubuntu ec2-host.amazonaws.com
```

## 🌐 API

### Habilitar API

```bash
sudo systemctl enable newscrapper-ec2-api
sudo systemctl start newscrapper-ec2-api
```

### Endpoints Disponibles

```bash
# Health check
GET /health

# Resumen más reciente
GET /resumen/latest
Header: X-API-Key: tu-api-key

# Resumen de fecha específica
GET /resumen/2025-12-09
Header: X-API-Key: tu-api-key

# Histórico completo
GET /historico
Header: X-API-Key: tu-api-key

# Listar feeds RSS
GET /rss/list
Header: X-API-Key: tu-api-key

# Forzar scraping
POST /scrape/run
Header: X-API-Key: tu-api-key
```

## ⚙️ Configuración Avanzada

### Cambiar Frecuencia de Scraping

```bash
sudo nano /etc/systemd/system/newscrapper-ec2.timer
```

Cambia `OnUnitActiveSec=6h` a:
- `1h` = cada hora
- `3h` = cada 3 horas
- `12h` = cada 12 horas
- `1d` = diario

Luego:

```bash
sudo systemctl daemon-reload
sudo systemctl restart newscrapper-ec2.timer
```

### Configurar Nginx como Reverse Proxy

```bash
sudo apt-get install -y nginx

sudo nano /etc/nginx/sites-available/newscrapper
```

Agregar:

```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Activar:

```bash
sudo ln -s /etc/nginx/sites-available/newscrapper /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 🔒 Seguridad

### Usar IAM Role (Recomendado)

En lugar de usar Access Keys en `.env`:

1. Crea un IAM Role con permisos para S3, Secrets Manager y CloudWatch
2. Asigna el role a la instancia EC2
3. Elimina `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` del `.env`

### Security Group

Asegúrate de que tu Security Group permite:
- SSH (22) desde tu IP
- HTTP (80) si usas Nginx
- Puerto 8000 si accedes directamente a la API

## 🆘 Troubleshooting

### El scraper no se ejecuta

```bash
# Ver errores
sudo journalctl -u newscrapper-ec2 -n 50

# Probar manualmente
cd ~/NewsScrapperEC2
source venv/bin/activate
python src/scraper/scrape_and_summarize.py
```

### Error de credenciales AWS

```bash
# Verificar configuración
aws sts get-caller-identity

# Verificar variables
cat .env | grep AWS
```

### Logs no se generan

```bash
# Verificar permisos
ls -la ~/NewsScrapperEC2/logs/

# Crear si no existe
mkdir -p ~/NewsScrapperEC2/logs
chmod 755 ~/NewsScrapperEC2/logs
```

## 📞 Comandos de Referencia Rápida

```bash
# Deployment
./deploy_ec2.sh ubuntu ec2-host.amazonaws.com

# Setup inicial (una vez)
./setup_ec2.sh
./setup_systemd.sh

# Control de servicios
sudo systemctl start newscrapper-ec2.timer
sudo systemctl stop newscrapper-ec2.timer
sudo systemctl restart newscrapper-ec2.timer
sudo systemctl status newscrapper-ec2.timer

# Ejecución manual
./start_scraper.sh

# Monitoreo
./monitor.sh
sudo journalctl -u newscrapper-ec2 -f

# Actualización
./quick_update.sh ubuntu ec2-host.amazonaws.com
```

## 📈 Diferencias con la Versión Docker

Esta versión está optimizada para EC2:

- ✅ **No requiere Docker** - deployment más simple
- ✅ **Systemd nativo** - integración con el sistema operativo
- ✅ **Mejor performance** - sin overhead de containers
- ✅ **Logs directos** - más fácil debugging
- ✅ **Updates más rápidos** - sin rebuild de imágenes
- ✅ **Menor uso de recursos** - ideal para instancias pequeñas

## 📚 Recursos

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Systemd Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [OpenAI API](https://platform.openai.com/docs/api-reference)

## 📝 Notas

- El scraper se ejecuta cada 6 horas por defecto
- Los resultados se guardan en S3 con particionado por fecha
- Los logs se rotan automáticamente por systemd
- La API requiere autenticación via X-API-Key header

---

**Versión**: 2.0  
**Última actualización**: Diciembre 2025  
**Autor**: Juan Diego Young
