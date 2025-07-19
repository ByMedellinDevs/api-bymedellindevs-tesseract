# Script de PowerShell para construcción y despliegue Docker
# API Rails con Tesseract OCR
# Uso: .\docker-deploy.ps1 [build|run|stop|restart|logs|clean|status]

param(
    [Parameter(Position=0)]
    [ValidateSet("build", "run", "stop", "restart", "logs", "clean", "status", "help")]
    [string]$Command = "help"
)

# Configuración
$ImageName = "api-bymedellin-imageocr"
$ContainerName = "api-ocr"
$Port = "3000"
$Version = "latest"

# Funciones de utilidad
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar si Docker está instalado y ejecutándose
function Test-Docker {
    try {
        $null = Get-Command docker -ErrorAction Stop
        $null = docker info 2>$null
        return $true
    }
    catch {
        Write-Error "Docker no está instalado o no está ejecutándose"
        return $false
    }
}

# Verificar archivo master.key
function Test-MasterKey {
    if (-not (Test-Path "config\master.key")) {
        Write-Warning "Archivo config\master.key no encontrado"
        Write-Info "Para producción, asegúrate de tener la clave maestra configurada"
    }
}

# Construir imagen Docker
function Build-Image {
    Write-Info "Construyendo imagen Docker..."
    
    try {
        # Verificar si hay cambios en Dockerfile
        $dockerfileHash = (Get-FileHash Dockerfile -Algorithm MD5).Hash
        $cachedHash = ""
        
        if (Test-Path ".docker-build-cache") {
            $cachedHash = Get-Content ".docker-build-cache" -ErrorAction SilentlyContinue
        }
        
        if ($dockerfileHash -eq $cachedHash) {
            Write-Info "No hay cambios en Dockerfile, usando cache..."
            docker build -t "${ImageName}:${Version}" .
        }
        else {
            Write-Info "Detectados cambios en Dockerfile, construyendo sin cache..."
            docker build --no-cache -t "${ImageName}:${Version}" .
            $dockerfileHash | Out-File ".docker-build-cache" -Encoding UTF8
        }
        
        Write-Success "Imagen construida exitosamente: ${ImageName}:${Version}"
    }
    catch {
        Write-Error "Error al construir la imagen: $_"
        exit 1
    }
}

# Ejecutar contenedor
function Start-Container {
    Write-Info "Iniciando contenedor..."
    
    try {
        # Detener contenedor existente si está ejecutándose
        $existingContainer = docker ps -q -f "name=$ContainerName" 2>$null
        if ($existingContainer) {
            Write-Warning "Deteniendo contenedor existente..."
            docker stop $ContainerName | Out-Null
            docker rm $ContainerName | Out-Null
        }
        
        # Crear directorio para volúmenes si no existe
        $volumeDir = "docker-volumes"
        if (-not (Test-Path $volumeDir)) {
            New-Item -ItemType Directory -Path $volumeDir -Force | Out-Null
            New-Item -ItemType Directory -Path "$volumeDir\logs" -Force | Out-Null
            New-Item -ItemType Directory -Path "$volumeDir\storage" -Force | Out-Null
        }
        
        # Obtener master key si existe
        $masterKey = ""
        if (Test-Path "config\master.key") {
            $masterKey = Get-Content "config\master.key" -Raw
            $masterKey = $masterKey.Trim()
        }
        
        # Obtener ruta absoluta para volúmenes
        $currentPath = (Get-Location).Path
        $logsPath = "$currentPath\docker-volumes\logs"
        $storagePath = "$currentPath\docker-volumes\storage"
        
        # Ejecutar contenedor
        $dockerArgs = @(
            "run", "-d",
            "--name", $ContainerName,
            "-p", "${Port}:3000",
            "-e", "RAILS_ENV=production",
            "-e", "RAILS_LOG_TO_STDOUT=true",
            "-v", "${logsPath}:/rails/log",
            "-v", "${storagePath}:/rails/storage",
            "--restart", "unless-stopped"
        )
        
        if ($masterKey) {
            $dockerArgs += "-e", "RAILS_MASTER_KEY=$masterKey"
        }
        
        $dockerArgs += "${ImageName}:${Version}"
        
        & docker @dockerArgs | Out-Null
        
        Write-Success "Contenedor iniciado: $ContainerName"
        Write-Info "API disponible en: http://localhost:$Port"
        Write-Info "Health check: http://localhost:$Port/api/v1/health"
    }
    catch {
        Write-Error "Error al iniciar el contenedor: $_"
        exit 1
    }
}

