# ByMedellin ImageOCR API

API REST desarrollada en Ruby on Rails 8.0.2 para extracción de texto de imágenes usando Tesseract OCR local en WSL (Windows Subsystem for Linux).

## Características

- ✅ Extracción de texto de imágenes usando Tesseract OCR
- ✅ Soporte para imágenes en base64 y archivos directos
- ✅ Integración con WSL para procesamiento local
- ✅ Endpoints RESTful con respuestas JSON
- ✅ Health check para monitoreo de servicios
- ✅ CORS habilitado para aplicaciones frontend
- ✅ Manejo robusto de errores
- ✅ Conversión automática de rutas Windows a WSL

## Prerrequisitos

- Ruby 3.3.0+
- Rails 8.0.2
- WSL (Windows Subsystem for Linux)
- Tesseract OCR instalado en WSL

## Instalación

1. **Clonar el repositorio:**
   ```bash
   git clone <repository-url>
   cd api-bymedellin-imageocr
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

4. **Instalar Tesseract en WSL:**
   ```bash
   # En WSL
   sudo apt update
   sudo apt install tesseract-ocr tesseract-ocr-spa
   ```

5. **Iniciar el servidor:**
   ```bash
   rails server -p 3000
   ```

## Endpoints de la API

### Health Check

**GET** `/api/v1/health`

Verifica el estado de la API y sus servicios.

**Respuesta exitosa:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "database": {
      "status": "ok",
      "message": "Base de datos conectada correctamente"
    },
    "tesseract_ocr": {
      "status": "ok",
      "message": "Tesseract OCR disponible",
      "version": "tesseract 5.3.4"
    }
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

### Instalación en WSL

```bash
# Actualizar repositorios
sudo apt update

# Instalar Tesseract y paquetes de idioma
sudo apt install tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng

# Verificar instalación
tesseract --version
```

### Idiomas Soportados

Por defecto, la API está configurada para español (`-l spa`). Para cambiar el idioma, modifica el método `build_tesseract_command` en `app/controllers/api/v1/ocr_controller.rb`:

```ruby
# Para inglés
"wsl tesseract '#{wsl_image_path}' stdout -l eng"

# Para múltiples idiomas
"wsl tesseract '#{wsl_image_path}' stdout -l spa+eng"
```

### Idiomas Disponibles

```bash
# Ver idiomas instalados
tesseract --list-langs

# Instalar idiomas adicionales
sudo apt install tesseract-ocr-fra  # Francés
sudo apt install tesseract-ocr-deu  # Alemán
sudo apt install tesseract-ocr-ita  # Italiano
```

## Formatos de Imagen Soportados

- PNG
- JPEG/JPG
- TIFF
- BMP
- GIF
- PDF (páginas individuales)

## Limitaciones

- Tamaño máximo de imagen: Limitado por la configuración de Rails (por defecto ~10MB)
- Tesseract funciona mejor con imágenes de alta calidad y texto claro
- El rendimiento depende del tamaño y complejidad de la imagen
- Requiere WSL para el procesamiento de OCR

## Despliegue con Docker 🐳

La API incluye soporte completo para Docker con Tesseract OCR preinstalado.

### Construcción y Ejecución Rápida

```bash
# Construir imagen
docker build -t api-bymedellin-imageocr .

# Ejecutar contenedor
docker run -d -p 3000:3000 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name api-ocr \
  api-bymedellin-imageocr
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

### Scripts de Automatización

#### Linux/macOS:
```bash
# Construir y ejecutar
./docker-deploy.sh build
./docker-deploy.sh run

# Ver estado
./docker-deploy.sh status

# Ver logs
./docker-deploy.sh logs
```

#### Windows (PowerShell):
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
- ✅ **Volúmenes persistentes** para logs y datos

### Documentación Completa

Para instrucciones detalladas de Docker, consulta:
- **[DOCKER_GUIDE.md](DOCKER_GUIDE.md)** - Guía completa de Docker
- **[docker-compose.yml](docker-compose.yml)** - Configuración Docker Compose
- **[.env.example](.env.example)** - Variables de entorno

## Desarrollo

### Estructura del Proyecto

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           ├── health_controller.rb    # Health check
│           └── ocr_controller.rb       # Extracción de texto
config/
├── initializers/
│   └── cors.rb                        # Configuración CORS
└── routes.rb                          # Rutas de la API
```

### Ejecutar Tests

```bash
# Ejecutar todos los tests
rails test

# Ejecutar tests específicos
rails test test/controllers/api/v1/ocr_controller_test.rb
```

### Logs

Los logs de la aplicación incluyen información detallada sobre:
- Comandos de Tesseract ejecutados
- Errores de procesamiento
- Tiempos de respuesta

```bash
# Ver logs en tiempo real
tail -f log/development.log
```

## Ejemplos de Uso

### cURL - Health Check

```bash
curl -X GET http://localhost:3000/api/v1/health
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

### Error: "Tesseract OCR no está disponible en WSL"

1. Verificar que WSL esté instalado y funcionando
2. Instalar Tesseract en WSL:
   ```bash
   sudo apt update
   sudo apt install tesseract-ocr
   ```

### Error: "No se pudo extraer texto de la imagen"

1. Verificar que la imagen contenga texto legible
2. Asegurar que la imagen tenga buena calidad y contraste
3. Probar con diferentes idiomas de OCR

### Error de conversión de rutas

1. Verificar que la imagen se esté guardando correctamente
2. Comprobar los logs para ver la ruta convertida
3. Asegurar que WSL tenga acceso a la ruta especificada

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

**ByMedellin ImageOCR API** - Desarrollado con ❤️ usando Ruby on Rails y Tesseract OCR
