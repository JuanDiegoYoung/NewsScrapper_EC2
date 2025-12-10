# NewsScrapperEC2

Scraper de noticias financieras con resumen automático usando OpenAI y almacenamiento en S3.

## 🌐 API en Producción

La API está desplegada y disponible públicamente en:

**Base URL**: `http://98.87.133.84:8000`

### Acceso Rápido

- **Documentación Swagger**: http://98.87.133.84:8000/docs
- **Documentación ReDoc**: http://98.87.133.84:8000/redoc
- **Health Check**: http://98.87.133.84:8000/health

### Credenciales de Acceso

Para endpoints protegidos, usa el header:
```bash
X-API-Key: api-newscrapper-key01
```

### Ejemplo de Uso

```bash
# Obtener últimas noticias
curl -H "X-API-Key: api-newscrapper-key01" http://98.87.133.84:8000/resumen/latest

# Health check (público)
curl http://98.87.133.84:8000/health
```

Ver [Guía de Usuario](#-guía-de-usuario) más abajo para ejemplos completos.

## 📁 Estructura del Proyecto

```
NewsScrapperEC2/
├── README.md                    # Este archivo
├── .env                         # Variables de entorno (no commitear)
├── .gitignore                   # Archivos ignorados por git
│
├── src/                         # Código fuente
│   ├── scraper/                 # Lógica del scraper
│   │   ├── scrape_and_summarize.py
│   │   └── save_bucket.py
│   └── api/                     # API REST con FastAPI
│       └── api.py
│
├── config/                      # Configuración
│   ├── config.py
│   ├── logger_utils.py
│   └── requirements.txt
│
├── scripts/                     # Scripts de utilidad
│   ├── local/                   # Scripts para desarrollo local
│   │   ├── start_api.sh
│   │   ├── stop_api.sh
│   │   ├── start_scraper.sh
│   │   ├── start_service_mac.sh
│   │   └── status_service_mac.sh
│   ├── deployment/              # Scripts de deployment
│   │   ├── deploy_ec2.sh
│   │   ├── setup_ec2.sh
│   │   └── setup_systemd.sh
│   └── monitoring/              # Scripts de monitoreo
│       ├── monitor.sh
│       ├── backup.sh
│       └── check_config.sh
│
├── tests/                       # Tests y validaciones
│   ├── test_api.sh
│   ├── test_local.sh
│   └── test_scraper_simple.py
│
├── docs/                        # Documentación
│   ├── API_README.md            # Documentación de la API
│   ├── QUICKSTART.md            # Guía de inicio rápido
│   ├── STRUCTURE.md             # Estructura del proyecto
│   └── CHANGELOG.md             # Registro de cambios
│
├── data/                        # Datos locales
│   └── scraped_summaries.jsonl
│
└── logs/                        # Logs de la aplicación
    ├── scraper.log
    ├── scraper_error.log
    └── api.log
```

## 🚀 Inicio Rápido

### 1. Configurar entorno

```bash
# Copiar variables de entorno
cp .env.example .env

# Editar con tus credenciales
nano .env

# Instalar dependencias
python3 -m venv venv
source venv/bin/activate
pip install -r config/requirements.txt
```

### 2. Uso Local (macOS)

```bash
# Iniciar scraper automático (cada 9 AM)
./scripts/local/start_service_mac.sh

# Ver estado del servicio
./scripts/local/status_service_mac.sh

# Iniciar API REST
./scripts/local/start_api.sh

# Detener API
./scripts/local/stop_api.sh
```

### 3. Deployment a EC2

```bash
# Deploy completo (requiere EC2 ya creado)
./scripts/deployment/deploy_ec2.sh

# Setup inicial en EC2
./scripts/deployment/setup_ec2.sh

# Configurar systemd en EC2
./scripts/deployment/setup_systemd.sh
```

## 📡 API REST

La API proporciona acceso programático a las noticias scrapeadas.

### Endpoints Disponibles

**Públicos (sin autenticación):**
- `GET /` - Info de la API
- `GET /health` - Health check

**Protegidos (requieren API Key):**
- `GET /resumen/latest` - Último resumen disponible
- `GET /resumen/{fecha}` - Resumen de fecha específica (YYYY-MM-DD)
- `GET /historico` - Todos los resúmenes históricos
- `GET /rss/list` - Fuentes RSS configuradas
- `POST /scrape/run` - Ejecutar scraping manualmente

Ver documentación completa: [docs/API_README.md](docs/API_README.md)

## 👥 Guía de Usuario

### Para Consumir la API (tu hermano)

#### 1. Verificar que la API está activa

```bash
curl http://98.87.133.84:8000/health
```

Respuesta esperada: `{"status":"healthy"}`

#### 2. Obtener las últimas noticias

```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://98.87.133.84:8000/resumen/latest
```

#### 3. Obtener noticias de una fecha específica

```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://98.87.133.84:8000/resumen/2025-12-09
```

#### 4. Ver histórico completo

```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://98.87.133.84:8000/historico
```

#### 5. Usar desde Python

```python
import requests

API_URL = "http://35.169.240.172:8000"
API_KEY = "api-newscrapper-key01"

headers = {"X-API-Key": API_KEY}

# Obtener últimas noticias
response = requests.get(f"{API_URL}/resumen/latest", headers=headers)
noticias = response.json()

print(f"Fecha: {noticias['fecha']}")
print(f"Artículos: {len(noticias['articulos'])}")

for articulo in noticias['articulos']:
    print(f"\n{articulo['title']}")
    print(f"Link: {articulo['link']}")
    print(f"Resumen: {articulo['summary']}")
```

#### 6. Usar desde JavaScript/Node.js

```javascript
const API_URL = "http://98.87.133.84:8000";
const API_KEY = "api-newscrapper-key01";

async function obtenerNoticias() {
  const response = await fetch(`${API_URL}/resumen/latest`, {
    headers: {
      'X-API-Key': API_KEY
    }
  });
  
  const data = await response.json();
  
  console.log(`Fecha: ${data.fecha}`);
  console.log(`Artículos: ${data.articulos.length}`);
  
  data.articulos.forEach(articulo => {
    console.log(`\n${articulo.title}`);
    console.log(`Link: ${articulo.link}`);
    console.log(`Resumen: ${articulo.summary}`);
  });
}

obtenerNoticias();
```

### Para Administrar el Sistema (tú)

Ver [docs/QUICKSTART.md](docs/QUICKSTART.md) para instrucciones de deployment y administración.

## 🔧 Monitoreo

```bash
# Ver estado completo
./scripts/monitoring/monitor.sh

# Verificar configuración
./scripts/monitoring/check_config.sh

# Backup de datos
./scripts/monitoring/backup.sh
```

## 🧪 Testing

```bash
# Test del scraper
./tests/test_local.sh

# Test de la API
./tests/test_api.sh
```

## 📊 Fuentes de Noticias

- **CNBC**: Noticias financieras y mercados
- **Reuters**: Noticias de finanzas globales
- **Bloomberg**: Mercados y economía

## 🔑 Configuración

Variables principales en `.env`:

```bash
# AWS
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
BUCKET=tu-bucket-s3

# OpenAI
OPENAI_API_KEY=tu-openai-key

# API
API_PORT=8000
API_KEY=tu-api-key-segura
```

## 📚 Documentación Adicional

- [Guía de Inicio Rápido](docs/QUICKSTART.md)
- [Documentación de la API](docs/API_README.md)
- [Estructura del Proyecto](docs/STRUCTURE.md)
- [Registro de Cambios](docs/CHANGELOG.md)

## 🛠️ Tecnologías

- **Python 3.14+**
- **OpenAI API** (GPT-4o-mini)
- **AWS S3** (almacenamiento)
- **FastAPI** (API REST)
- **BeautifulSoup4** (parsing HTML)
- **Feedparser** (parsing RSS)

## 📝 Licencia

MIT
