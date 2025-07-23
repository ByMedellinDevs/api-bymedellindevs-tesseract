# API ByMedellin OCR - Versión Simplificada y Optimizada

Esta API ha sido simplificada y optimizada para soportar **múltiples peticiones OCR simultáneas** aprovechando las capacidades nativas de Tesseract y Rails.

## 🚀 Mejoras Implementadas

### 1. Controlador OCR Simplificado
- ✅ Código más limpio y mantenible
- ✅ Manejo mejorado de archivos temporales con nombres únicos
- ✅ Mejor gestión de errores con `ensure` block
- ✅ Optimización de comandos Tesseract (`--oem 3 --psm 6`)

### 2. Configuración de Concurrencia
- ✅ **Puma Workers**: 2 procesos por defecto (configurable con `WEB_CONCURRENCY`)
- ✅ **Threads por Worker**: 8 threads por defecto (configurable con `RAILS_MAX_THREADS`)
- ✅ Preload de aplicación para mejor rendimiento
- ✅ Timeouts configurables para workers

### 3. Configuración Específica para OCR
- ✅ Límites de concurrencia configurables
- ✅ Timeouts específicos para operaciones OCR
- ✅ Limpieza automática de archivos temporales
- ✅ Directorio temporal dedicado

## 📊 Capacidad de Concurrencia

Con la configuración por defecto:
- **2 workers × 8 threads = 16 peticiones simultáneas**
- Cada petición OCR se ejecuta en un thread separado
- Tesseract maneja múltiples procesos eficientemente

## 🔧 Variables de Entorno

```bash
# Configuración de Puma
WEB_CONCURRENCY=2          # Número de workers
RAILS_MAX_THREADS=8        # Threads por worker

# Configuración de OCR
OCR_MAX_CONCURRENT=10      # Límite de peticiones OCR simultáneas
OCR_TIMEOUT=30             # Timeout en segundos para OCR
```

## 🏃‍♂️ Ejecución

### Desarrollo
```bash
rails server
```

### Producción con Docker
```bash
docker run -d -p 3000:3000 \
  -e WEB_CONCURRENCY=4 \
  -e RAILS_MAX_THREADS=8 \
  -e OCR_MAX_CONCURRENT=20 \
  --name api-ocr-optimized \
  api-bymedellin-imageocr
```

## 📋 Endpoints

### Health Check
```
GET /api/v1/health
```

Respuesta incluye información de concurrencia:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "services": {
    "tesseract_ocr": { "status": "ok", "version": "..." },
    "concurrent_config": { "status": "ok", "config": {...} }
  },
  "concurrency": {
    "max_threads": 10,
    "puma_workers": 2,
    "puma_threads": 8
  }
}
```

### Extracción de Texto
```
POST /api/v1/ocr/extract_text
```

## 🧪 Pruebas de Concurrencia

Para probar múltiples peticiones simultáneas:

```bash
# Instalar herramienta de testing
npm install -g artillery

# Crear archivo de prueba
cat > load-test.yml << EOF
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 5
scenarios:
  - name: "OCR Test"
    requests:
      - post:
          url: "/api/v1/ocr/extract_text"
          json:
            image: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
EOF

# Ejecutar prueba
artillery run load-test.yml
```

## 🔍 Monitoreo

Los logs mostrarán información de workers:
```
Worker 12345 iniciado
Ejecutando Tesseract: tesseract '/tmp/ocr_abc123_12345.png' stdout -l spa --oem 3 --psm 6
```

## ⚡ Optimizaciones Adicionales

1. **Escalado Horizontal**: Aumentar `WEB_CONCURRENCY` según CPU disponible
2. **Escalado Vertical**: Aumentar `RAILS_MAX_THREADS` para más I/O concurrente
3. **Límites de Memoria**: Configurar límites en producción
4. **Load Balancer**: Usar múltiples instancias detrás de un balanceador

La API ahora está optimizada para manejar múltiples peticiones OCR simultáneas de manera eficiente.