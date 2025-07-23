# 🐳 Guía Docker - API OCR

Guía simplificada para ejecutar la API OCR con Docker.

## Requisitos

- Docker instalado
- Archivo `src/config/master.key` (para producción)

## 🚀 Uso Rápido

### Con Docker Compose (Recomendado)
```bash
# Construir y ejecutar
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

### Con Docker Manual
```bash
# Construir imagen
docker build -t api-bymedellin-ocr .
```bash
# Ejecutar con Docker
docker run -d -p 3000:3000 \
  -e RAILS_MASTER_KEY=$(cat src/config/master.key) \
  --name api-ocr \
  api-bymedellin-ocr
```

```bash
# Ejecutar con configuración personalizada
docker run -d \
  --name api-ocr \
  -p 3000:80 \
  -e RAILS_MASTER_KEY=$(cat src/config/master.key) \
  -e TESSERACT_LANGUAGE=spa+eng \
  -v $(pwd)/docker-volumes/logs:/rails/log \
  -v $(pwd)/docker-volumes/storage:/rails/storage \
  garuda64/api-bymedellin-imageocr:latest
```

## 🔧 Comandos Útiles

```bash
# Ver logs
docker logs -f api-ocr

# Acceder al contenedor
docker exec -it api-ocr /bin/bash

# Verificar Tesseract
docker exec api-ocr tesseract --version

# Detener y eliminar
docker stop api-ocr && docker rm api-ocr
```

## 🧪 Verificación

```bash
# Health check básico
curl http://localhost:3000/api/v1/health

# Health check con formato JSON
curl -H "Accept: application/json" http://localhost:3000/api/v1/health | jq

# Prueba OCR
curl -X POST -F "image=@test.png" http://localhost:3000/api/v1/ocr/extract_text
```

**Respuesta del Health Check:**
```json
{
  "status": "ok",
  "services": {
    "tesseract_ocr": {
      "status": "ok",
      "language_config": {
        "configured": "spa+eng",
        "status": "ok",
        "message": "Todos los idiomas configurados están disponibles"
      },
      "languages": {
        "available": ["eng", "osd", "spa"],
        "total": 3
      }
    }
  }
}
```

## 📊 Características

- **Ruby 3.2.3** con Rails
- **Tesseract OCR 5.x** (español e inglés preinstalados)
- **Puerto:** 80 (mapeado a 3000 en host)
- **Health check** automático con validación de idiomas
- **Configuración de idiomas** via `TESSERACT_LANGUAGE`
- **Volúmenes** para logs y storage
- **Validación automática** de idiomas al inicio

## 🔍 Troubleshooting

### Contenedor no inicia
```bash
docker logs api-ocr
```

### API no responde
```bash
docker exec api-ocr curl http://localhost:80/api/v1/health
```

### Verificar Tesseract
```bash
# Ver idiomas instalados
docker exec api-ocr tesseract --list-langs

# Verificar configuración actual
docker exec api-ocr printenv TESSERACT_LANGUAGE

# Probar OCR con idioma específico
docker exec api-ocr tesseract --help
```

### Problemas con idiomas
```bash
# Ver logs de validación de idiomas
docker logs api-ocr | grep -i tesseract

# Verificar health check para idiomas faltantes
curl http://localhost:3000/api/v1/health | jq '.services.tesseract_ocr.language_config'
```