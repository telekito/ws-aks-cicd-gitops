param(
  [Parameter(Mandatory = $false)]
  [string]$Namespace = 'aks-workshop',

  [Parameter(Mandatory = $false)]
  [string]$ImageTag = 'latest',

  [Parameter(Mandatory = $false)]
  [string]$AcrName = '<ACR_NAME>'
)

if ($AcrName -eq '<ACR_NAME>') {
  Write-Host "ERROR: reemplaza <ACR_NAME> con el nombre real de tu Container Registry"
  exit 1
}

$workshopApp = Join-Path $PSScriptRoot '..\..\workshop-app\k8s'

Write-Host "Desplegando en namespace $Namespace con imagen tag $ImageTag"

kubectl apply -f (Join-Path $workshopApp 'namespace.yaml')
kubectl apply -f (Join-Path $workshopApp 'configmap.yaml')
kubectl apply -f (Join-Path $workshopApp 'service.yaml')
kubectl apply -f (Join-Path $workshopApp 'deployment.yaml')

# Reemplazar el placeholder de ACR en el deployment
$deployment = kubectl get deployment workshop-app -n $Namespace -o yaml | ConvertFrom-Json
$image = "$AcrName.azurecr.io/workshop-app:$ImageTag"
kubectl set image deployment/workshop-app workshop-app=$image -n $Namespace --record

Write-Host "Esperando a que el Deployment esté listo..."
kubectl rollout status deployment/workshop-app -n $Namespace

Write-Host "Validación final:"
kubectl get all -n $Namespace
