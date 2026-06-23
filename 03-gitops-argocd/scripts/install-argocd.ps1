param(
  [string]$Namespace = 'argocd',
  [int]$TimeoutMinutes = 10
)

Write-Host "Creando namespace de Argo CD (si no existe)..."
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] No se pudo crear/aplicar el namespace $Namespace" -ForegroundColor Red
  exit 1
}

Write-Host "Instalando Argo CD..."
kubectl apply -n $Namespace -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] Falló la instalación de Argo CD" -ForegroundColor Red
  exit 1
}

Write-Host "Esperando disponibilidad de argocd-server..."
kubectl wait --for=condition=Available deployment/argocd-server -n $Namespace --timeout=10m
if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] argocd-server no llegó a estado Available" -ForegroundColor Red
  exit 1
}

Write-Host "Configurando servicio público (LoadBalancer)..."
kubectl patch svc argocd-server -n $Namespace -p '{"spec":{"type":"LoadBalancer"}}'
if ($LASTEXITCODE -ne 0) {
  Write-Host "[ERROR] No se pudo configurar argocd-server como LoadBalancer" -ForegroundColor Red
  exit 1
}

Write-Host "Esperando IP pública del servicio..."
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$externalIp = $null
$externalHost = $null

while ((Get-Date) -lt $deadline) {
  $externalIp = kubectl get svc argocd-server -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
  $externalHost = kubectl get svc argocd-server -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

  if (-not [string]::IsNullOrWhiteSpace($externalIp) -or -not [string]::IsNullOrWhiteSpace($externalHost)) {
    break
  }

  Start-Sleep -Seconds 10
}

Write-Host ""
Write-Host "[OK] Argo CD instalado." -ForegroundColor Green
kubectl get svc argocd-server -n $Namespace -o wide

if (-not [string]::IsNullOrWhiteSpace($externalIp)) {
  Write-Host "URL pública: https://$externalIp" -ForegroundColor Cyan
}
elseif (-not [string]::IsNullOrWhiteSpace($externalHost)) {
  Write-Host "URL pública: https://$externalHost" -ForegroundColor Cyan
}
else {
  Write-Host "[WARNING] Aún no hay IP pública asignada. Reintenta:" -ForegroundColor Yellow
  Write-Host "  kubectl get svc argocd-server -n $Namespace -w"
}
