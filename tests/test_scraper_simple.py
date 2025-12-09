#!/usr/bin/env python3
# test_scraper_simple.py - Test rápido sin OpenAI

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import feedparser
import requests
from bs4 import BeautifulSoup

RSS_FEEDS = [
    "https://www.cnbc.com/id/100003114/device/rss/rss.html",
    "https://www.reuters.com/finance/markets/rss",
]

print("🧪 Probando scraper (sin OpenAI)\n")

for feed_url in RSS_FEEDS[:1]:  # Solo el primero para test rápido
    print(f"📡 Fetching: {feed_url}")
    try:
        d = feedparser.parse(feed_url)
        print(f"✅ Encontrados {len(d.entries)} artículos\n")
        
        for i, entry in enumerate(d.entries[:2], 1):  # Solo 2 artículos
            title = entry.get('title', 'Sin título')
            link = entry.get('link', '')
            
            print(f"{i}. 📰 {title}")
            print(f"   🔗 {link}")
            
            # Intentar descargar contenido
            try:
                r = requests.get(link, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
                soup = BeautifulSoup(r.text, 'html.parser')
                text = soup.get_text()[:500]  # Primeros 500 caracteres
                print(f"   📄 Contenido: {len(text)} caracteres extraídos")
                print(f"   Preview: {text[:150]}...")
            except Exception as e:
                print(f"   ⚠️  Error descargando: {e}")
            
            print()
            
    except Exception as e:
        print(f"❌ Error: {e}\n")

print("✅ Test completado!")
