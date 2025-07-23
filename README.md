# ByMedellin OCR API

API REST desarrollada en Ruby on Rails 8.0.2 para extracción de texto de imágenes usando Tesseract OCR, optimizada para múltiples peticiones simultáneas.

## Características

- ✅ Extracción de texto de imágenes usando Tesseract OCR
- ✅ Soporte para imágenes en base64 y archivos directos
- ✅ **Optimizada para concurrencia** - Maneja múltiples peticiones simultáneas
- ✅ Configuración de Puma para alta concurrencia (2 workers, 8 threads)
- ✅ Endpoints RESTful con respuestas JSON
- ✅ Health check con información de concurrencia
- ✅ CORS habilitado para aplicaciones frontend
- ✅ Manejo robusto de errores y timeouts
- ✅ Limpieza automática de archivos temporales

## Prerrequisitos

- Ruby 3.3.0+
- Rails 8.0.2
- Tesseract OCR 5.3.4+

## Instalación

1. **Clonar el repositorio:**
   ```bash
   git clone <repository-url>
   cd api-bymedellindevs-tesseract
   ```

2. **Instalar dependencias:**
   ```bash
   bundle install
   ```

3. **Configurar la base de datos:**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **Instalar Tesseract:**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng
   
   # macOS
   brew install tesseract tesseract-lang
   
   # Windows
   # Ver TESSERACT_SETUP.md para instrucciones detalladas
   ```

5. **Iniciar el servidor:**
   ```bash
   rails server -p 3000
   ```

## Configuración de Concurrencia

La API está optimizada para manejar múltiples peticiones simultáneas:

- **Workers de Puma**: 2 (configurable con `WEB_CONCURRENCY`)
- **Threads por worker**: 8 (configurable con `RAILS_MAX_THREADS`)
- **Capacidad total**: 16 peticiones simultáneas
- **Timeout por petición**: 30 segundos
- **Máximo concurrente**: 10 peticiones OCR simultáneas

### Variables de Entorno

```bash
# Configuración de concurrencia
export WEB_CONCURRENCY=2          # Número de workers
export RAILS_MAX_THREADS=8        # Threads por worker
export OCR_MAX_CONCURRENT=10       # Máximo OCR simultáneo
export OCR_TIMEOUT=30              # Timeout en segundos
```

## Endpoints de la API

### Health Check

**GET** `/api/v1/health`

Verifica el estado de la API, sus servicios y configuración de concurrencia.

**Respuesta exitosa:**
```json
{
  "status": "ok",
  "timestamp": "2025-07-23T15:04:25Z",
  "services": {
    "tesseract_ocr": {
      "status": "ok",
      "message": "Tesseract OCR disponible",
      "version": "tesseract 5.3.4",
      "languages": ["eng", "osd", "spa"]
    },
    "concurrent_config": {
      "status": "ok",
      "message": "Configuración de concurrencia cargada",
      "config": {
        "max_concurrent": 10,
        "timeout": 30,
        "temp_dir": "/tmp/ocr"
      }
    }
  },
  "concurrency": {
    "max_threads": 10,
    "puma_workers": 2,
    "puma_threads": 8
  }
}
```

### Extracción de Texto

**POST** `/api/v1/ocr/extract_text`

Extrae texto de una imagen usando Tesseract OCR.

#### Opción 1: Imagen en Base64

**Request:**
```json
{
  "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
}
```

#### Opción 2: Archivo de Imagen

**Request (multipart/form-data):**
```
POST /api/v1/ocr/extract_text
Content-Type: multipart/form-data

image: [archivo de imagen]
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "text": "Texto extraído de la imagen",
  "message": "Texto extraído exitosamente con Tesseract OCR"
}
```

**Respuesta de error:**
```json
{
  "error": "Error interno del servidor",
  "message": "Descripción del error"
}
```

## Configuración de Tesseract OCR

### Verificación de Instalación

```bash
# Verificar instalación y versión
tesseract --version

# Ver idiomas instalados
tesseract --list-langs
```

### Idiomas Soportados

La API está configurada para usar español por defecto. Los idiomas se configuran en `config/initializers/concurrent_ocr.rb`:

```ruby
# Configuración actual
Rails.application.config.ocr_language = 'spa'

# Para múltiples idiomas
Rails.application.config.ocr_language = 'spa+eng'
```

### Idiomas Disponibles

```bash
# Instalar idiomas adicionales
sudo apt install tesseract-ocr-fra  # Francés
sudo apt install tesseract-ocr-deu  # Alemán
sudo apt install tesseract-ocr-ita  # Italiano
sudo apt install tesseract-ocr-por  # Portugués
```

## Formatos de Imagen Soportados

- PNG
- JPEG/JPG
- TIFF
- BMP
- GIF
- PDF (páginas individuales)

## Rendimiento y Limitaciones

### Capacidad de Concurrencia
- **Máximo simultáneo**: 16 peticiones (2 workers × 8 threads)
- **OCR concurrente**: 10 peticiones OCR simultáneas
- **Timeout**: 30 segundos por petición
- **Limpieza automática**: Archivos temporales > 1 hora

### Limitaciones
- Tamaño máximo de imagen: ~10MB (configurable en Rails)
- Tesseract funciona mejor con imágenes de alta calidad y texto claro
- El rendimiento depende del tamaño y complejidad de la imagen
- Memoria recomendada: 2GB+ para alta concurrencia

### Optimización
- Usa imágenes con resolución 300 DPI o superior
- Contraste alto entre texto y fondo
- Texto horizontal para mejor precisión
- Evita imágenes muy grandes (>5MB) para mejor rendimiento

## Despliegue con Docker 🐳

La API incluye soporte completo para Docker con Tesseract OCR preinstalado.

### Construcción y Ejecución Rápida

```bash
# Construir imagen
docker build -t api-bymedellindevs-tesseract .

