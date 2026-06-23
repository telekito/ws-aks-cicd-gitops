param(
  [string]$Namespace = 'argocd'
)

Write-Host 'Admin password:'
$encoded = kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
Write-Host "`n`nPort forward command: kubectl port-forward svc/argocd-server -n $Namespace 8080:443"
