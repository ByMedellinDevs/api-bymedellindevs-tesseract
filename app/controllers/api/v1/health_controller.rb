class Api::V1::HealthController < ApplicationController
  def check
    services = {
      database: check_database,
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

  def check_database
    begin
      # Intentar una consulta simple a la base de datos
      ActiveRecord::Base.connection.execute("SELECT 1")
      {
        status: 'ok',
        message: 'Base de datos conectada correctamente'
      }
    rescue => e
      {
        status: 'error',
        message: "Error de conexión a la base de datos: #{e.message}"
      }
    end
  end

  def check_tesseract
    begin
      # Verificar si Tesseract está disponible
      if running_in_wsl?
        # Si estamos en WSL, usar tesseract directamente
        result = `tesseract --version 2>&1`
      else
        # Si estamos en Windows, usar WSL para ejecutar tesseract
        result = `wsl tesseract --version 2>&1`
      end
      
      exit_status = $?.exitstatus
      
      if exit_status == 0
        # Extraer la versión de Tesseract
        version_line = result.lines.first&.strip
        {
          status: 'ok',
          message: 'Tesseract OCR disponible',
          version: version_line,
          environment: running_in_wsl? ? 'WSL' : 'Windows'
        }
      else
        {
          status: 'error',
          message: 'Tesseract OCR no está disponible',
          details: result.strip,
          environment: running_in_wsl? ? 'WSL' : 'Windows'
        }
      end
    rescue => e
      {
        status: 'error',
        message: "Error verificando Tesseract OCR: #{e.message}",
        environment: running_in_wsl? ? 'WSL' : 'Windows'
      }
    end
  end

  private

  def running_in_wsl?
    # Verificar si estamos ejecutando dentro de WSL
    File.exist?('/proc/version') && File.read('/proc/version').downcase.include?('microsoft')
  end
end
