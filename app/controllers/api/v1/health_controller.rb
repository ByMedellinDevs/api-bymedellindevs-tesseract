class Api::V1::HealthController < ApplicationController
  def check
    services = {
      tesseract_ocr: check_tesseract
    }
    
    overall_status = services.values.all? { |service| service[:status] == 'ok' } ? 'ok' : 'degraded'
    
    render json: {
      status: overall_status,
      timestamp: Time.current.iso8601,
      services: services
    }
  end

  private

  def check_tesseract
    begin
      result = `tesseract --version 2>&1`
            
      exit_status = $?.exitstatus
      
      if exit_status == 0
        # Extraer la versión de Tesseract
        version_line = result.lines.first&.strip
        {
          status: 'ok',
          message: 'Tesseract OCR disponible',
          version: version_line,
          environment: 'Linux'
        }
      else
        {
          status: 'error',
          message: 'Tesseract OCR no está disponible',
          details: result.strip,
          environment: 'Linux'
        }
      end
    rescue => e
      {
        status: 'error',
        message: "Error verificando Tesseract OCR: #{e.message}",
        environment: 'Linux'
      }
    end
  end
end
