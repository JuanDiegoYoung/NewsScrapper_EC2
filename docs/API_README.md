# NewsScrapperEC2 API

API REST para acceder a noticias financieras scrapeadas y resumidas por OpenAI.

## 🌐 API en Producción

### URL Base
```
http://98.87.133.84:8000
```

### Documentación Interactiva

- **Swagger UI**: http://98.87.133.84:8000/docs
- **ReDoc**: http://98.87.133.84:8000/redoc

### Credenciales

```
API Key: api-newscrapper-key01
```

## 🚀 Inicio Rápido

### Test de Conectividad

```bash
# Verificar que la API está activa
curl http://98.87.133.84:8000/health
```

Respuesta esperada:
```json
{"status":"healthy"}
```

### Primer Request

```bash
# Obtener las últimas noticias
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/resumen/latest
```

## 💻 Desarrollo Local

Si necesitas correr la API localmente:

```bash
./scripts/local/start_api.sh
```

El servidor estará disponible en: `http://localhost:8000`

## 🔑 Autenticación

La API utiliza API Key authentication mediante el header `X-API-Key`.

La API key se obtiene automáticamente de:
1. **AWS Secrets Manager** (prioritario): Secret `newscrapper-api-secret`
2. **Variable de entorno**: `API_KEY` en el archivo `.env`

### Ejemplo de request con autenticación

**Producción:**
```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://98.87.133.84:8000/resumen/latest
```

**Local:**
```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://localhost:8000/resumen/latest
```

## 📡 Endpoints

### Públicos (sin autenticación)

#### `GET /`
Health check básico.

**Response:**
```json
{
    "status": "ok",
    "message": "NewsScrapperEC2 API activa",
    "version": "2.0"
}
```

#### `GET /health`
Health check detallado.

**Response:**
```json
{
    "status": "healthy"
}
```

### Protegidos (requieren API Key)

#### `GET /resumen/latest`
Obtener el resumen más reciente disponible.

**Headers:**
- `X-API-Key`: Tu API key

**Response:**
```json
{
    "fecha": "2025-12-09",
    "articulos": [
        {
            "title": "Título del artículo",
            "link": "https://...",
            "published": "2025-12-09T17:21:04+00:00",
            "summary": "Resumen generado por OpenAI..."
        }
    ]
}
```

#### `GET /resumen/{fecha}`
Obtener resumen de una fecha específica.

**Parámetros:**
- `fecha`: Fecha en formato `YYYY-MM-DD` (ej: `2025-12-09`)

**Headers:**
- `X-API-Key`: Tu API key

**Response:** Igual que `/resumen/latest`

#### `GET /historico`
Obtener todo el histórico de resúmenes.

**Headers:**
- `X-API-Key`: Tu API key

**Response:**
```json
{
    "2025-12-08": [ /* artículos */ ],
    "2025-12-09": [ /* artículos */ ]
}
```

#### `GET /rss/list`
Listar los feeds RSS configurados.

**Headers:**
- `X-API-Key`: Tu API key

**Response:**
```json
[
    "https://www.cnbc.com/id/100003114/device/rss/rss.html",
    "https://www.reuters.com/finance/markets/rss",
    "https://feeds.bloomberg.com/markets/news.rss"
]
```

#### `POST /scrape/run`
Forzar la ejecución del scraper ahora (útil para testing).

**Headers:**
- `X-API-Key`: Tu API key

**Response:**
```json
{
    "status": "ok",
    "articulos_procesados": 5,
    "results": [ /* artículos */ ]
}
```

## 🧪 Testing

### Script de prueba

```bash
# Probar sin autenticación (endpoints públicos)
./test_api.sh

# Probar con autenticación
export API_KEY='tu-api-key'
./test_api.sh
```

### Ejemplos con curl

```bash
# Health check
curl http://localhost:8000/health

# Último resumen
curl -H "X-API-Key: tu-api-key" \
    http://localhost:8000/resumen/latest

# Resumen por fecha
curl -H "X-API-Key: tu-api-key" \
    http://localhost:8000/resumen/2025-12-09

# Listar feeds RSS
curl -H "X-API-Key: tu-api-key" \
    http://localhost:8000/rss/list

# Forzar scraping
curl -X POST -H "X-API-Key: tu-api-key" \
    http://localhost:8000/scrape/run
```

## 🔧 Configuración

Variables de entorno en `.env`:

```bash
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_KEY=tu-api-key-segura

# AWS Configuration (para acceder a S3)
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
BUCKET=tu-bucket-s3
```

## 🐳 Deployment

### Local

```bash
./start_api.sh
```

### Background con nohup

```bash
cd /ruta/al/proyecto
source venv/bin/activate
cd src/api
nohup python -m uvicorn api:app --host 0.0.0.0 --port 8000 > ../../logs/api.log 2>&1 &
```

### Systemd (Linux/EC2)

Crear el archivo `/etc/systemd/system/newscrapper-api.service`:

```ini
[Unit]
Description=NewsScrapperEC2 API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/NewsScrapperEC2/src/api
Environment="PATH=/home/ubuntu/NewsScrapperEC2/venv/bin"
EnvironmentFile=/home/ubuntu/NewsScrapperEC2/.env
ExecStart=/home/ubuntu/NewsScrapperEC2/venv/bin/python -m uvicorn api:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Activar:
```bash
sudo systemctl enable newscrapper-api
sudo systemctl start newscrapper-api
sudo systemctl status newscrapper-api
```

## 📊 Monitoring

### Ver logs en tiempo real

```bash
tail -f logs/api.log
```

### Verificar que el servidor está corriendo

```bash
ps aux | grep uvicorn
curl http://localhost:8000/health
```

## 🔒 Seguridad

### Best Practices

1. **Nunca commitear el .env** - Ya está en `.gitignore`
2. **Usar HTTPS en producción** - Configurar con nginx + certbot
3. **Rotar API keys regularmente** - Actualizar en Secrets Manager
4. **Rate limiting** - Considerar usar nginx o middleware de FastAPI
5. **CORS** - Ya configurado para aceptar cualquier origen (ajustar en producción)

### Actualizar API Key en Secrets Manager

```bash
aws secretsmanager update-secret \
    --secret-id newscrapper-api-secret \
    --secret-string '{"NEWSCRAPPER-API-KEY":"nueva-key-segura"}'
```

## 🚨 Troubleshooting

### El servidor no inicia

```bash
# Verificar que el puerto 8000 no está ocupado
lsof -i :8000

# Verificar logs
cat logs/api.log

# Verificar que el entorno virtual está activado
which python
```

### Error 401 Unauthorized

Verifica que:
1. Estás enviando el header `X-API-Key`
2. La API key es correcta (verifica en Secrets Manager o `.env`)
3. El servidor cargó correctamente las variables de entorno

### No hay datos en los endpoints

Verifica que:
1. El scraper se ha ejecutado al menos una vez
2. Los datos están en S3: `aws s3 ls s3://tu-bucket/runs/`
3. Las credenciales de AWS tienen permisos de lectura en S3

## 📝 Licencia

MIT
