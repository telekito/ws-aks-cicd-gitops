param(
  [string]$Namespace = 'aks-workshop'
)

Write-Host 'Cluster nodes:'
kubectl get nodes -o wide

Write-Host "`nWorkloads:"
kubectl get all -n $Namespace

Write-Host "`nEvents:"
kubectl get events -n $Namespace --sort-by=.metadata.creationTimestamp
