# Guía para Probar la API con Apidog

## 📋 Información General de la API

**Base URL:** `http://localhost:3000`
**Versión:** v1
**Formato:** JSON

---

## 🔍 Endpoints Disponibles

### 1. Health Check
**Endpoint:** `GET /api/v1/health`
**Descripción:** Verifica el estado de la API y sus servicios

#### Configuración en Apidog:
- **Método:** GET
- **URL:** `http://localhost:3000/api/v1/health`
- **Headers:** 
  - `Content-Type: application/json`

#### Respuesta Esperada (200 OK):
```json
{
    "status": "ok",
    "timestamp": "2025-07-19T02:25:27Z",
    "services": {
        "database": {
            "status": "ok",
            "message": "Base de datos conectada correctamente"
        },
        "tesseract_ocr": {
            "status": "ok",
            "message": "Tesseract OCR disponible",
            "version": "tesseract 5.3.4",
            "environment": "WSL"
        }
    }
}
```

---

### 2. Extracción de Texto OCR
**Endpoint:** `POST /api/v1/ocr/extract_text`
**Descripción:** Extrae texto de imágenes usando Tesseract OCR

#### Configuración en Apidog:
- **Método:** POST
- **URL:** `http://localhost:3000/api/v1/ocr/extract_text`
- **Headers:** 
  - `Content-Type: multipart/form-data`

#### Opciones de Envío:

##### Opción 1: Archivo de Imagen (Recomendado)
- **Body Type:** form-data
- **Campo:** `image` (tipo: file)
- **Archivo:** Seleccionar imagen (PNG, JPG, JPEG, GIF, BMP, TIFF)

##### Opción 2: Base64
- **Body Type:** raw (JSON)
- **Content:**
```json
{
    "image_base64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
}
```

#### Respuesta Exitosa (200 OK):
```json
{
    "success": true,
    "text": "Texto extraído de la imagen",
    "message": "Texto extraído exitosamente con Tesseract OCR"
}
```

#### Respuestas de Error:

**400 Bad Request - Sin imagen:**
```json
{
    "error": "No se proporcionó imagen",
    "message": "Debe enviar una imagen en base64 o como archivo"
}
```

**500 Internal Server Error - Error de procesamiento:**
```json
{
    "error": "Error interno del servidor",
    "message": "Error al procesar imagen con Tesseract: [detalles del error]"
}
```

---

## 🧪 Casos de Prueba Recomendados

### Test Case 1: Health Check
1. **Objetivo:** Verificar que la API esté funcionando
2. **Método:** GET
3. **URL:** `http://localhost:3000/api/v1/health`
4. **Resultado esperado:** Status 200, todos los servicios "ok"

### Test Case 2: OCR con Imagen Válida
1. **Objetivo:** Extraer texto de una imagen
2. **Método:** POST
3. **URL:** `http://localhost:3000/api/v1/ocr/extract_text`
4. **Body:** form-data con archivo de imagen que contenga texto
5. **Resultado esperado:** Status 200, texto extraído correctamente

### Test Case 3: OCR sin Imagen
1. **Objetivo:** Validar manejo de errores
2. **Método:** POST
3. **URL:** `http://localhost:3000/api/v1/ocr/extract_text`
4. **Body:** vacío
5. **Resultado esperado:** Status 400, mensaje de error apropiado

### Test Case 4: OCR con Archivo Inválido
1. **Objetivo:** Validar manejo de archivos no válidos
2. **Método:** POST
3. **URL:** `http://localhost:3000/api/v1/ocr/extract_text`
4. **Body:** form-data con archivo de texto (.txt)
5. **Resultado esperado:** Status 500, mensaje de error de Tesseract

---

## 📝 Pasos Detallados en Apidog

### Configurar Health Check:
1. Crear nueva request
2. Seleccionar método GET
3. Ingresar URL: `http://localhost:3000/api/v1/health`
4. En Headers agregar: `Content-Type: application/json`
5. Enviar request
6. Verificar respuesta JSON con status "ok"

### Configurar OCR Test:
1. Crear nueva request
2. Seleccionar método POST
3. Ingresar URL: `http://localhost:3000/api/v1/ocr/extract_text`
4. En Body seleccionar "form-data"
5. Agregar campo "image" tipo "file"
6. Seleccionar imagen de prueba
7. Enviar request
8. Verificar respuesta con texto extraído

### Configurar Test de Error:
1. Crear nueva request
2. Seleccionar método POST
3. Ingresar URL: `http://localhost:3000/api/v1/ocr/extract_text`
4. Dejar Body vacío
5. Enviar request
6. Verificar respuesta de error 400

---

## 🔧 Troubleshooting

### Problemas Comunes:

1. **Connection refused:**
   - Verificar que el servidor esté ejecutándose en puerto 3000
   - Comprobar URL: `http://localhost:3000`

2. **500 Internal Server Error en OCR:**
   - Verificar que Tesseract esté instalado en WSL
   - Comprobar formato de imagen (usar PNG, JPG)
   - Verificar que la imagen contenga texto legible

3. **Timeout:**
   - Imágenes muy grandes pueden tardar más en procesarse
   - Aumentar timeout en Apidog si es necesario

### Verificación Manual:
```bash
# Verificar servidor
curl http://localhost:3000/api/v1/health

# Verificar OCR con imagen
curl -X POST -F "image=@imagen.png" http://localhost:3000/api/v1/ocr/extract_text
```

---

## 📊 Métricas de Rendimiento

- **Health Check:** < 100ms
- **OCR pequeña (< 1MB):** 1-3 segundos
- **OCR mediana (1-5MB):** 3-10 segundos
- **OCR grande (> 5MB):** 10+ segundos

---

## 🌐 Formatos de Imagen Soportados

- PNG (recomendado)
- JPG/JPEG
- GIF
- BMP
- TIFF
- WEBP

**Nota:** Para mejores resultados de OCR, usar imágenes con:
- Texto claro y legible
- Buen contraste
- Resolución adecuada (mínimo 300 DPI)
- Texto horizontal (no rotado)