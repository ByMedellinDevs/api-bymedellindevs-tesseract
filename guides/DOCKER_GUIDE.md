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
# Health check
curl http://localhost:3000/api/v1/health

# Prueba OCR
curl -X POST -F "image=@test.png" http://localhost:3000/api/v1/ocr/extract_text
```

## 📊 Características

- **Ruby 3.2.3** con Rails
- **Tesseract OCR 5.x** (español e inglés)
- **Puerto:** 3000
- **Health check** automático
- **Volúmenes** para logs y storage

## 🔍 Troubleshooting

### Contenedor no inicia
```bash
docker logs api-ocr
```

### API no responde
```bash
docker exec api-ocr curl http://localhost:3000/api/v1/health
```

### Verificar Tesseract
```bash
docker exec api-ocr tesseract --list-langs
```