# Ejecutar contenedor
docker run -d -p 3000:3000 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name api-ocr \
  api-bymedellindevs-tesseract
```

### Usando Docker Compose

```bash
# Configurar variables de entorno
cp .env.example .env
# Editar .env con tu RAILS_MASTER_KEY

# Ejecutar con Docker Compose
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### Script de Automatización (Windows)

```powershell
# Construir y ejecutar
.\docker-deploy.ps1 build
.\docker-deploy.ps1 run

# Ver estado
.\docker-deploy.ps1 status

# Ver logs
.\docker-deploy.ps1 logs
```

### Características del Contenedor Docker

- ✅ **Tesseract OCR 5.x** preinstalado
- ✅ **Idiomas incluidos:** Español y Inglés
- ✅ **ImageMagick** para procesamiento de imágenes
- ✅ **Multi-stage build** para optimización de tamaño
- ✅ **Usuario no-root** para seguridad
- ✅ **Health checks** automáticos
- ✅ **Configuración de concurrencia** optimizada

### Documentación Completa

Para instrucciones detalladas de Docker, consulta:
- **[DOCKER_GUIDE.md](DOCKER_GUIDE.md)** - Guía completa de Docker
- **[TESSERACT_SETUP.md](TESSERACT_SETUP.md)** - Configuración de Tesseract
- **[CONCURRENT_OCR_GUIDE.md](CONCURRENT_OCR_GUIDE.md)** - Guía de concurrencia

## Pruebas de Concurrencia

### Script de Pruebas

```powershell
# Ejecutar test de concurrencia
.\test_simple_concurrent.ps1 -ConcurrentRequests 5 -TotalRequests 20

# Test más intensivo
.\test_simple_concurrent.ps1 -ConcurrentRequests 8 -TotalRequests 40
```

### Métricas Esperadas
- **Tasa de éxito**: >90%
- **Tiempo de respuesta**: 0.25-0.6 segundos
- **Capacidad**: Hasta 16 peticiones simultáneas

## Monitoreo y Logs

```bash
# Ver logs en tiempo real
tail -f log/development.log

# Health check
curl http://localhost:3000/api/v1/health

# Verificar concurrencia
curl http://localhost:3000/api/v1/health | jq '.concurrency'
```

## Desarrollo

### Estructura del Proyecto

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           ├── health_controller.rb    # Health check con concurrencia
│           └── ocr_controller.rb       # Extracción de texto optimizada
config/
├── initializers/
│   ├── concurrent_ocr.rb              # Configuración de concurrencia
│   └── cors.rb                        # Configuración CORS
├── puma.rb                            # Configuración de workers/threads
└── routes.rb                          # Rutas de la API
```

### Ejecutar Tests

```bash
# Ejecutar todos los tests
rails test

# Test de concurrencia
.\test_simple_concurrent.ps1 -ConcurrentRequests 5 -TotalRequests 20
```

### Logs y Debugging

Los logs incluyen información detallada sobre:
- Comandos de Tesseract ejecutados
- Errores de procesamiento
- Tiempos de respuesta
- Información de concurrencia

```bash
# Ver logs en tiempo real
tail -f log/development.log

# Logs específicos de OCR
grep "OCR" log/development.log
```

## Ejemplos de Uso

### cURL - Health Check

```bash
curl -X GET http://localhost:3000/api/v1/health | jq
```

### cURL - OCR con Base64

```bash
curl -X POST http://localhost:3000/api/v1/ocr/extract_text \
  -H "Content-Type: application/json" \
  -d '{"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="}'
```

### cURL - OCR con Archivo

```bash
curl -X POST http://localhost:3000/api/v1/ocr/extract_text \
  -F "image=@/path/to/your/image.png"
```

### JavaScript - Fetch API

```javascript
// OCR con base64
const response = await fetch('http://localhost:3000/api/v1/ocr/extract_text', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    image: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=='
  })
});

const result = await response.json();
console.log(result.text);
```

## Troubleshooting

### Error: "Tesseract OCR no disponible"

1. Verificar instalación de Tesseract:
   ```bash
   tesseract --version
   ```
2. Instalar Tesseract si es necesario:
   ```bash
   sudo apt install tesseract-ocr tesseract-ocr-spa
   ```

### Error: "No se pudo extraer texto"

1. Verificar que la imagen contenga texto legible
2. Asegurar buena calidad y contraste de la imagen
3. Probar con diferentes idiomas de OCR
4. Verificar tamaño de imagen (<10MB)

### Problemas de Concurrencia

1. Verificar configuración en health check:
   ```bash
   curl http://localhost:3000/api/v1/health | jq '.concurrency'
   ```
2. Ajustar variables de entorno si es necesario
3. Monitorear logs durante carga alta

### Rendimiento Lento

1. Optimizar imágenes antes del envío
2. Aumentar workers/threads si hay recursos disponibles
3. Verificar limpieza de archivos temporales
4. Considerar cache para imágenes repetidas

## Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Soporte

Para soporte técnico o preguntas:
- Crear un issue en el repositorio
- Contactar al equipo de desarrollo de ByMedellin

---

**ByMedellin OCR API** - Desarrollado con ❤️ usando Ruby on Rails y Tesseract OCR
