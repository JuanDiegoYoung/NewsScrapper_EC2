# scrape_and_summarize.py — RSS → HTML → OpenAI (EC2 version)

import os, time, hashlib, json, requests, feedparser, random
from dateutil import parser as dateparser
from bs4 import BeautifulSoup
import boto3
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(override=True)

sys.path.append(str(Path(__file__).parent.parent.parent))
from config.logger_utils import get_logger
from src.scraper.save_bucket import upload_results_to_s3
import uuid

logger = get_logger(name="scraper")
ses = boto3.client("ses", region_name="us-east-1")

OPENAI_URL = "https://api.openai.com/v1/chat/completions"

def get_openai_api_key():
    name = os.getenv("OPENAI_SECRET")
    if name:
        sm = boto3.client("secretsmanager", region_name=os.getenv("AWS_REGION","us-east-1"))
        secret_str = sm.get_secret_value(SecretId=name)["SecretString"]
        return json.loads(secret_str)["OPENAI_API_KEY"]
    return os.getenv("OPENAI_API_KEY", "")

API_KEY = get_openai_api_key()

# --- Backoff exponencial con jitter ---
def _backoff(try_idx, base=0.5, cap=6.0):
    return min(cap, base * (2 ** try_idx)) * (0.5 + random.random())

def http_retry(call, tries=4, label="http"):
    last = None
    for i in range(tries):
        try:
            return call()
        except requests.RequestException as e:
            last = e
            # 4xx no-retriables (salvo 408/429): cortar
            status = getattr(e.response, "status_code", None)
            if status and status < 500 and status not in (408, 409, 425, 429):
                raise
            time.sleep(_backoff(i))
    raise last

RSS_FEEDS = [
    "https://www.cnbc.com/id/100003114/device/rss/rss.html",
    "https://www.reuters.com/finance/markets/rss",
    "https://feeds.bloomberg.com/markets/news.rss"
]

def send_email(subject, body, recipient="young.juandiego@gmail.com"):
    """Enviar email via SES (opcional)"""
    t0 = time.time()
    logger.info("ses.send.start", extra={"recipient": recipient, "subject": subject[:80]})
    try:
        response = ses.send_email(
            Source=recipient,
            Destination={"ToAddresses": [recipient]},
            Message={
                "Subject": {"Data": subject, "Charset": "UTF-8"},
                "Body": {"Text": {"Data": body, "Charset": "UTF-8"}}
            }
        )
        lat = round(time.time() - t0, 3)
        logger.info("ses.send.ok", extra={"recipient": recipient, "latency_s": lat, "message_id": response.get("MessageId")})
        return True
    except Exception as e:
        logger.exception("ses.send.error", extra={"recipient": recipient})
        return False

def fetch_article_text(url, timeout=25):
    """Descargar y extraer texto del artículo"""
    logger.info("fetch_article.start", extra={"url": url})
    try:
        r = http_retry(lambda: requests.get(url, timeout=timeout, headers={"User-Agent":"Mozilla/5.0"}), label="requests.get")
        r.raise_for_status()
    except Exception:
        logger.exception("fetch_article.request_error", extra={"url": url})
        return ""
    try:
        soup = BeautifulSoup(r.text, "html.parser")
        for sel in ["article", "main", "div#main-content", "div.article__content", "div#content"]:
            node = soup.select_one(sel)
            if node:
                txt = " ".join(node.get_text(" ", strip=True).split())
                if len(txt) >= 200:
                    logger.info("fetch_article.done", extra={"url": url, "chars": len(txt)})
                    return txt[:8000]
        txt = " ".join(soup.get_text(" ", strip=True).split())
        logger.info("fetch_article.done_fallback", extra={"url": url, "chars": len(txt)})
        return txt[:8000]
    except Exception:
        logger.exception("fetch_article.parse_error", extra={"url": url})
        return ""


