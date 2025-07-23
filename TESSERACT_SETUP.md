# Configuración de Tesseract OCR para ByMedellin ImageOCR API

Esta guía te ayudará a instalar y configurar Tesseract OCR en WSL para que funcione con la API de ByMedellin ImageOCR.

## ¿Qué es Tesseract OCR?

Tesseract es un motor de OCR (Optical Character Recognition) de código abierto desarrollado originalmente por HP y actualmente mantenido por Google. Es uno de los motores de OCR más precisos y ampliamente utilizados.

## Instalación en WSL

### Opción 1: Instalación desde Repositorios (Recomendada)

```bash
# Actualizar la lista de paquetes
sudo apt update

# Instalar Tesseract y paquetes de idioma básicos
sudo apt install tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng

# Verificar la instalación
tesseract --version
```

### Opción 2: Instalación con Idiomas Adicionales

```bash
# Instalar Tesseract con múltiples idiomas
sudo apt install tesseract-ocr \
  tesseract-ocr-spa \
  tesseract-ocr-eng \
  tesseract-ocr-fra \
  tesseract-ocr-deu \
  tesseract-ocr-ita \
  tesseract-ocr-por

# Verificar idiomas instalados
tesseract --list-langs
```

### Opción 3: Instalación desde Código Fuente (Avanzada)

Si necesitas la versión más reciente o características específicas:

```bash
# Instalar dependencias de compilación
sudo apt install build-essential autoconf automake libtool \
  pkg-config libpng-dev libjpeg8-dev libtiff5-dev zlib1g-dev \
  libicu-dev libpango1.0-dev libcairo2-dev

# Clonar y compilar Tesseract
git clone https://github.com/tesseract-ocr/tesseract.git
cd tesseract
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
```

## Verificación de la Instalación

### Verificar que Tesseract está disponible:

```bash
# Verificar versión
tesseract --version

# Verificar ubicación del ejecutable
which tesseract

# Listar idiomas disponibles
tesseract --list-langs
```

### Probar OCR básico:

```bash
# Crear una imagen de prueba con texto
echo "Hola Mundo" | convert -pointsize 24 label:@- test_image.png

# Extraer texto de la imagen
tesseract test_image.png stdout -l spa

# Limpiar archivo de prueba
rm test_image.png
```

## Configuración de Idiomas

### Idiomas Disponibles

Los paquetes de idioma más comunes son:

- `tesseract-ocr-spa` - Español
- `tesseract-ocr-eng` - Inglés
- `tesseract-ocr-fra` - Francés
- `tesseract-ocr-deu` - Alemán
- `tesseract-ocr-ita` - Italiano
- `tesseract-ocr-por` - Portugués
- `tesseract-ocr-chi-sim` - Chino simplificado
- `tesseract-ocr-jpn` - Japonés
- `tesseract-ocr-kor` - Coreano

### Instalar idiomas adicionales:

```bash
# Instalar un idioma específico
sudo apt install tesseract-ocr-fra

# Instalar múltiples idiomas
sudo apt install tesseract-ocr-deu tesseract-ocr-ita
```

### Configurar idioma por defecto en la API

Edita el archivo `src/app/controllers/api/v1/ocr_controller.rb` y modifica el método `build_tesseract_command`:

```ruby
def build_tesseract_command(image_path)
  wsl_image_path = convert_to_wsl_path(image_path)
  
  # Cambiar 'spa' por el idioma deseado
  "wsl tesseract '#{wsl_image_path}' stdout -l spa"
end
```

### Usar múltiples idiomas:

```ruby
# Para detectar texto en español e inglés
"wsl tesseract '#{wsl_image_path}' stdout -l spa+eng"

# Para detectar texto en múltiples idiomas europeos
"wsl tesseract '#{wsl_image_path}' stdout -l spa+eng+fra+deu"
```

## Optimización y Configuración Avanzada

### Configuración de PSM (Page Segmentation Mode)

