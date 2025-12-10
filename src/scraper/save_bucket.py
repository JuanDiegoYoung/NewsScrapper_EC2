# save_bucket.py - Guardar resultados en S3

import os, io, json, datetime
import boto3
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(override=True)

sys.path.append(str(Path(__file__).parent.parent.parent))
from config.logger_utils import logger
from config.config import BUCKET as S3_BUCKET, PREFIX as S3_PREFIX

s3 = boto3.client("s3")

def _results_to_jsonl_bytes(results):
    """Convertir lista de resultados a JSONL bytes"""
    buf = io.StringIO()
    for r in results:
        buf.write(json.dumps(r, ensure_ascii=False) + "\n")
    return buf.getvalue().encode("utf-8")

def upload_results_to_s3(results, request_id: str) -> bool:
    """Subir resultados a S3 en formato JSONL"""
    if not S3_BUCKET:
        logger.warning("s3.skip_no_bucket")
        return False
    
    date_str = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    key = f"{S3_PREFIX}dt={date_str}/run={request_id}.jsonl"
    body = _results_to_jsonl_bytes(results)
    
    try:
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=key,
            Body=body,
            ContentType="application/json"
        )
        logger.info("s3.put.ok", extra={"bucket": S3_BUCKET, "key": key, "bytes": len(body)})
        return True
    except Exception:
        logger.exception("s3.put.error", extra={"bucket": S3_BUCKET, "key": key})
        return False
