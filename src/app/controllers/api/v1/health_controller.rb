class Api::V1::HealthController < ApplicationController
  def check
    services = {
      tesseract_ocr: check_tesseract,
      concurrent_config: check_concurrent_config
    }
    
    overall_status = services.values.all? { |service| service[:status] == 'ok' } ? 'ok' : 'degraded'
    
    render json: {
      status: overall_status,
      timestamp: Time.current.iso8601,
      services: services,
      concurrency: {
        max_threads: Rails.application.config.x.ocr&.max_concurrent_requests || 10,
        puma_workers: ENV.fetch("WEB_CONCURRENCY", 2),
        puma_threads: ENV.fetch("RAILS_MAX_THREADS", 8)
      }
    }
  end

  private

  def check_tesseract
    result = `tesseract --version 2>&1`
    exit_status = $?.exitstatus
    
    if exit_status == 0
      version_line = result.lines.first&.strip
      configured_language = ENV['TESSERACT_LANGUAGE'] || 'spa'
      available_languages = get_tesseract_languages
      
      # Verificar si el idioma configurado está disponible
      requested_languages = configured_language.split('+')
      missing_languages = requested_languages - available_languages
      language_status = missing_languages.empty? ? 'ok' : 'warning'
      
      {
        status: language_status,
        message: 'Tesseract OCR disponible',
        version: version_line,
        language_config: {
          configured: configured_language,
          status: language_status,
          missing: missing_languages,
          message: missing_languages.empty? ? 
            "Idioma(s) configurado(s): #{configured_language}" : 
            "Idiomas faltantes: #{missing_languages.join(', ')}"
        },
        languages: {
          available: available_languages,
          total: available_languages.length
        }
      }
    else
      {
        status: 'error',
        message: 'Tesseract OCR no disponible',
        details: result.strip
      }
    end
  rescue => e
    {
      status: 'error',
      message: "Error verificando Tesseract: #{e.message}"
    }
  end

  def check_concurrent_config
    {
      status: 'ok',
      message: 'Configuración de concurrencia cargada',
      config: {
        max_concurrent: Rails.application.config.x.ocr&.max_concurrent_requests || 'default',
        timeout: Rails.application.config.x.ocr&.timeout || 'default',
        temp_dir: Rails.application.config.x.ocr&.temp_dir&.to_s || 'default'
      }
    }
  rescue => e
    {
      status: 'error',
      message: "Error en configuración: #{e.message}"
    }
  end

  def get_tesseract_languages
    result = `tesseract --list-langs 2>&1`
    return [] unless $?.exitstatus == 0
    
    result.lines[1..-1]&.map(&:strip)&.compact || []
  rescue
    []
  end
end
