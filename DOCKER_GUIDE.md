# 🐳 Guía Docker - API Rails con Tesseract OCR

Esta guía explica cómo construir y ejecutar la API Rails con Tesseract OCR usando Docker.

## 📋 Requisitos Previos

- Docker instalado y funcionando
- Archivo `config/master.key` (para producción)

## 🏗️ Construcción del Contenedor

### Construcción Básica
```bash
docker build -t api-bymedellin-imageocr .
```

### Construcción con Etiqueta de Versión
```bash
docker build -t api-bymedellin-imageocr:v1.0.0 .
```

### Construcción sin Cache (Recomendado para cambios importantes)
```bash
docker build --no-cache -t api-bymedellin-imageocr .
```

## 🚀 Ejecución del Contenedor

docker run -d -p 3000:3000 -e RAILS_MASTER_KEY=$(cat config/master.key) --name api-ocr api-bymedellin-imageocr

### Modo Desarrollo (con logs visibles)
```bash
docker run -p 3000:3000 \
  -e RAILS_ENV=development \
  --name api-ocr-dev \
  api-bymedellin-imageocr
```

### Modo Producción
```bash
docker run -d -p 3000:3000 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name api-ocr-prod \
  api-bymedellin-imageocr
```

### Con Variables de Entorno Personalizadas
```bash
docker run -d -p 3000:3000 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY=your_master_key_here \
  -e DATABASE_URL=sqlite3:///rails/storage/production.sqlite3 \
  --name api-ocr \
  api-bymedellin-imageocr
```

## 🔧 Comandos de Gestión

### Ver Logs del Contenedor
```bash
docker logs api-ocr
```

### Ver Logs en Tiempo Real
```bash
docker logs -f api-ocr
```

### Acceder al Contenedor (Debug)
```bash
docker exec -it api-ocr /bin/bash
```

### Detener el Contenedor
```bash
docker stop api-ocr
```

### Reiniciar el Contenedor
```bash
docker restart api-ocr
```

### Eliminar el Contenedor
```bash
docker rm api-ocr
```

## 🧪 Verificación de la Instalación

### 1. Verificar que el Contenedor está Ejecutándose
```bash
docker ps
```

### 2. Probar Health Check
```bash
curl http://localhost:3000/api/v1/health
```

### 3. Verificar Tesseract dentro del Contenedor
```bash
docker exec api-ocr tesseract --version
docker exec api-ocr tesseract --list-langs
```

## 📊 Características del Contenedor

### Paquetes Incluidos
- **Ruby 3.2.3** - Runtime de la aplicación
- **Tesseract OCR 5.x** - Motor de reconocimiento de texto
- **Idiomas soportados:**
  - Español (`spa`)
  - Inglés (`eng`)
- **ImageMagick** - Procesamiento de imágenes
- **SQLite3** - Base de datos
- **Dependencias de sistema** necesarias

### Puertos Expuestos
- **3000** - API Rails

### Volúmenes Recomendados (Opcional)
```bash
# Para persistir logs
docker run -d -p 3000:3000 \
  -v $(pwd)/logs:/rails/log \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name api-ocr \
  api-bymedellin-imageocr

# Para persistir base de datos
docker run -d -p 3000:3000 \
  -v $(pwd)/data:/rails/storage \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name api-ocr \
  api-bymedellin-imageocr
```

## 🐳 Docker Compose (Opcional)

Crear archivo `docker-compose.yml`:

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
    volumes:
      - ./logs:/rails/log
      - ./data:/rails/storage
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Ejecutar con Docker Compose
```bash
# Construir y ejecutar
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

## 🔍 Troubleshooting

### Problema: Contenedor no inicia
```bash
# Verificar logs
docker logs api-ocr

# Verificar que el puerto no esté en uso
netstat -tulpn | grep :3000
```

### Problema: Tesseract no funciona
```bash
# Verificar instalación dentro del contenedor
docker exec api-ocr which tesseract
docker exec api-ocr tesseract --version
```

### Problema: API no responde
```bash
# Verificar que el servicio esté escuchando
docker exec api-ocr netstat -tulpn | grep :3000

# Probar desde dentro del contenedor
docker exec api-ocr curl http://localhost:3000/api/v1/health
```

## 📈 Optimizaciones de Producción

### Multi-stage Build
El Dockerfile ya utiliza multi-stage build para optimizar el tamaño final.

### Tamaño de Imagen
```bash
# Ver tamaño de la imagen
docker images api-bymedellin-imageocr
```

### Recursos Recomendados
- **CPU:** 1-2 cores
- **RAM:** 512MB - 1GB
- **Disco:** 2GB mínimo

## 🔐 Seguridad

### Variables de Entorno Sensibles
- Nunca incluir `RAILS_MASTER_KEY` en el Dockerfile
- Usar archivos `.env` o secrets de Docker/Kubernetes
- El contenedor ejecuta como usuario no-root (UID 1000)

### Ejemplo con Archivo de Secrets
```bash
# Crear archivo de secrets
echo "your_master_key_here" | docker secret create rails_master_key -

# Usar en Docker Swarm
docker service create \
  --name api-ocr \
  --secret rails_master_key \
  -p 3000:3000 \
  api-bymedellin-imageocr
```

## 📝 Notas Adicionales

- El contenedor está optimizado para producción
- Incluye verificación automática de Tesseract al construir
- Soporta tanto SQLite como PostgreSQL/MySQL (configurando DATABASE_URL)
- Los logs se escriben en `/rails/log/` dentro del contenedor
- La aplicación se ejecuta como usuario `rails` (no root) por seguridad