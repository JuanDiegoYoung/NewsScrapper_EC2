# Changelog

Todos los cambios notables de este proyecto serán documentados aquí.

## [2.0.0] - 2025-12-09

### Nuevo
- 🎉 Versión completamente nueva optimizada para EC2 (sin Docker)
- ✨ Scripts de deployment automatizado (`deploy_ec2.sh`)
- ✨ Setup automatizado en EC2 (`setup_ec2.sh`)
- ✨ Configuración de servicios systemd (`setup_systemd.sh`)
- ✨ Script de monitoreo (`monitor.sh`)
- ✨ Actualización rápida de código (`quick_update.sh`)
- ✨ Testing local antes de deployment (`test_local.sh`)
- ✨ Logs estructurados en formato JSON
- ✨ Soporte para CloudWatch Embedded Metrics
- ✨ API FastAPI mejorada con más endpoints
- ✨ Timer de systemd para ejecución cada 6 horas
- ✨ Manejo robusto de errores con retry exponencial

### Mejorado
- 🚀 Deployment simplificado sin Docker
- 🚀 Mejor integración con el sistema operativo (systemd)
- 🚀 Performance optimizado sin overhead de containers
- 🚀 Logs más accesibles y fáciles de monitorear
- 🚀 Actualizaciones de código más rápidas
- 🚀 Menor uso de recursos

### Cambiado
- 🔄 Estructura de proyecto simplificada
- 🔄 Configuración mediante .env en lugar de Docker Compose
- 🔄 Logs a archivos locales en lugar de Docker logs
- 🔄 API actualizada a OpenAI Chat Completions (gpt-4o-mini)

### Documentación
- 📚 README completo con guías de uso
- 📚 Ejemplos de configuración
- 📚 Troubleshooting guide
- 📚 Scripts comentados y autoexplicativos

## [1.0.0] - 2025-XX-XX (Versión Docker original)

### Features Originales
- Scraping de noticias desde RSS feeds
- Resumen con OpenAI
- Almacenamiento en S3
- API FastAPI
- Dashboard Streamlit
- Deployment con Docker y Kubernetes
- Email notifications via SES

---

**Formato basado en [Keep a Changelog](https://keepachangelog.com/)**