# Detener contenedor
function Stop-Container {
    Write-Info "Deteniendo contenedor..."
    
    try {
        $existingContainer = docker ps -q -f "name=$ContainerName" 2>$null
        if ($existingContainer) {
            docker stop $ContainerName | Out-Null
            docker rm $ContainerName | Out-Null
            Write-Success "Contenedor detenido y eliminado"
        }
        else {
            Write-Warning "No hay contenedor ejecutándose con nombre: $ContainerName"
        }
    }
    catch {
        Write-Error "Error al detener el contenedor: $_"
    }
}

# Reiniciar contenedor
function Restart-Container {
    Write-Info "Reiniciando contenedor..."
    Stop-Container
    Start-Container
}

# Ver logs
function Show-Logs {
    Write-Info "Mostrando logs del contenedor..."
    
    try {
        $existingContainer = docker ps -q -f "name=$ContainerName" 2>$null
        if ($existingContainer) {
            docker logs -f $ContainerName
        }
        else {
            Write-Error "Contenedor no está ejecutándose"
            exit 1
        }
    }
    catch {
        Write-Error "Error al mostrar logs: $_"
    }
}

# Limpiar recursos Docker
function Clear-Docker {
    Write-Info "Limpiando recursos Docker..."
    
    try {
        # Detener contenedor si está ejecutándose
        $existingContainer = docker ps -q -f "name=$ContainerName" 2>$null
        if ($existingContainer) {
            docker stop $ContainerName | Out-Null
            docker rm $ContainerName | Out-Null
        }
        
        # Eliminar imagen
        $existingImage = docker images -q $ImageName 2>$null
        if ($existingImage) {
            docker rmi "${ImageName}:${Version}" | Out-Null
            Write-Success "Imagen eliminada"
        }
        
        # Limpiar cache de construcción
        if (Test-Path ".docker-build-cache") {
            Remove-Item ".docker-build-cache" -Force
        }
        
        # Limpiar volúmenes (opcional)
        $response = Read-Host "¿Eliminar volúmenes de datos? (y/N)"
        if ($response -match "^[Yy]$") {
            if (Test-Path "docker-volumes") {
                Remove-Item "docker-volumes" -Recurse -Force
                Write-Success "Volúmenes eliminados"
            }
        }
        
        Write-Success "Limpieza completada"
    }
    catch {
        Write-Error "Error durante la limpieza: $_"
    }
}

# Verificar estado del contenedor
function Get-ContainerStatus {
    Write-Info "Estado del contenedor:"
    
    try {
        $existingContainer = docker ps -q -f "name=$ContainerName" 2>$null
        if ($existingContainer) {
            Write-Host "✓ Contenedor ejecutándose" -ForegroundColor Green
            docker ps -f "name=$ContainerName" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
            
            # Verificar health check
            Write-Info "Verificando health check..."
            Start-Sleep -Seconds 2
            
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port/api/v1/health" -TimeoutSec 5 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    Write-Host "✓ API respondiendo correctamente" -ForegroundColor Green
                }
                else {
                    Write-Host "✗ API no responde correctamente (Status: $($response.StatusCode))" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "✗ API no responde" -ForegroundColor Red
            }
        }
        else {
            Write-Host "✗ Contenedor no está ejecutándose" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Error al verificar estado: $_"
    }
}

# Función de ayuda
function Show-Help {
    Write-Host "Uso: .\docker-deploy.ps1 [comando]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Comandos disponibles:" -ForegroundColor Yellow
    Write-Host "  build     - Construir imagen Docker"
    Write-Host "  run       - Ejecutar contenedor"
    Write-Host "  stop      - Detener contenedor"
    Write-Host "  restart   - Reiniciar contenedor"
    Write-Host "  logs      - Ver logs del contenedor"
    Write-Host "  status    - Ver estado del contenedor"
    Write-Host "  clean     - Limpiar recursos Docker"
    Write-Host "  help      - Mostrar esta ayuda"
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor Yellow
    Write-Host "  .\docker-deploy.ps1 build"
    Write-Host "  .\docker-deploy.ps1 run"
    Write-Host "  .\docker-deploy.ps1 restart"
    Write-Host "  .\docker-deploy.ps1 logs"
}

# Función principal
function Main {
    if (-not (Test-Docker)) {
        exit 1
    }
    
    switch ($Command) {
        "build" {
            Test-MasterKey
            Build-Image
        }
        "run" {
            Test-MasterKey
            Start-Container
            Start-Sleep -Seconds 3
            Get-ContainerStatus
        }
        "stop" {
            Stop-Container
        }
        "restart" {
            Restart-Container
            Start-Sleep -Seconds 3
            Get-ContainerStatus
        }
        "logs" {
            Show-Logs
        }
        "status" {
            Get-ContainerStatus
        }
        "clean" {
            Clear-Docker
        }
        "help" {
            Show-Help
        }
        default {
            Write-Error "Comando no reconocido: $Command"
            Show-Help
            exit 1
        }
    }
}

# Ejecutar función principal
Main