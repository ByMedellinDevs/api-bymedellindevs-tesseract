# Despliegue en EasyPanel

Esta guía te ayudará a desplegar la API de OCR en EasyPanel.

## 📋 Requisitos Previos

- Cuenta en EasyPanel
- Repositorio Git con el código (GitHub, GitLab, etc.)

## 🚀 Pasos para Desplegar

### 1. Crear Nueva Aplicación en EasyPanel

1. Inicia sesión en tu panel de EasyPanel
2. Haz clic en "Create App" o "Nueva Aplicación"
3. Selecciona "Docker" como tipo de aplicación

### 2. Configurar el Repositorio

1. Conecta tu repositorio Git
2. Selecciona la rama principal (main/master)
3. EasyPanel detectará automáticamente el Dockerfile

### 3. Configurar Variables de Entorno

En la sección de "Environment Variables", agrega las siguientes variables:

```
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
RAILS_MASTER_KEY=ac7c6128ecc5c6e4f8c2bf163991eb92
SECRET_KEY_BASE=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456789012345678901234567890abcdef1234567890abcdef123456789012345678
PORT=3000
```

**⚠️ IMPORTANTE**: Las claves mostradas son solo para pruebas. En producción, genera claves únicas y seguras.

### 4. Configurar el Puerto

- EasyPanel mapeará automáticamente el puerto 3000 interno
- No necesitas configurar puertos manualmente
- La aplicación estará disponible en la URL que EasyPanel te proporcione

### 5. Configurar Dominio (Opcional)

1. Ve a la sección "Domains"
2. Agrega tu dominio personalizado
3. EasyPanel configurará automáticamente SSL/HTTPS

### 6. Desplegar

1. Haz clic en "Deploy" o "Desplegar"
2. EasyPanel construirá la imagen Docker automáticamente
3. El proceso puede tomar varios minutos la primera vez

## 🔧 Configuraciones Adicionales

### Base de Datos Externa

Si necesitas usar una base de datos externa (PostgreSQL, MySQL):

```
DATABASE_URL=postgresql://username:password@hostname:port/database_name
```

### CORS para Frontend

Si tienes un frontend en otro dominio:

```
CORS_ORIGINS=https://tu-frontend.com,https://www.tu-frontend.com
```

### Logs y Monitoreo

- Los logs estarán disponibles en la sección "Logs" de EasyPanel
- EasyPanel proporciona métricas básicas de CPU y memoria

## 🧪 Probar la API

Una vez desplegada, puedes probar los endpoints:

```bash
# Health check
curl https://tu-app.easypanel.host/api/v1/health

# OCR endpoint (con imagen)
curl -X POST -F "image=@imagen.png" https://tu-app.easypanel.host/api/v1/ocr/extract_text
```

## 🔄 Actualizaciones

Para actualizar la aplicación:

1. Haz push de los cambios a tu repositorio
2. En EasyPanel, haz clic en "Redeploy" o configura auto-deploy
3. EasyPanel reconstruirá y desplegará automáticamente

## 🆘 Solución de Problemas

### La aplicación no inicia

1. Revisa los logs en EasyPanel
2. Verifica que todas las variables de entorno estén configuradas
3. Asegúrate de que el Dockerfile sea válido

### Error de puerto

- EasyPanel maneja automáticamente el mapeo de puertos
- La aplicación debe escuchar en el puerto 3000 internamente

### Problemas de memoria

- Considera aumentar los recursos asignados en EasyPanel
- Optimiza la aplicación Rails si es necesario

## 📚 Recursos Adicionales

- [Documentación de EasyPanel](https://easypanel.io/docs)
- [Guía de Docker para Rails](https://guides.rubyonrails.org/getting_started_with_devcontainer.html)