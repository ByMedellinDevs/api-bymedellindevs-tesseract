# Configuración de Tesseract OCR
Rails.application.configure do
  # Configurar idioma de Tesseract desde variable de entorno
  config.tesseract_language = ENV['TESSERACT_LANGUAGE'] || 'spa'
  
  # Validar que el idioma esté disponible al inicializar la aplicación
  config.after_initialize do
    begin
      # Verificar idiomas disponibles en Tesseract
      available_languages = `tesseract --list-langs 2>&1`.split("\n")[1..-1] rescue []
      
      if available_languages.any?
        requested_languages = Rails.application.config.tesseract_language.split('+')
        missing_languages = requested_languages - available_languages
        
        if missing_languages.any?
          Rails.logger.warn "⚠️  Idiomas de Tesseract no disponibles: #{missing_languages.join(', ')}"
          Rails.logger.warn "📋 Idiomas disponibles: #{available_languages.join(', ')}"
        else
          Rails.logger.info "✅ Tesseract configurado con idioma(s): #{Rails.application.config.tesseract_language}"
        end
      else
        Rails.logger.warn "⚠️  No se pudieron verificar los idiomas de Tesseract"
      end
    rescue => e
      Rails.logger.error "❌ Error verificando configuración de Tesseract: #{e.message}"
    end
  end
end