```ruby
# PSM 6: Asume un bloque uniforme de texto (por defecto)
"wsl tesseract '#{wsl_image_path}' stdout -l spa --psm 6"

# PSM 8: Trata la imagen como una sola palabra
"wsl tesseract '#{wsl_image_path}' stdout -l spa --psm 8"

# PSM 13: Línea de texto sin formato específico
"wsl tesseract '#{wsl_image_path}' stdout -l spa --psm 13"
```

### Configuración de OEM (OCR Engine Mode)

```ruby
# OEM 3: Usar tanto el motor legacy como LSTM (por defecto)
"wsl tesseract '#{wsl_image_path}' stdout -l spa --oem 3"

# OEM 1: Solo motor LSTM (más preciso para texto moderno)
"wsl tesseract '#{wsl_image_path}' stdout -l spa --oem 1"
```

### Configuración personalizada completa:

```ruby
def build_tesseract_command(image_path)
  wsl_image_path = convert_to_wsl_path(image_path)
  
  # Comando optimizado para documentos en español
  "wsl tesseract '#{wsl_image_path}' stdout -l spa --psm 6 --oem 1 -c tessedit_char_whitelist=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzáéíóúñüÁÉÍÓÚÑÜ"
end
```

## Troubleshooting

### Error: "tesseract: command not found"

```bash
# Verificar si Tesseract está instalado
sudo apt list --installed | grep tesseract

# Si no está instalado, instalarlo
sudo apt update
sudo apt install tesseract-ocr
```

### Error: "Error opening data file"

```bash
# Verificar que los datos de idioma están instalados
ls /usr/share/tesseract-ocr/*/tessdata/

# Instalar datos de idioma faltantes
sudo apt install tesseract-ocr-spa
```

### Error: "Failed to load language 'spa'"

```bash
# Verificar idiomas disponibles
tesseract --list-langs

# Instalar el idioma específico
sudo apt install tesseract-ocr-spa
```

### Problemas de rendimiento

1. **Imágenes muy grandes**: Redimensionar antes del OCR
2. **Imágenes de baja calidad**: Aplicar preprocesamiento
3. **Texto muy pequeño**: Aumentar resolución de la imagen

### Preprocesamiento de imágenes (opcional)

Para mejorar la precisión, puedes instalar ImageMagick en WSL:

```bash
# Instalar ImageMagick
sudo apt install imagemagick

# Ejemplo de preprocesamiento en el controlador
def preprocess_image(image_path)
  processed_path = image_path.gsub(/\.[^.]+$/, '_processed.png')
  
  # Convertir a escala de grises y mejorar contraste
  `wsl convert '#{convert_to_wsl_path(image_path)}' -colorspace Gray -normalize '#{convert_to_wsl_path(processed_path)}'`
  
  processed_path
end
```

## Comandos Útiles

### Información del sistema:

```bash
# Información detallada de Tesseract
tesseract --help

# Variables de configuración disponibles
tesseract --print-parameters

# Información de compilación
tesseract --version
```

### Testing y debugging:

```bash
# Ejecutar OCR con salida detallada
tesseract imagen.png stdout -l spa --psm 6 -c debug_file=/tmp/tesseract.log

# Ver el log de debug
cat /tmp/tesseract.log
```

## Integración con la API

### Verificar desde la API:

1. Inicia el servidor Rails:
   ```bash
   rails server -p 3000
   ```

2. Verifica el health check:
   ```bash
   curl http://localhost:3000/api/v1/health
   ```

3. La respuesta debe mostrar Tesseract como disponible:
   ```json
   {
     "status": "ok",
     "services": {
       "tesseract_ocr": {
         "status": "ok",
         "message": "Tesseract OCR disponible",
         "version": "tesseract 5.3.4"
       }
     }
   }
   ```

## Recursos Adicionales

- [Documentación oficial de Tesseract](https://tesseract-ocr.github.io/)
- [Wiki de Tesseract](https://github.com/tesseract-ocr/tesseract/wiki)
- [Mejores prácticas para OCR](https://github.com/tesseract-ocr/tesseract/wiki/ImproveQuality)
- [Lista completa de idiomas soportados](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html)

---

**Nota**: Esta configuración está optimizada para funcionar con la API de ByMedellin ImageOCR en un entorno WSL de Windows.