#!/bin/bash

# Script para probar la concurrencia de la API OCR
# Envía múltiples peticiones simultáneas para verificar el rendimiento

API_URL="http://localhost:3000/api/v1/ocr/extract_text"
CONCURRENT_REQUESTS=10
TOTAL_REQUESTS=50

echo "🧪 Probando API OCR con $CONCURRENT_REQUESTS peticiones simultáneas"
echo "📊 Total de peticiones: $TOTAL_REQUESTS"
echo "🎯 URL: $API_URL"
echo ""

# Imagen de prueba en base64 (imagen simple con texto "TEST")
TEST_IMAGE="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

# Función para enviar una petición
send_request() {
    local request_id=$1
    local start_time=$(date +%s.%N)
    
    response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"image\":\"$TEST_IMAGE\"}" \
        "$API_URL")
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local http_code="${response: -3}"
    local body="${response%???}"
    
    echo "Request $request_id: HTTP $http_code - ${duration}s"
    
    if [ "$http_code" = "200" ]; then
        echo "  ✅ Success"
    else
        echo "  ❌ Error: $body"
    fi
}

# Verificar que la API esté disponible
echo "🔍 Verificando disponibilidad de la API..."
health_response=$(curl -s "$API_URL/../health" || echo "ERROR")

if [[ "$health_response" == *"ok"* ]]; then
    echo "✅ API disponible"
else
    echo "❌ API no disponible. Asegúrate de que el servidor esté ejecutándose."
    exit 1
fi

echo ""
echo "🚀 Iniciando pruebas de concurrencia..."
echo "⏰ $(date)"
echo ""

# Ejecutar peticiones en paralelo
for i in $(seq 1 $TOTAL_REQUESTS); do
    send_request $i &
    
    # Limitar concurrencia
    if (( i % CONCURRENT_REQUESTS == 0 )); then
        wait  # Esperar a que terminen las peticiones actuales
        echo "📊 Completadas $i peticiones..."
    fi
done

# Esperar a que terminen todas las peticiones restantes
wait

echo ""
echo "✅ Pruebas completadas"
echo "⏰ $(date)"
echo ""
echo "📋 Resumen:"
echo "  - Peticiones totales: $TOTAL_REQUESTS"
echo "  - Concurrencia máxima: $CONCURRENT_REQUESTS"
echo "  - Revisa los logs del servidor para más detalles"