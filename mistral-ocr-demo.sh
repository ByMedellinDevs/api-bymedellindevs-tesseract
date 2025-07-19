#!/bin/bash

# Script demo de Mistral OCR para ByMedellin ImageOCR API
# Este es un script de demostración que simula la funcionalidad de Mistral OCR

IMAGE_PATH="$1"

if [ -z "$IMAGE_PATH" ]; then
    echo "Error: No se proporcionó ruta de imagen"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: El archivo de imagen no existe: $IMAGE_PATH"
    exit 1
fi

# Simular procesamiento OCR
echo "Procesando imagen: $IMAGE_PATH" >&2
sleep 1

# Obtener información del archivo
FILE_SIZE=$(stat -c%s "$IMAGE_PATH" 2>/dev/null || echo "unknown")
FILE_TYPE=$(file -b "$IMAGE_PATH" 2>/dev/null || echo "unknown")

# Generar respuesta simulada basada en el tipo de archivo
if [[ "$FILE_TYPE" == *"PNG"* ]] || [[ "$FILE_TYPE" == *"JPEG"* ]] || [[ "$FILE_TYPE" == *"image"* ]]; then
    # Respuesta de texto simple para una imagen válida
    echo "Texto extraído de la imagen de demostración."
    echo "Este es un resultado simulado de Mistral OCR."
    echo "Tamaño del archivo: $FILE_SIZE bytes"
    echo "Tipo: $FILE_TYPE"
    echo "[DEMO MODE - Reemplazar con Mistral real]"
else
    echo "Error: Formato de imagen no soportado - $FILE_TYPE"
    exit 1
fi

exit 0