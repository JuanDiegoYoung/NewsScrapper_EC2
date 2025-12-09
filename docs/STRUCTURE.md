# 📁 Estructura del Proyecto NewsScrapperEC2

```
NewsScrapperEC2/
│
├── 📄 README.md                    # Documentación principal completa
├── 📄 QUICKSTART.md                # Guía rápida de deployment
├── 📄 CHANGELOG.md                 # Registro de cambios
├── 📄 .env.example                 # Template de configuración
├── 📄 .gitignore                   # Archivos a ignorar en git
│
├── 🔧 SCRIPTS DE DEPLOYMENT
│   ├── deploy_ec2.sh               # Deploy desde local → EC2
│   ├── setup_ec2.sh                # Setup inicial en EC2 (una vez)
│   ├── setup_systemd.sh            # Configurar servicios systemd (una vez)
│   ├── quick_update.sh             # Update rápido de código
│   ├── check_config.sh             # Verificar configuración
│   └── test_local.sh               # Testing antes de deploy
│
├── 🚀 SCRIPTS DE OPERACIÓN
│   ├── start_scraper.sh            # Ejecutar scraper manualmente
│   ├── stop_scraper.sh             # Detener todos los servicios
│   └── monitor.sh                  # Monitorear estado del sistema
│
├── 📦 config/                      # Configuración
│   ├── __init__.py
│   ├── config.py                   # Variables de configuración (S3, región, etc)
│   ├── logger_utils.py             # Sistema de logging estructurado
│   └── requirements.txt            # Dependencias Python
│
├── 🐍 src/                         # Código fuente
│   ├── __init__.py
│   │
│   ├── scraper/                    # Módulo de scraping
│   │   ├── __init__.py
│   │   ├── scrape_and_summarize.py # Scraper principal + OpenAI
│   │   └── save_bucket.py          # Guardar resultados en S3
│   │
│   └── api/                        # API FastAPI
│       ├── __init__.py
│       └── api.py                  # Endpoints REST
│
├── 📂 data/                        # Datos locales (opcional)
│   └── scraped_summaries.jsonl    # Cache local de resultados
│
└── 📂 logs/                        # Logs de ejecución
    ├── scraper.log                # Logs del scraper
    ├── scraper_error.log          # Errores del scraper
    ├── api.log                    # Logs de la API
    └── api_error.log              # Errores de la API
```

## 📊 Estadísticas del Proyecto

- **Archivos Python**: 9
- **Scripts Bash**: 9
- **Documentación**: 3 archivos MD
- **Total líneas Python**: ~564
- **Total líneas Scripts**: ~866

## 🔄 Flujo de Trabajo

### 1️⃣ Desarrollo Local
```
edit code → test_local.sh → commit
```

### 2️⃣ Primera Vez en EC2
```
deploy_ec2.sh → setup_ec2.sh → configure .env → setup_systemd.sh
```

### 3️⃣ Operación Normal
```
systemd timer → scraper runs every 6h → saves to S3 → logs
```

### 4️⃣ Actualizaciones
```
edit code → quick_update.sh → servicios se reinician
```

### 5️⃣ Monitoreo
```
monitor.sh | journalctl -u newscrapper-ec2 -f | CloudWatch
```

## 🎯 Componentes Clave

### Scraper (`scrape_and_summarize.py`)
- Fetch RSS feeds (CNBC, Reuters, Bloomberg)
- Download article HTML
- Extract text with BeautifulSoup
- Summarize with OpenAI (gpt-4o-mini)
- Save to S3 + local

### API (`api.py`)
- `GET /resumen/latest` - Último resumen
- `GET /resumen/{fecha}` - Resumen por fecha
- `GET /historico` - Todo el histórico
- `POST /scrape/run` - Forzar ejecución
- Authentication via X-API-Key header

### Systemd Services
- `newscrapper-ec2.service` - Job de scraping
- `newscrapper-ec2.timer` - Timer (cada 6h)
- `newscrapper-ec2-api.service` - API FastAPI

### Logging
- Formato JSON estructurado
- CloudWatch EMF metrics support
- Rotation automática por systemd

## 🛠️ Stack Tecnológico

- **Python 3.11+**
- **FastAPI** - API REST
- **Uvicorn** - ASGI server
- **BeautifulSoup4** - HTML parsing
- **Feedparser** - RSS parsing
- **Boto3** - AWS SDK
- **Requests** - HTTP client
- **OpenAI API** - Summarization
- **Systemd** - Service management
- **AWS S3** - Storage
- **CloudWatch** - Monitoring (opcional)

## 📝 Archivos de Configuración

### `.env`
Variables de entorno para credenciales y configuración

### `config.py`
Configuración estática (bucket, región, etc)

### `logger_utils.py`
Setup de logging con formato JSON

### `requirements.txt`
Dependencias Python del proyecto

## 🔐 Seguridad

- Credenciales en `.env` (no commiteadas)
- Soporte para IAM roles (recomendado)
- API key authentication
- Security groups en EC2
- S3 bucket policies

## 📈 Escalabilidad

- Fácil cambiar frecuencia (editar timer)
- Agregar más RSS feeds (editar lista)
- Horizontal scaling con Load Balancer
- CloudWatch para alertas
- S3 lifecycle policies para archivado

---

**Diseñado para**: Deployment directo en EC2  
**Optimizado para**: Simplicidad, performance, bajo costo  
**Alternativa a**: Docker/Kubernetes (overhead reducido)
