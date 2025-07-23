# Script PowerShell para Docker - API OCR
# Uso: .\docker-deploy.ps1 [build|run|stop|restart|logs|status|help]

param(
    [Parameter(Position=0)]
    [ValidateSet("build", "run", "stop", "restart", "logs", "status", "help")]
    [string]$Command = "help"
)

# Configuración
$ImageName = "api-bymedellin-ocr"
$ContainerName = "api-ocr"
$Port = "3000"

# Funciones de utilidad
function Write-Info { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param([string]$Message); Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message); Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message); Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Verificar Docker
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

# Construir imagen
function Build-Image {
    Write-Info "Construyendo imagen Docker..."
    try {
        docker build -t $ImageName .
        Write-Success "Imagen construida: $ImageName"
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
        # Detener contenedor existente
        $existing = docker ps -q -f "name=$ContainerName" 2>$null
        if ($existing) {
            docker stop $ContainerName | Out-Null
            docker rm $ContainerName | Out-Null
        }
        
        # Obtener master key
        $masterKey = ""
        if (Test-Path "src\config\master.key") {
            $masterKey = (Get-Content "src\config\master.key" -Raw).Trim()
        }
        
        # Ejecutar contenedor
        $args = @("run", "-d", "--name", $ContainerName, "-p", "${Port}:3000")
        if ($masterKey) { $args += "-e", "RAILS_MASTER_KEY=$masterKey" }
        $args += $ImageName
        
        & docker @args | Out-Null
        Write-Success "Contenedor iniciado: $ContainerName"
        Write-Info "API disponible en: http://localhost:$Port"
    }
    catch {
        Write-Error "Error al iniciar el contenedor: $_"
        exit 1
    }
}

# Detener contenedor
function Stop-Container {
    Write-Info "Deteniendo contenedor..."
    $existing = docker ps -q -f "name=$ContainerName" 2>$null
    if ($existing) {
        docker stop $ContainerName | Out-Null
        docker rm $ContainerName | Out-Null
        Write-Success "Contenedor detenido"
    } else {
        Write-Warning "No hay contenedor ejecutándose"
    }
}

# Ver logs
function Show-Logs {
    $existing = docker ps -q -f "name=$ContainerName" 2>$null
    if ($existing) {
        docker logs -f $ContainerName
    } else {
        Write-Error "Contenedor no está ejecutándose"
    }
}

# Estado del contenedor
function Get-Status {
    Write-Info "Estado del contenedor:"
    $existing = docker ps -q -f "name=$ContainerName" 2>$null
    if ($existing) {
        Write-Host "✓ Contenedor ejecutándose" -ForegroundColor Green
        docker ps -f "name=$ContainerName" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
        
        # Health check
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port/api/v1/health" -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ API respondiendo" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "✗ API no responde" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Contenedor no ejecutándose" -ForegroundColor Red
    }
}

# Ayuda
function Show-Help {
    Write-Host "Uso: .\docker-deploy.ps1 [comando]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Comandos:" -ForegroundColor Yellow
    Write-Host "  build     - Construir imagen"
    Write-Host "  run       - Ejecutar contenedor"
    Write-Host "  stop      - Detener contenedor"
    Write-Host "  restart   - Reiniciar contenedor"
    Write-Host "  logs      - Ver logs"
    Write-Host "  status    - Ver estado"
    Write-Host "  help      - Mostrar ayuda"
}

# Función principal
function Main {
    if (-not (Test-Docker)) { exit 1 }
    
    switch ($Command) {
        "build" { Build-Image }
        "run" { Start-Container; Start-Sleep 3; Get-Status }
        "stop" { Stop-Container }
        "restart" { Stop-Container; Start-Container; Start-Sleep 3; Get-Status }
        "logs" { Show-Logs }
        "status" { Get-Status }
        "help" { Show-Help }
        default { Write-Error "Comando no reconocido: $Command"; Show-Help; exit 1 }
    }
}

Main