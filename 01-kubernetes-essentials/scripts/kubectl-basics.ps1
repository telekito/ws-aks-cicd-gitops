param(
  [string]$Namespace = 'aks-workshop'
)

Write-Host 'Current context:'
kubectl config current-context

Write-Host "`nNamespaces:"
kubectl get namespace

Write-Host "`nWorkload overview:"
kubectl get pods -n $Namespace
kubectl get deploy -n $Namespace
kubectl get svc -n $Namespace
