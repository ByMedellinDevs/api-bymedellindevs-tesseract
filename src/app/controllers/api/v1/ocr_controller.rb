class Api::V1::OcrController < ApplicationController
  require 'base64'
  require 'tempfile'
  require 'securerandom'

  def extract_text
    # Validar entrada
    unless params[:image].present?
      return render json: { 
        error: 'No se proporcionó imagen', 
        message: 'Debe enviar una imagen en base64 o como archivo' 
      }, status: :bad_request
    end

    # Procesar imagen y extraer texto
    image_path = process_image(params[:image])
    extracted_text = extract_text_with_tesseract(image_path)
    
    render json: {
      success: true,
      text: extracted_text,
      message: 'Texto extraído exitosamente'
    }
    
  rescue => e
    Rails.logger.error "Error en OCR: #{e.message}"
    render json: { 
      error: 'Error procesando imagen', 
      message: e.message 
    }, status: :internal_server_error
  ensure
    # Limpiar archivo temporal de forma segura
    File.delete(image_path) if image_path && File.exist?(image_path)
  end

  private

  def process_image(image_param)
    if image_param.is_a?(String)
      process_base64_image(image_param)
    elsif image_param.respond_to?(:tempfile)
      process_uploaded_file(image_param)
    else
      raise "Formato de imagen no soportado"
    end
  end

  def process_base64_image(base64_string)
    # Remover prefijo data:image si existe
    base64_data = base64_string.gsub(/^data:image\/[a-z]+;base64,/, '')
    image_data = Base64.decode64(base64_data)
    
    # Crear archivo temporal único para evitar conflictos en concurrencia
    temp_file = create_temp_file('.png')
    temp_file.binmode
    temp_file.write(image_data)
    temp_file.close
    
    temp_file.path
  end

  def process_uploaded_file(uploaded_file)
    extension = File.extname(uploaded_file.original_filename)
    temp_file = create_temp_file(extension)
    temp_file.binmode
    temp_file.write(uploaded_file.read)
    temp_file.close
    
    temp_file.path
  end

  def create_temp_file(extension)
    # Usar SecureRandom para nombres únicos en entorno concurrente
    unique_name = "ocr_#{SecureRandom.hex(8)}_#{Process.pid}"
    Tempfile.new([unique_name, extension])
  end

  def extract_text_with_tesseract(image_path)
    # Obtener idioma desde variable de entorno o usar español por defecto
    language = ENV['TESSERACT_LANGUAGE'] || 'spa'
    
    # Comando optimizado para Tesseract con idioma configurable
    command = "tesseract '#{image_path}' stdout -l #{language} --oem 3 --psm 6"
    
    Rails.logger.debug "Ejecutando Tesseract: #{command}"
    
    result = `#{command} 2>&1`
    
    if $?.exitstatus != 0
      Rails.logger.error "Error Tesseract: #{result}"
      raise "Error procesando imagen: #{result}"
    end
    
    cleaned_text = result.strip
    cleaned_text.empty? ? "No se detectó texto en la imagen" : cleaned_text
  end
end
