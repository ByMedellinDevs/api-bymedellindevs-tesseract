# Test de Concurrencia para API OCR
param(
    [int]$ConcurrentRequests = 5,
    [int]$TotalRequests = 20,
    [string]$ApiUrl = "http://localhost:3000/api/v1/ocr/extract_text"
)

Write-Host "Probando API OCR con $ConcurrentRequests peticiones simultaneas" -ForegroundColor Cyan
Write-Host "Total de peticiones: $TotalRequests" -ForegroundColor Yellow
Write-Host "URL: $ApiUrl" -ForegroundColor Green
Write-Host ""

# Imagen de prueba simple en base64
$testImage = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

# Verificar API
Write-Host "Verificando disponibilidad de la API..." -ForegroundColor Yellow

try {
    $healthUrl = $ApiUrl.Replace("/ocr/extract_text", "/health")
    $healthResponse = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10
    
    if ($healthResponse.status -eq "ok") {
        Write-Host "API disponible" -ForegroundColor Green
        Write-Host "Workers: $($healthResponse.concurrency.puma_workers)" -ForegroundColor White
        Write-Host "Threads: $($healthResponse.concurrency.puma_threads)" -ForegroundColor White
    } else {
        Write-Host "API disponible pero con estado: $($healthResponse.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "API no disponible. Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Iniciando pruebas de concurrencia..." -ForegroundColor Cyan
Write-Host "Hora: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Variables para resultados
$results = @()
$jobs = @()

# Ejecutar peticiones
for ($i = 1; $i -le $TotalRequests; $i++) {
    $job = Start-Job -ScriptBlock {
        param($RequestId, $Url, $Image)
        
        $startTime = Get-Date
        
        try {
            $body = @{ image = $Image } | ConvertTo-Json
            $response = Invoke-RestMethod -Uri $Url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Crear objeto con propiedades explícitas
            $result = New-Object PSObject
            $result | Add-Member -MemberType NoteProperty -Name "Success" -Value $true
            $result | Add-Member -MemberType NoteProperty -Name "Duration" -Value $duration
            $result | Add-Member -MemberType NoteProperty -Name "RequestId" -Value $RequestId
            $result | Add-Member -MemberType NoteProperty -Name "Response" -Value $response
            
            return $result
        }
        catch {
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Crear objeto con propiedades explícitas
            $result = New-Object PSObject
            $result | Add-Member -MemberType NoteProperty -Name "Success" -Value $false
            $result | Add-Member -MemberType NoteProperty -Name "Duration" -Value $duration
            $result | Add-Member -MemberType NoteProperty -Name "RequestId" -Value $RequestId
            $result | Add-Member -MemberType NoteProperty -Name "Error" -Value $_.Exception.Message
            
            return $result
        }
    } -ArgumentList $i, $ApiUrl, $testImage
    
    $jobs += $job
    
    # Controlar concurrencia
    if ($jobs.Count -ge $ConcurrentRequests) {
        Wait-Job -Job $jobs -Any | Out-Null
        
        $completedJobs = $jobs | Where-Object { $_.State -eq "Completed" }
        foreach ($completedJob in $completedJobs) {
            $result = Receive-Job -Job $completedJob
            $results += $result
            
            if ($result.Success) {
                Write-Host "Request $($result.RequestId): Success - $([math]::Round($result.Duration, 2))s" -ForegroundColor Green
            } else {
                Write-Host "Request $($result.RequestId): Error - $([math]::Round($result.Duration, 2))s" -ForegroundColor Red
            }
            
            Remove-Job -Job $completedJob
        }
        
        $jobs = $jobs | Where-Object { $_.State -eq "Running" }
        
        if ($i % 10 -eq 0) {
            Write-Host "Completadas $($results.Count) peticiones..." -ForegroundColor Yellow
        }
    }
}

# Esperar jobs restantes
Write-Host "Esperando peticiones restantes..." -ForegroundColor Yellow
Wait-Job -Job $jobs | Out-Null

foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $results += $result
    
    if ($result.Success) {
        Write-Host "Request $($result.RequestId): Success - $([math]::Round($result.Duration, 2))s" -ForegroundColor Green
    } else {
        Write-Host "Request $($result.RequestId): Error - $([math]::Round($result.Duration, 2))s" -ForegroundColor Red
    }
    
    Remove-Job -Job $job
}

Write-Host ""
Write-Host "Pruebas completadas" -ForegroundColor Green
Write-Host "Hora: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Estadisticas
$successfulRequests = $results | Where-Object { $_.Success -eq $true }
$failedRequests = $results | Where-Object { $_.Success -eq $false }

Write-Host "Resumen de Resultados:" -ForegroundColor Cyan
Write-Host "  - Peticiones totales: $TotalRequests" -ForegroundColor White
Write-Host "  - Peticiones exitosas: $($successfulRequests.Count)" -ForegroundColor Green
Write-Host "  - Peticiones fallidas: $($failedRequests.Count)" -ForegroundColor Red
Write-Host "  - Tasa de exito: $([math]::Round(($successfulRequests.Count / $TotalRequests) * 100, 2))%" -ForegroundColor Yellow
Write-Host "  - Concurrencia maxima: $ConcurrentRequests" -ForegroundColor White
Write-Host ""

if ($successfulRequests.Count -gt 0) {
    $avgDuration = ($successfulRequests | Measure-Object -Property Duration -Average).Average
    $minDuration = ($successfulRequests | Measure-Object -Property Duration -Minimum).Minimum
    $maxDuration = ($successfulRequests | Measure-Object -Property Duration -Maximum).Maximum
    
    Write-Host "Tiempos de Respuesta:" -ForegroundColor Cyan
    Write-Host "  - Promedio: $([math]::Round($avgDuration, 2))s" -ForegroundColor White
    Write-Host "  - Minimo: $([math]::Round($minDuration, 2))s" -ForegroundColor White
    Write-Host "  - Maximo: $([math]::Round($maxDuration, 2))s" -ForegroundColor White
}

Write-Host ""
Write-Host "Revisa los logs del servidor para mas detalles" -ForegroundColor Blue