param(
  [string]$Namespace = 'argocd'
)

Write-Host "Obteniendo contraseña admin de Argo CD..."
$encoded = kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>$null

if ([string]::IsNullOrWhiteSpace($encoded)) {
  Write-Host "[ERROR] No se encontró argocd-initial-admin-secret en namespace $Namespace" -ForegroundColor Red
  exit 1
}

$password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
$externalIp = kubectl get svc argocd-server -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
$externalHost = kubectl get svc argocd-server -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

Write-Host ""
Write-Host "Usuario: admin"
Write-Host "Password: $password" -ForegroundColor Yellow
Write-Host ""

if (-not [string]::IsNullOrWhiteSpace($externalIp)) {
  Write-Host "URL pública: https://$externalIp" -ForegroundColor Cyan
}
elseif (-not [string]::IsNullOrWhiteSpace($externalHost)) {
  Write-Host "URL pública: https://$externalHost" -ForegroundColor Cyan
}
else {
  Write-Host "Aún no hay IP pública asignada. Usa temporalmente:"
  Write-Host "  kubectl port-forward svc/argocd-server -n $Namespace 8080:443"
  Write-Host "  https://localhost:8080"
}
