# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Configuración optimizada para múltiples peticiones OCR simultáneas
# Tesseract puede manejar múltiples procesos concurrentes eficientemente

# Número de workers (procesos)
# Cada worker puede manejar múltiples threads
workers ENV.fetch("WEB_CONCURRENCY", 2)

# Número de threads por worker
# Aumentado para manejar operaciones I/O intensivas como OCR
threads_count = ENV.fetch("RAILS_MAX_THREADS", 8)
threads threads_count, threads_count

# Puerto de escucha
port ENV.fetch("PORT", 3000)

# Configuración de memoria para workers
# Reiniciar workers si usan demasiada memoria
worker_timeout 60
worker_boot_timeout 60

# Preload de la aplicación para mejor rendimiento
preload_app!

# Configuración para reinicio automático
plugin :tmp_restart

# Solid Queue para trabajos en background
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# PID file
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# Configuración específica para workers
on_worker_boot do
  # Configuraciones específicas por worker si es necesario
  Rails.logger.info "Worker #{Process.pid} iniciado"
end

# Configuración de límites de memoria (opcional)
if ENV["RAILS_ENV"] == "production"
  # Reiniciar worker si usa más de 512MB
  worker_shutdown_timeout 30
end
