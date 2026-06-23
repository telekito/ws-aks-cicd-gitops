param(
  [string]$Namespace = 'argocd'
)

Write-Host 'Admin password:'
kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
Write-Host "\n\nPort forward command: kubectl port-forward svc/argocd-server -n $Namespace 8080:443"
