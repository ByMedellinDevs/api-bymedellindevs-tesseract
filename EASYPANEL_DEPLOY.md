# 🚀 Despliegue en EasyPanel

Guía simplificada para desplegar la API OCR en EasyPanel.

## 📋 Requisitos

- Cuenta en EasyPanel
- Repositorio Git (GitHub, GitLab, etc.)

## 🚀 Pasos de Despliegue

### 1. Crear Aplicación
1. Inicia sesión en EasyPanel
2. Crear "Nueva Aplicación" → Tipo "Docker"
3. Conectar repositorio Git

### 2. Variables de Entorno
```
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_MASTER_KEY=tu_clave_maestra_aqui
PORT=3000
```

### 3. Configuración
- **Puerto:** 3000 (automático)
- **Dominio:** Opcional, con SSL automático
- **Recursos:** 1 CPU, 512MB RAM mínimo

### 4. Desplegar
1. Clic en "Deploy"
2. EasyPanel construye la imagen automáticamente
3. Proceso toma varios minutos

## 🧪 Verificación

```bash
# Health check
curl https://tu-app.easypanel.host/api/v1/health

# Prueba OCR
curl -X POST -F "image=@test.png" https://tu-app.easypanel.host/api/v1/ocr/extract_text
```

## 🔄 Actualizaciones

- Push cambios al repositorio
- EasyPanel redespliega automáticamente
- O usar botón "Redeploy" manual

## 🔍 Troubleshooting

### App no inicia
- Revisar logs en EasyPanel
- Verificar variables de entorno
- Validar Dockerfile

### Problemas de memoria
- Aumentar recursos en EasyPanel
- Optimizar configuración Rails