# Guía de Usuario - NewsScrapperEC2 API

Esta guía es para usuarios que quieren **consumir** la API de noticias financieras.

## 📋 Información de Acceso

### URL de la API
```
http://98.87.133.84:8000
```

### Credenciales
```
API Key: api-newscrapper-key01
```

### Documentación Interactiva
- Swagger UI: http://98.87.133.84:8000/docs
- ReDoc: http://98.87.133.84:8000/redoc

## 🚀 Primeros Pasos

### 1. Verificar que la API está activa

```bash
curl http://35.169.240.172:8000/health
```

**Respuesta esperada:**
```json
{"status":"healthy"}
```

### 2. Obtener las últimas noticias

```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/resumen/latest
```

**Respuesta ejemplo:**
```json
{
  "fecha": "2025-12-09",
  "articulos": [
    {
      "title": "Título del artículo",
      "link": "https://www.cnbc.com/...",
      "published": "2025-12-09T17:41:32+00:00",
      "summary": "Resumen: ...\n\nTópicos: ...\nTickers: ..."
    }
  ]
}
```

## 📡 Todos los Endpoints

### Endpoints Públicos (sin API Key)

#### Health Check
```bash
curl http://35.169.240.172:8000/health
```

#### Info de la API
```bash
curl http://35.169.240.172:8000/
```

### Endpoints Protegidos (requieren API Key)

Todos estos requests necesitan el header `X-API-Key: api-newscrapper-key01`

#### 1. Últimas noticias
```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/resumen/latest
```

#### 2. Noticias de una fecha específica
```bash
# Formato: YYYY-MM-DD
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/resumen/2025-12-09
```

#### 3. Histórico completo
```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/historico
```

#### 4. Lista de fuentes RSS
```bash
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/rss/list
```

#### 5. Forzar scraping manual
```bash
curl -X POST -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/scrape/run
```

## 💻 Ejemplos de Código

### Python

#### Instalación de dependencias
```bash
pip install requests
```

#### Código
```python
import requests
from datetime import datetime

# Configuración
API_URL = "http://35.169.240.172:8000"
API_KEY = "api-newscrapper-key01"
headers = {"X-API-Key": API_KEY}

# Función para obtener últimas noticias
def obtener_ultimas_noticias():
    response = requests.get(f"{API_URL}/resumen/latest", headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        return data
    else:
        print(f"Error: {response.status_code}")
        return None

# Función para obtener noticias de una fecha
def obtener_noticias_fecha(fecha):
    """
    fecha: formato 'YYYY-MM-DD' ejemplo: '2025-12-09'
    """
    response = requests.get(f"{API_URL}/resumen/{fecha}", headers=headers)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        return None

# Función para obtener todo el histórico
def obtener_historico():
    response = requests.get(f"{API_URL}/historico", headers=headers)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        return None

# Ejemplo de uso
if __name__ == "__main__":
    print("Obteniendo últimas noticias...")
    noticias = obtener_ultimas_noticias()
    
    if noticias:
        print(f"\nFecha: {noticias['fecha']}")
        print(f"Total artículos: {len(noticias['articulos'])}\n")
        
        for i, articulo in enumerate(noticias['articulos'], 1):
            print(f"{i}. {articulo['title']}")
            print(f"   Link: {articulo['link']}")
            print(f"   Publicado: {articulo['published']}")
            print(f"   Resumen: {articulo['summary'][:200]}...")
            print()
```

### JavaScript/Node.js

#### Instalación de dependencias
```bash
npm install node-fetch
```

#### Código (ES6)
```javascript
// Para Node.js >= 18, fetch está incluido
// Para versiones anteriores: npm install node-fetch

const API_URL = "http://35.169.240.172:8000";
const API_KEY = "api-newscrapper-key01";

// Función para obtener últimas noticias
async function obtenerUltimasNoticias() {
  try {
    const response = await fetch(`${API_URL}/resumen/latest`, {
      headers: {
        'X-API-Key': API_KEY
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error:', error);
    return null;
  }
}

// Función para obtener noticias de una fecha
async function obtenerNoticiasFecha(fecha) {
  try {
    const response = await fetch(`${API_URL}/resumen/${fecha}`, {
      headers: {
        'X-API-Key': API_KEY
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error:', error);
    return null;
  }
}

// Función para obtener histórico
async function obtenerHistorico() {
  try {
    const response = await fetch(`${API_URL}/historico`, {
      headers: {
        'X-API-Key': API_KEY
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error:', error);
    return null;
  }
}

// Ejemplo de uso
async function main() {
  console.log('Obteniendo últimas noticias...\n');
  
  const noticias = await obtenerUltimasNoticias();
  
  if (noticias) {
    console.log(`Fecha: ${noticias.fecha}`);
    console.log(`Total artículos: ${noticias.articulos.length}\n`);
    
    noticias.articulos.forEach((articulo, i) => {
      console.log(`${i + 1}. ${articulo.title}`);
      console.log(`   Link: ${articulo.link}`);
      console.log(`   Publicado: ${articulo.published}`);
      console.log(`   Resumen: ${articulo.summary.substring(0, 200)}...\n`);
    });
  }
}

main();
```

### JavaScript (navegador)

