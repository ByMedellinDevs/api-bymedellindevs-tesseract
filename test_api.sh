#!/bin/bash

# Script de prueba para ByMedellin ImageOCR API con Tesseract OCR
# Asegúrate de que el servidor Rails esté ejecutándose en http://localhost:3000

API_BASE_URL="http://localhost:3000"

echo "🧪 Iniciando pruebas de la API ByMedellin ImageOCR con Tesseract..."
echo "=================================================="

# Función para mostrar resultados
show_result() {
    local test_name="$1"
    local response="$2"
    local status_code="$3"
    
    echo ""
    echo "📋 Test: $test_name"
    echo "📊 Status Code: $status_code"
    echo "📄 Response:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
    echo "=================================================="
}

# Test 1: Health Check
echo "🔍 Test 1: Health Check"
response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/api/v1/health")
status_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)
show_result "Health Check" "$body" "$status_code"

# Test 2: Health Check alternativo
echo "🔍 Test 2: Health Check (ruta alternativa)"
response=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/health")
status_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)
show_result "Health Check Alternativo" "$body" "$status_code"

# Test 3: OCR con imagen base64 pequeña (imagen de prueba simple)
echo "🖼️ Test 3: OCR con imagen base64"
# Imagen PNG 1x1 pixel transparente en base64
base64_image="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/api/v1/ocr/extract_text" \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"data:image/png;base64,$base64_image\"}")
status_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)
show_result "OCR con Base64" "$body" "$status_code"

# Test 4: Error handling - sin parámetros
echo "❌ Test 4: Error handling - sin imagen"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/api/v1/ocr/extract_text" \
  -H "Content-Type: application/json" \
  -d "{}")
status_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)
show_result "Error - Sin Imagen" "$body" "$status_code"

# Test 5: Error handling - imagen inválida
echo "❌ Test 5: Error handling - imagen base64 inválida"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/api/v1/ocr/extract_text" \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"invalid_base64_data\"}")
status_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)
show_result "Error - Base64 Inválido" "$body" "$status_code"

echo ""
echo "✅ Pruebas completadas!"
echo ""
echo "📝 Notas:"
echo "- Para probar con imágenes reales, usa los ejemplos a continuación"
echo "- Asegúrate de que Tesseract OCR esté instalado en WSL"
echo "- El health check debe mostrar 'tesseract_ocr' como 'ok'"
echo ""

# Ejemplos adicionales para uso manual
echo "🔧 Ejemplos para pruebas manuales:"
echo ""
echo "1. OCR con archivo de imagen:"
echo "   curl -X POST $API_BASE_URL/api/v1/ocr/extract_text \\"
echo "     -F \"image=@/path/to/your/image.png\""
echo ""
echo "2. OCR con imagen base64 real:"
echo "   # Convertir imagen a base64:"
echo "   base64 -w 0 imagen.png"
echo "   # Luego usar en el request:"
echo "   curl -X POST $API_BASE_URL/api/v1/ocr/extract_text \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"image\": \"data:image/png;base64,<base64_string>\"}'"
echo ""
echo "3. Verificar Tesseract en WSL:"
echo "   wsl tesseract --version"
echo "   wsl tesseract --list-langs"
echo ""
echo "4. Crear imagen de prueba con texto:"
echo "   # En WSL:"
echo "   echo 'Hola Mundo' | convert -pointsize 24 label:@- test.png"
echo "   # Luego probar OCR:"
echo "   curl -X POST $API_BASE_URL/api/v1/ocr/extract_text \\"
echo "     -F \"image=@test.png\""