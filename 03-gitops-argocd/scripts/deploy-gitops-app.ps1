param(
  [string]$Namespace = 'argocd',
  [string]$ApplicationName = 'workshop-app',
  [string]$ManifestPath = (Join-Path $PSScriptRoot '..\manifests\application.yaml'),
  [string]$GitRepositoryUrl,
  [int]$TimeoutMinutes = 10
)

if (-not (Test-Path $ManifestPath)) {
  Write-Host "[ERROR] No se encontró el manifiesto: $ManifestPath" -ForegroundColor Red
  exit 1
}

$content = Get-Content $ManifestPath -Raw

if ($content -match '<GIT_REPOSITORY_URL>') {
  if ([string]::IsNullOrWhiteSpace($GitRepositoryUrl)) {
    Write-Host "[ERROR] El manifiesto contiene <GIT_REPOSITORY_URL>. Usa -GitRepositoryUrl para reemplazarlo." -ForegroundColor Red
    exit 1
  }

  $content = $content -replace [regex]::Escape('<GIT_REPOSITORY_URL>'), $GitRepositoryUrl
}

$tempFile = Join-Path $env:TEMP "argocd-app-$ApplicationName.yaml"
Set-Content -Path $tempFile -Value $content -Encoding UTF8

Write-Host "Aplicando Application de Argo CD..."
kubectl apply -n $Namespace -f $tempFile
if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] No se pudo aplicar la Application." -ForegroundColor Red
  exit 1
}

Write-Host "Esperando a que la Application esté Synced/Healthy..."
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)

while ((Get-Date) -lt $deadline) {
  $syncStatus = kubectl get application $ApplicationName -n $Namespace -o jsonpath='{.status.sync.status}' 2>$null
  $healthStatus = kubectl get application $ApplicationName -n $Namespace -o jsonpath='{.status.health.status}' 2>$null

  if ($syncStatus -eq 'Synced' -and $healthStatus -eq 'Healthy') {
    Write-Host "[OK] Application sincronizada y saludable." -ForegroundColor Green
    kubectl get application $ApplicationName -n $Namespace
    kubectl get all -n aks-workshop-argo
    exit 0
  }

  Write-Host "  Sync=$syncStatus | Health=$healthStatus"
  Start-Sleep -Seconds 10
}

Write-Host "[WARNING] Timeout esperando Synced/Healthy." -ForegroundColor Yellow
kubectl describe application $ApplicationName -n $Namespace
exit 1
