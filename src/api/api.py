# api.py - FastAPI para NewsScrapperEC2

from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import boto3
import json
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Cargar variables de entorno (override=True para sobrescribir)
load_dotenv(Path(__file__).parent.parent.parent / ".env", override=True)

sys.path.append(str(Path(__file__).parent.parent.parent))
from src.scraper.scrape_and_summarize import run_once as run_scraper
from config.config import BUCKET, PREFIX, SECRET_NAME, REGION

s3 = boto3.client("s3")

# =========================
#  Cargar API key desde Secrets Manager
# =========================

def load_api_key():
    """Cargar API key desde AWS Secrets Manager"""
    try:
        sm = boto3.client("secretsmanager", region_name=REGION)
        raw = sm.get_secret_value(SecretId=SECRET_NAME)["SecretString"]
        data = json.loads(raw)
        return data.get("NEWSCRAPPER-API-KEY", "")
    except Exception:
        # Si no hay secret configurado, usar variable de entorno
        return os.getenv("API_KEY", "default-dev-key")

API_KEY = load_api_key()

def verify_key(x_api_key: str = Header(None)):
    """Verificar API key en header"""
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

# =========================
#  Funciones internas
# =========================

def list_dates():
    """Listar todas las fechas disponibles en S3"""
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX, Delimiter="/")
    prefixes = resp.get("CommonPrefixes", [])
    fechas = []
    for p in prefixes:
        key = p["Prefix"]
        if "dt=" in key and key.endswith("/"):
            fecha = key.split("dt=")[1].replace("/", "")
            fechas.append(fecha)
    return fechas

def get_one_jsonl_for_date(fecha):
    """Obtener un archivo JSONL para una fecha específica"""
    prefix = f"{PREFIX}dt={fecha}/"
    resp = s3.list_objects_v2(Bucket=BUCKET, Prefix=prefix)
    archivos = resp.get("Contents", [])
    jsonls = [x["Key"] for x in archivos if x["Key"].endswith(".jsonl")]
    if not jsonls:
        return None
    jsonls.sort()
    return jsonls[-1]  # Retornar el más reciente

def read_jsonl_s3(key):
    """Leer archivo JSONL desde S3"""
    obj = s3.get_object(Bucket=BUCKET, Key=key)
    contenido = obj["Body"].read().decode("utf-8").splitlines()
    datos = []
    for linea in contenido:
        try:
            datos.append(json.loads(linea))
        except:
            pass
    return datos

def get_latest_date():
    """Obtener la fecha más reciente"""
    fechas = list_dates()
    if not fechas:
        return None
    fechas.sort()
    return fechas[-1]

def list_rss_feeds():
    """Listar feeds RSS configurados"""
    return [
        "https://www.cnbc.com/id/100003114/device/rss/rss.html",
        "https://www.reuters.com/finance/markets/rss",
        "https://feeds.bloomberg.com/markets/news.rss"
    ]


# =========================
#  FastAPI
# =========================
app = FastAPI(
    title="NewsScrapperEC2 API",
    description="API para acceder a noticias financieras scrapeadas y resumidas",
    version="2.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

@app.get("/")
def root():
    """Endpoint raíz - health check"""
    return {
        "status": "ok",
        "message": "NewsScrapperEC2 API activa",
        "version": "2.0"
    }

@app.get("/health")
def health():
    """Health check endpoint"""
    return {"status": "healthy"}

@app.get("/resumen/latest")
def endpoint_latest(auth=Depends(verify_key)):
    """Obtener resumen más reciente"""
    fecha = get_latest_date()
    if not fecha:
        raise HTTPException(404, "No hay fechas en S3")
    key = get_one_jsonl_for_date(fecha)
    if not key:
        raise HTTPException(404, "No hay archivos jsonl para esa fecha")
    datos = read_jsonl_s3(key)
    return JSONResponse({"fecha": fecha, "articulos": datos})

@app.get("/resumen/{fecha}")
def endpoint_fecha(fecha: str, auth=Depends(verify_key)):
    """Obtener resumen de una fecha específica (formato: YYYY-MM-DD)"""
    try:
        datetime.strptime(fecha, "%Y-%m-%d")
    except:
        raise HTTPException(400, "Formato de fecha inválido (usar YYYY-MM-DD)")
    key = get_one_jsonl_for_date(fecha)
    if not key:
        raise HTTPException(404, "No hay archivo jsonl para esa fecha")
    datos = read_jsonl_s3(key)
    return JSONResponse({"fecha": fecha, "articulos": datos})

@app.get("/historico")
def endpoint_historico(auth=Depends(verify_key)):
    """Obtener todo el histórico de resúmenes"""
    fechas = list_dates()
    master = {}
    for f in fechas:
        key = get_one_jsonl_for_date(f)
        if key:
            master[f] = read_jsonl_s3(key)
    return JSONResponse(master)

@app.get("/rss/list")
def endpoint_rss(auth=Depends(verify_key)):
    """Listar feeds RSS configurados"""
    return JSONResponse(list_rss_feeds())

@app.post("/scrape/run")
def endpoint_forzar_scrape(auth=Depends(verify_key)):
    """Forzar ejecución de scraping ahora"""
    try:
        results = run_scraper(top_n=5)
        return JSONResponse({
            "status": "ok",
            "articulos_procesados": len(results),
            "results": results
        })
    except Exception as e:
        raise HTTPException(500, str(e))


if __name__ == "__main__":
    import uvicorn
    import os
    
    port = int(os.getenv("API_PORT", "8000"))
    host = os.getenv("API_HOST", "0.0.0.0")
    
    uvicorn.run(
        "api:app",
        host=host,
        port=port,
        reload=False
    )
