# 🚀 Inicio Rápido - API de Noticias

## Lo Único que Necesitas Saber

**URL**: `http://35.169.240.172:8000`  
**API Key**: `api-newscrapper-key01`

## Uso Inmediato

### Opción 1: Desde la terminal (Mac/Linux)

```bash
curl -H "X-API-Key: api-newscrapper-key01" http://35.169.240.172:8000/resumen/latest
```

### Opción 2: Python (3 líneas)

```python
import requests
r = requests.get("http://35.169.240.172:8000/resumen/latest", headers={"X-API-Key": "api-newscrapper-key01"})
print(r.json())
```

### Opción 3: Navegador (probar en vivo)

Abre esto en tu navegador: http://35.169.240.172:8000/docs

1. Click en `GET /resumen/latest`
2. Click en "Try it out"
3. En "X-API-Key" poner: `api-newscrapper-key01`
4. Click en "Execute"

## Eso es Todo

La API te devuelve las últimas noticias financieras resumidas con IA.

**¿Más info?** → Ver `GUIA_USUARIO.md`
