param(
  [Parameter(Mandatory = $true)]
  [string]$NewTag
)

$manifest = Join-Path $PSScriptRoot '..\..\workshop-app\k8s\deployment.yaml'
(Get-Content $manifest) -replace '<ACR_NAME>\.azurecr\.io/workshop-app:latest', "<ACR_NAME>.azurecr.io/workshop-app:$NewTag" | Set-Content $manifest
Write-Host "Updated deployment image tag to $NewTag"
