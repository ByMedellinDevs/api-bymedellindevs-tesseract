# Configuración para optimizar OCR concurrente
# Este archivo configura parámetros específicos para manejar múltiples peticiones OCR

Rails.application.configure do
  # Configuración de logs para debugging de concurrencia
  config.log_level = :info
  
  # Configuración de cache para mejorar rendimiento
  config.cache_store = :memory_store, { size: 64.megabytes }
  
  # Configuración específica para OCR
  config.x.ocr = ActiveSupport::OrderedOptions.new
  
  # Límites de concurrencia
  config.x.ocr.max_concurrent_requests = ENV.fetch("OCR_MAX_CONCURRENT", 10).to_i
  
  # Timeout para operaciones OCR (en segundos)
  config.x.ocr.timeout = ENV.fetch("OCR_TIMEOUT", 30).to_i
  
  # Configuración de Tesseract
  config.x.ocr.tesseract_options = {
    oem: 3,  # OCR Engine Mode: Legacy + LSTM
    psm: 6,  # Page Segmentation Mode: Uniform block of text
    language: 'spa'  # Idioma por defecto
  }
  
  # Configuración de archivos temporales
  config.x.ocr.temp_dir = Rails.root.join('tmp', 'ocr')
  
  # Crear directorio temporal si no existe
  FileUtils.mkdir_p(config.x.ocr.temp_dir) unless Dir.exist?(config.x.ocr.temp_dir)
end

# Configuración de limpieza automática de archivos temporales
Rails.application.config.after_initialize do
  # Limpiar archivos temporales antiguos al iniciar
  if Dir.exist?(Rails.application.config.x.ocr.temp_dir)
    Dir.glob(File.join(Rails.application.config.x.ocr.temp_dir, 'ocr_*')).each do |file|
      File.delete(file) if File.mtime(file) < 1.hour.ago
    rescue => e
      Rails.logger.warn "No se pudo eliminar archivo temporal #{file}: #{e.message}"
    end
  end
end