```html
<!DOCTYPE html>
<html>
<head>
    <title>NewsScrapperEC2 - Noticias</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; }
        .articulo { border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .articulo h3 { margin-top: 0; }
        .metadata { color: #666; font-size: 0.9em; }
        button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>NewsScrapperEC2 - Noticias Financieras</h1>
    
    <button onclick="cargarNoticias()">Cargar Últimas Noticias</button>
    <button onclick="cargarHistorico()">Cargar Histórico</button>
    
    <div id="contenido"></div>
    
    <script>
        const API_URL = "http://35.169.240.172:8000";
        const API_KEY = "api-newscrapper-key01";
        
        async function cargarNoticias() {
            const contenido = document.getElementById('contenido');
            contenido.innerHTML = '<p>Cargando...</p>';
            
            try {
                const response = await fetch(`${API_URL}/resumen/latest`, {
                    headers: { 'X-API-Key': API_KEY }
                });
                
                const data = await response.json();
                
                let html = `<h2>Noticias del ${data.fecha}</h2>`;
                
                data.articulos.forEach(articulo => {
                    html += `
                        <div class="articulo">
                            <h3><a href="${articulo.link}" target="_blank">${articulo.title}</a></h3>
                            <p class="metadata">Publicado: ${articulo.published}</p>
                            <p>${articulo.summary}</p>
                        </div>
                    `;
                });
                
                contenido.innerHTML = html;
            } catch (error) {
                contenido.innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
            }
        }
        
        async function cargarHistorico() {
            const contenido = document.getElementById('contenido');
            contenido.innerHTML = '<p>Cargando histórico...</p>';
            
            try {
                const response = await fetch(`${API_URL}/historico`, {
                    headers: { 'X-API-Key': API_KEY }
                });
                
                const historico = await response.json();
                
                let html = '<h2>Histórico de Noticias</h2>';
                
                Object.keys(historico).sort().reverse().forEach(fecha => {
                    html += `<h3>${fecha} (${historico[fecha].length} artículos)</h3>`;
                    
                    historico[fecha].forEach(articulo => {
                        html += `
                            <div class="articulo">
                                <h4><a href="${articulo.link}" target="_blank">${articulo.title}</a></h4>
                                <p>${articulo.summary}</p>
                            </div>
                        `;
                    });
                });
                
                contenido.innerHTML = html;
            } catch (error) {
                contenido.innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
            }
        }
    </script>
</body>
</html>
```

### cURL (línea de comandos)

#### Guardar respuesta en archivo
```bash
# Últimas noticias en archivo JSON
curl -H "X-API-Key: api-newscrapper-key01" \
  http://35.169.240.172:8000/resumen/latest \
  -o noticias.json

# Ver archivo formateado
cat noticias.json | python3 -m json.tool
```

#### Script bash para monitoreo
```bash
#!/bin/bash
# monitor_noticias.sh

API_URL="http://35.169.240.172:8000"
API_KEY="api-newscrapper-key01"

echo "Verificando API..."
curl -s "$API_URL/health" | python3 -m json.tool

echo -e "\n\nÚltimas noticias:"
curl -s -H "X-API-Key: $API_KEY" "$API_URL/resumen/latest" | python3 -m json.tool
```

## 🔍 Formato de Respuestas

### Estructura de un artículo
```json
{
  "title": "Título del artículo",
  "link": "URL completa del artículo original",
  "published": "2025-12-09T17:41:32+00:00",
  "summary": "Resumen: ...\n\nTópicos: ...\nTickers: ..."
}
```

### Respuesta de `/resumen/latest` y `/resumen/{fecha}`
```json
{
  "fecha": "2025-12-09",
  "articulos": [
    { /* artículo 1 */ },
    { /* artículo 2 */ },
    { /* artículo 3 */ }
  ]
}
```

### Respuesta de `/historico`
```json
{
  "2025-12-08": [ /* artículos */ ],
  "2025-12-09": [ /* artículos */ ]
}
```

## ⚠️ Manejo de Errores

### Error 401 - No autorizado
```json
{
  "detail": "API Key inválida o faltante"
}
```
**Solución:** Verificar que estás enviando el header `X-API-Key` correctamente.

### Error 404 - No encontrado
```json
{
  "detail": "No se encontraron datos para la fecha solicitada"
}
```
**Solución:** Verificar que la fecha existe o usar `/resumen/latest` para obtener la más reciente.

### Error 500 - Error del servidor
```json
{
  "detail": "Error interno del servidor"
}
```
**Solución:** Contactar al administrador del sistema.

## 📊 Fuentes de Datos

La API obtiene noticias de las siguientes fuentes:

- **CNBC**: Noticias de mercados y finanzas
- **Reuters**: Noticias financieras globales
- **Bloomberg**: Mercados y economía

El scraper se ejecuta automáticamente cada 6 horas.

## 🕐 Frecuencia de Actualización

- **Scraping automático**: Cada 6 horas
- **Última actualización manual**: Usar endpoint `POST /scrape/run`

## 💡 Consejos de Uso

1. **Cache local**: Considera guardar las respuestas localmente para evitar requests innecesarios.

2. **Rate limiting**: Aunque no hay límite explícito, evita hacer requests excesivos.

3. **Manejo de fechas**: Las fechas están en formato `YYYY-MM-DD` y zona horaria UTC.

4. **Tickers**: Los resúmenes incluyen tickers de acciones mencionadas (ej: NVDA, PFE, etc.)

5. **Documentación interactiva**: Usa http://35.169.240.172:8000/docs para probar los endpoints directamente desde el navegador.

## 📞 Soporte

Para problemas técnicos o preguntas, contacta al administrador del sistema.

---

**Última actualización**: 9 de diciembre de 2025