def summarize_with_openai(title, url, body):
    """Resumir artículo con OpenAI"""
    if not API_KEY:
        logger.error("openai.missing_api_key")
        return "ERROR: falta OPENAI_API_KEY"
    
    prompt = (
        "Resumí en 2–3 líneas, listá 3 tópicos y tickers si aplica. Formato EXACTO:\n"
        "Resumen: ...\n"
        "Tópicos: a, b, c\n"
        "Tickers: ...\n\n"
        f"Título: {title}\nURL: {url}\n\nCuerpo:\n{body[:6000]}"
    )
    
    payload = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": "Sos un analista de noticias financieras, conciso y factual."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.2,
        "max_tokens": 800
    }
    
    t0 = time.time()
    try:
        def _post():
            r = requests.post(
                OPENAI_URL,
                headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
                json=payload,
                timeout=40
            )
            # Retriable: 429 / 5xx
            if r.status_code in (429,) or 500 <= r.status_code < 600:
                raise requests.HTTPError(response=r)
            r.raise_for_status()
            return r
        
        r = http_retry(_post, label="openai.post")
        j = r.json()
        
        # Extraer respuesta
        text = ""
        if "choices" in j and j["choices"]:
            text = j["choices"][0].get("message", {}).get("content", "")
        
        logger.info("openai.ok", extra={"latency_s": round(time.time() - t0, 3), "title": title[:80]})
        return text if text.strip() else f"(respuesta cruda)\n{j}"
    except requests.HTTPError as e:
        logger.exception("openai.http_error", extra={"status": getattr(e.response, "status_code", None), "title": title[:80]})
        return f"ERROR HTTP {getattr(e.response,'status_code',None)}: {getattr(e.response,'text','')[:400]}"
    except Exception:
        logger.exception("openai.error", extra={"title": title[:80]})
        return "ERROR: fallo al llamar a OpenAI"


def fetch_rss(url):
    """Parsear feed RSS"""
    d = feedparser.parse(url)
    out = []
    for e in d.entries:
        link = e.get("link") or e.get("id") or ""
        title = (e.get("title") or "").strip()
        summary = (e.get("summary") or e.get("description") or "").strip()
        published = None
        for k in ("published", "updated", "pubDate"):
            if e.get(k):
                try:
                    published = dateparser.parse(e.get(k)).isoformat()
                except Exception:
                    published = e.get(k)
                break
        uid = hashlib.sha1((link + title).encode()).hexdigest()
        out.append({
            "uid": uid,
            "title": title,
            "summary": summary,
            "link": link,
            "published": published,
            "_source": url
        })
    return out


def dedupe(entries):
    """Eliminar duplicados"""
    seen = set()
    out = []
    for e in entries:
        if e["uid"] in seen:
            continue
        seen.add(e["uid"])
        out.append(e)
    return out


def run_once(top_n=5):
    """Ejecutar un ciclo completo de scraping"""
    logger.info("run_once.start", extra={"top_n": top_n, "feeds": len(RSS_FEEDS)})
    all_entries = []
    
    for feed in RSS_FEEDS:
        try:
            logger.info("fetch_rss.start", extra={"feed": feed})
            all_entries.extend(fetch_rss(feed))
            logger.info("fetch_rss.done", extra={"feed": feed})
        except Exception:
            logger.exception("fetch_rss.error", extra={"feed": feed})
        time.sleep(0.2)

    all_entries = dedupe(all_entries)
    all_entries.sort(key=lambda x: x.get("published") or "", reverse=True)
    top = all_entries[:top_n]

    results = []
    for e in top:
        logger.info("summarize.start", extra={"uid": e["uid"], "title": e["title"][:80], "link": e["link"]})
        body = fetch_article_text(e["link"]) or e["summary"]
        summary = summarize_with_openai(e["title"], e["link"], body)
        results.append({
            "title": e["title"],
            "link": e["link"],
            "published": e.get("published"),
            "summary": summary
        })
        logger.info("summarize.done", extra={"uid": e["uid"], "summary_len": len(summary)})
        time.sleep(0.3)

    logger.info("run_once.done", extra={"n_results": len(results)})

    # Subir resultados a S3
    run_id = uuid.uuid4().hex
    upload_results_to_s3(results, run_id)

    return results


if __name__ == "__main__":
    results = run_once(top_n=5)
    
    # Guardar localmente
    with open("data/scraped_summaries.jsonl", "a", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    
    logger.info("scraper.complete", extra={"total_articles": len(results)})
    print(f"\n✅ Scraping completado: {len(results)} artículos procesados")
