# logger_utils.py - Logging estructurado para EC2

import logging, json, time, os, sys
from typing import Optional, Dict, Any

# JSON formatter para logs estructurados
class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        base = {
            "ts": int(time.time() * 1000),
            "level": record.levelname,
            "msg": record.getMessage(),
            "logger": record.name,
            "module": record.module,
            "func": record.funcName,
            "line": record.lineno,
        }
        # Adjunta 'extra' si viene como dict
        for k, v in record.__dict__.items():
            if k in base or k.startswith("_"):
                continue
            # Solo serializables
            try:
                json.dumps(v)
                base[k] = v
            except Exception:
                base[k] = str(v)
        # Adjunta stack si es excepción
        if record.exc_info:
            base["exc_type"] = str(record.exc_info[0].__name__)
            base["exc"] = self.formatException(record.exc_info)
        return json.dumps(base, ensure_ascii=False)

def get_logger(name: str = "scraper", level: str = "INFO") -> logging.Logger:
    """Obtener logger configurado"""
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(getattr(logging, level.upper(), logging.INFO))
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(JsonFormatter())
        logger.addHandler(handler)
        logger.propagate = False
    return logger

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
ENV_STAGE = os.getenv("STAGE", "prod")
logger = get_logger(level=LOG_LEVEL)

def log_info(msg: str, extra: Optional[Dict[str, Any]] = None):
    """Helper para logging info"""
    logger.info(msg, extra={"stage": ENV_STAGE, **(extra or {})})

def log_warn(msg: str, extra: Optional[Dict[str, Any]] = None):
    """Helper para logging warning"""
    logger.warning(msg, extra={"stage": ENV_STAGE, **(extra or {})})

def log_error(msg: str, extra: Optional[Dict[str, Any]] = None):
    """Helper para logging error"""
    logger.error(msg, extra={"stage": ENV_STAGE, **(extra or {})})

# CloudWatch Embedded Metric Format (opcional)
def emit_metric(name: str, value: float, unit: str = "Count", dims: Optional[Dict[str, str]] = None):
    """Emitir métrica en formato EMF para CloudWatch"""
    blob = {
        "_aws": {
            "Timestamp": int(time.time() * 1000),
            "CloudWatchMetrics": [
                {
                    "Namespace": "NewsScrapperEC2",
                    "Dimensions": [list((dims or {"Stage": ENV_STAGE}).keys())],
                    "Metrics": [{"Name": name, "Unit": unit}]
                }
            ],
        },
        name: value,
    }
    blob.update(dims or {"Stage": ENV_STAGE})
    print(json.dumps(blob))
