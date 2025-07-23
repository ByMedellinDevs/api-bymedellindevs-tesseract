# Script para probar la concurrencia de la API OCR en PowerShell
# Envía múltiples peticiones simultáneas para verificar el rendimiento

param(
    [int]$ConcurrentRequests = 10,
    [int]$TotalRequests = 50,
    [string]$ApiUrl = "http://localhost:3000/api/v1/ocr/extract_text"
)

Write-Host "🧪 Probando API OCR con $ConcurrentRequests peticiones simultáneas" -ForegroundColor Cyan
Write-Host "📊 Total de peticiones: $TotalRequests" -ForegroundColor Yellow
Write-Host "🎯 URL: $ApiUrl" -ForegroundColor Green
Write-Host ""

# Imagen de prueba en base64 (imagen simple)
$testImage = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

# Verificar que la API esté disponible
Write-Host "🔍 Verificando disponibilidad de la API..." -ForegroundColor Yellow

try {
    $healthUrl = $ApiUrl.Replace("/ocr/extract_text", "/health")
    $healthResponse = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10
    
    if ($healthResponse.status -eq "ok") {
        Write-Host "✅ API disponible" -ForegroundColor Green
        Write-Host "📋 Configuración de concurrencia:" -ForegroundColor Cyan
        Write-Host "  - Workers: $($healthResponse.concurrency.puma_workers)" -ForegroundColor White
        Write-Host "  - Threads: $($healthResponse.concurrency.puma_threads)" -ForegroundColor White
        Write-Host "  - Max concurrent: $($healthResponse.concurrency.max_threads)" -ForegroundColor White
    } else {
        Write-Host "⚠️ API disponible pero con estado: $($healthResponse.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ API no disponible. Asegúrate de que el servidor esté ejecutándose." -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚀 Iniciando pruebas de concurrencia..." -ForegroundColor Cyan
Write-Host "⏰ $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Variables para estadísticas
$results = @()
$jobs = @()

# Ejecutar peticiones en lotes para controlar la concurrencia
for ($i = 1; $i -le $TotalRequests; $i++) {
    # Crear job para petición asíncrona
    $job = Start-Job -ScriptBlock {
        param($RequestId, $Url, $Image)
        
        $startTime = Get-Date
        
        try {
            $body = @{
                image = $Image
            } | ConvertTo-Json
            
            $response = Invoke-RestMethod -Uri $Url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            return @{ 
                Success = $true
                Duration = $duration
                RequestId = $RequestId
                Response = $response
            }
        }
        catch {
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            return @{ 
                Success = $false
                Duration = $duration
                RequestId = $RequestId
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $i, $ApiUrl, $testImage
    
    $jobs += $job
    
    # Controlar concurrencia - esperar si hemos alcanzado el límite
    if ($jobs.Count -ge $ConcurrentRequests) {
        # Esperar a que termine al menos un job
        $completed = Wait-Job -Job $jobs -Any
        
        # Procesar jobs completados
        $completedJobs = $jobs | Where-Object { $_.State -eq "Completed" }
        foreach ($completedJob in $completedJobs) {
            $result = Receive-Job -Job $completedJob
            $results += $result
            
            if ($result.Success) {
                Write-Host "Request $($result.RequestId): ✅ Success - $([math]::Round($result.Duration, 2))s" -ForegroundColor Green
            } else {
                Write-Host "Request $($result.RequestId): ❌ Error - $([math]::Round($result.Duration, 2))s" -ForegroundColor Red
            }
            
            Remove-Job -Job $completedJob
        }
        
        # Actualizar lista de jobs activos
        $jobs = $jobs | Where-Object { $_.State -eq "Running" }
        
        if ($i % 10 -eq 0) {
            Write-Host "📊 Completadas $($results.Count) peticiones..." -ForegroundColor Yellow
        }
    }
}

# Esperar a que terminen todos los jobs restantes
Write-Host "⏳ Esperando peticiones restantes..." -ForegroundColor Yellow
Wait-Job -Job $jobs | Out-Null

# Procesar jobs restantes
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $results += $result
    
    if ($result.Success) {
        Write-Host "Request $($result.RequestId): ✅ Success - $([math]::Round($result.Duration, 2))s" -ForegroundColor Green
    } else {
        Write-Host "Request $($result.RequestId): ❌ Error - $([math]::Round($result.Duration, 2))s" -ForegroundColor Red
    }
    
    Remove-Job -Job $job
}

Write-Host ""
Write-Host "✅ Pruebas completadas" -ForegroundColor Green
Write-Host "⏰ $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Calcular estadísticas
$successfulRequests = $results | Where-Object { $_.Success -eq $true }
$failedRequests = $results | Where-Object { $_.Success -eq $false }

Write-Host "📋 Resumen de Resultados:" -ForegroundColor Cyan
Write-Host "  - Peticiones totales: $TotalRequests" -ForegroundColor White
Write-Host "  - Peticiones exitosas: $($successfulRequests.Count)" -ForegroundColor Green
Write-Host "  - Peticiones fallidas: $($failedRequests.Count)" -ForegroundColor Red
Write-Host "  - Tasa de éxito: $([math]::Round(($successfulRequests.Count / $TotalRequests) * 100, 2))%" -ForegroundColor Yellow
Write-Host "  - Concurrencia máxima: $ConcurrentRequests" -ForegroundColor White
Write-Host ""

if ($successfulRequests.Count -gt 0) {
    $avgDuration = ($successfulRequests | Measure-Object -Property Duration -Average).Average
    $minDuration = ($successfulRequests | Measure-Object -Property Duration -Minimum).Minimum
    $maxDuration = ($successfulRequests | Measure-Object -Property Duration -Maximum).Maximum
    
    Write-Host "⏱️ Tiempos de Respuesta:" -ForegroundColor Cyan
    Write-Host "  - Promedio: $([math]::Round($avgDuration, 2))s" -ForegroundColor White
    Write-Host "  - Mínimo: $([math]::Round($minDuration, 2))s" -ForegroundColor White
    Write-Host "  - Máximo: $([math]::Round($maxDuration, 2))s" -ForegroundColor White
}

Write-Host ""
Write-Host "💡 Revisa los logs del servidor para más detalles sobre el procesamiento interno" -ForegroundColor Blue