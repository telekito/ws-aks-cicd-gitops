param(
  [Parameter(Mandatory = $false)]
  [string]$ConfigFile = '../../00-setup/workshop-config.json',
  
  [Parameter(Mandatory = $false)]
  [string]$Namespace = 'aks-workshop'
)

Write-Host "================================================"
Write-Host "Workshop App - Deploy to AKS"
Write-Host "================================================"
Write-Host ""

# Validar que kubectl está disponible
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  Write-Host "❌ kubectl no está disponible" -ForegroundColor Red
  Write-Host "   Instala kubectl o ejecuta connect-aks.ps1 primero"
  exit 1
}

# Cargar configuración
$configPath = Resolve-Path $ConfigFile -ErrorAction SilentlyContinue
if (-not $configPath) {
  Write-Host "❌ Archivo de configuración no encontrado: $ConfigFile" -ForegroundColor Red
  Write-Host "   Ejecuta primero: cd ../../00-setup && .\deploy-infrastructure.ps1"
  exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json
Write-Host "✅ Configuración cargada desde: $configPath"
Write-Host "   ACR: $($config.acrName).azurecr.io"
Write-Host ""

# Crear namespace si no existe
Write-Host "Verificando namespace '$Namespace'..."
$nsExists = kubectl get namespace $Namespace -o json 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Creando namespace '$Namespace'..."
  kubectl create namespace $Namespace
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error creando namespace" -ForegroundColor Red
    exit 1
  }
}
Write-Host "✅ Namespace '$Namespace' listo"
Write-Host ""

# Rutas de manifests
$manifestDir = "../../workshop-app/k8s"
$tempDir = $env:TEMP + "\workshop-deploy-" + (Get-Random)
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
  Write-Host "Generando manifests con valores reales..."
  
  # Archivos a procesar
  $manifestFiles = @('namespace.yaml', 'configmap.yaml', 'deployment.yaml', 'service.yaml', 'ingress.yaml')
  
  foreach ($file in $manifestFiles) {
    $srcPath = Join-Path $manifestDir $file
    $destPath = Join-Path $tempDir $file
    
    if (-not (Test-Path $srcPath)) {
      Write-Host "⚠️  Archivo no encontrado: $file (saltando)"
      continue
    }
    
    # Leer y reemplazar placeholders
    $content = Get-Content $srcPath -Raw
    $content = $content -replace '<ACR_NAME>', $config.acrName
    $content = $content -replace '<AKS_RESOURCE_GROUP>', $config.resourceGroup
    $content = $content -replace '<AKS_CLUSTER_NAME>', $config.aksClusterName
    
    # Guardar en temporal
    $content | Out-File -FilePath $destPath -Encoding UTF8
    Write-Host "  ✓ $file"
  }
  
  Write-Host ""
  Write-Host "Aplicando manifests a Kubernetes..."
  Write-Host ""
  
  # Aplicar manifests
  kubectl apply -f $tempDir -n $Namespace
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error aplicando manifests" -ForegroundColor Red
    exit 1
  }
  
  Write-Host ""
  Write-Host "================================================"
  Write-Host "✅ Aplicación desplegada exitosamente"
  Write-Host "================================================"
  Write-Host ""
  Write-Host "Estado del despliegue:"
  kubectl get deployments -n $Namespace
  Write-Host ""
  Write-Host "Pods:"
  kubectl get pods -n $Namespace
  Write-Host ""
  Write-Host "Servicios:"
  kubectl get services -n $Namespace
  Write-Host ""
  Write-Host "Para ver los logs:"
  Write-Host "  kubectl logs -n $Namespace -l app=workshop-app"
  Write-Host ""
  Write-Host "Para acceder a la aplicación:"
  Write-Host "  kubectl port-forward -n $Namespace svc/workshop-app 3000:3000"
  Write-Host "  Luego abre: http://localhost:3000"
  Write-Host ""
}
finally {
  # Limpiar
  Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
