class Api::V1::OcrController < ApplicationController
  require 'base64'
  require 'tempfile'
  require 'json'

  def extract_text
    begin
      # Validar que se envió una imagen
      unless params[:image].present?
        return render json: { 
          error: 'No se proporcionó imagen', 
          message: 'Debe enviar una imagen en base64 o como archivo' 
        }, status: :bad_request
      end

      # Procesar imagen según el tipo de entrada
      image_path = process_image(params[:image])
      
      # Extraer texto usando Tesseract OCR
      extracted_text = extract_text_with_tesseract(image_path)
      
      # Limpiar archivo temporal
      File.delete(image_path) if File.exist?(image_path)
      
      render json: {
        success: true,
        text: extracted_text,
        message: 'Texto extraído exitosamente con Tesseract OCR'
      }
      
    rescue => e
      Rails.logger.error "Error en OCR: #{e.message}"
      render json: { 
        error: 'Error interno del servidor', 
        message: e.message 
      }, status: :internal_server_error
    end
  end

  private

  def process_image(image_param)
    if image_param.is_a?(String)
      # Es una imagen en base64
      process_base64_image(image_param)
    elsif image_param.respond_to?(:tempfile)
      # Es un archivo subido
      process_uploaded_file(image_param)
    else
      raise "Formato de imagen no soportado"
    end
  end

  def process_base64_image(base64_string)
    # Remover el prefijo data:image si existe
    base64_data = base64_string.gsub(/^data:image\/[a-z]+;base64,/, '')
    
    # Decodificar base64
    image_data = Base64.decode64(base64_data)
    
    # Crear archivo temporal
    temp_file = Tempfile.new(['ocr_image', '.png'])
    temp_file.binmode
    temp_file.write(image_data)
    temp_file.close
    
    temp_file.path
  end

  def process_uploaded_file(uploaded_file)
    # Crear archivo temporal con la extensión correcta
    extension = File.extname(uploaded_file.original_filename)
    temp_file = Tempfile.new(['ocr_image', extension])
    temp_file.binmode
    temp_file.write(uploaded_file.read)
    temp_file.close
    
    temp_file.path
  end

  def extract_text_with_tesseract(image_path)
    # Comando para usar Tesseract OCR localmente
    command = build_tesseract_command(image_path)
    
    Rails.logger.info "Ejecutando comando Tesseract: #{command}"
    
    # Ejecutar el comando y capturar la salida
    result = `#{command} 2>&1`
    exit_status = $?.exitstatus
    
    if exit_status != 0
      Rails.logger.error "Error ejecutando Tesseract: #{result}"
      raise "Error al procesar imagen con Tesseract: #{result}"
    end
    
    # Tesseract devuelve el texto directamente, limpiar espacios en blanco
    cleaned_text = result.strip
    
    # Si no hay texto, devolver mensaje informativo
    if cleaned_text.empty?
      return "No se pudo extraer texto de la imagen. La imagen puede no contener texto legible."
    end
    
    cleaned_text
  end

  def build_tesseract_command(image_path)
    "tesseract '#{image_path}' stdout -l spa"
  end
end
