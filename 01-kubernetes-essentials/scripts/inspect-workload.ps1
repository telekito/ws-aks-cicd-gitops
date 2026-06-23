param(
  [string]$Namespace = 'aks-workshop',
  [string]$PodName
)

if (-not $PodName) {
  $PodName = kubectl get pods -n $Namespace -o jsonpath='{.items[0].metadata.name}'
}

Write-Host "Inspecting pod $PodName in namespace $Namespace"
kubectl describe pod $PodName -n $Namespace
Write-Host "\nLogs:"
kubectl logs $PodName -n $Namespace
