Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Health check endpoints
      get "health", to: "health#check"
      get "health/check"
      
      # OCR endpoint - simplificado
      post "ocr/extract_text"
    end
  end
  
  # Health check global
  get "up" => "rails/health#show", as: :rails_health_check
  get "/health", to: "api/v1/health#check"
  
  # Documentación de la API (opcional)
  # root to: redirect('/api/v1/health')
end
