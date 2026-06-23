param(
  [string]$Namespace = 'aks-workshop',
  [string]$PodName
)

if (-not $PodName) {
  # Obtener lista de pods en el namespace
  $podsJson = kubectl get pods -n $Namespace -o json 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error obteniendo pods del namespace '$Namespace'" -ForegroundColor Red
    exit 1
  }
  
  $pods = $podsJson | ConvertFrom-Json
  if ($pods.items.Count -eq 0) {
    Write-Host "❌ No hay pods en el namespace '$Namespace'" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pods disponibles en otros namespaces:"
    kubectl get pods --all-namespaces
    exit 1
  }
  
  $PodName = $pods.items[0].metadata.name
  Write-Host "✅ Pod seleccionado: $PodName"
}

Write-Host "Inspeccionando pod $PodName en namespace $Namespace"
kubectl describe pod $PodName -n $Namespace
Write-Host "`nLogs:"
kubectl logs $PodName -n $Namespace
