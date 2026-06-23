
# Script para automatizar el reemplazo de placeholders después del despliegue

param(
  [Parameter(Mandatory = $false)]
  [string]$ConfigFile = 'workshop-config.json'
)

Write-Host "================================================"
Write-Host "Workshop Configuration Helper"
Write-Host "================================================"
Write-Host ""

# Cargar configuración
if (-not (Test-Path $ConfigFile)) {
  Write-Host "❌ Archivo de configuración no encontrado: $ConfigFile" -ForegroundColor Red
  Write-Host "   Ejecuta primero: .\deploy-infrastructure.ps1"
  exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json
Write-Host "Configuración cargada desde: $ConfigFile"
Write-Host ""

# Mostrar valores
Write-Host "Valores detectados:"
Write-Host "  Grupo de recursos: $($config.resourceGroup)"
Write-Host "  Clúster AKS: $($config.aksClusterName)"
Write-Host "  ACR: $($config.acrName)"
Write-Host "  Ubicación: $($config.location)"
Write-Host ""

# Mapeo de placeholders
$placeholders = @{
  '<AKS_RESOURCE_GROUP>' = $config.resourceGroup
  '<AKS_CLUSTER_NAME>' = $config.aksClusterName
  '<ACR_NAME>' = $config.acrName
}

Write-Host "Placeholders a reemplazar:"
foreach ($placeholder in $placeholders.GetEnumerator()) {
  Write-Host "  $($placeholder.Key) → $($placeholder.Value)"
}
Write-Host ""

# Archivos a procesar
$filesToProcess = @(
  '..\01-kubernetes-essentials\README.md'
  '..\02-azure-devops-cicd\README.md'
  '..\02-azure-devops-cicd\azure-pipelines.yml'
  '..\03-gitops-argocd\README.md'
  '..\03-gitops-argocd\manifests\application.yaml'
  '..\04-operacion-aks\README.md'
  '..\workshop-app\k8s\deployment.yaml'
  '..\workshop-app\k8s\ingress.yaml'
)

Write-Host "Buscando archivos a actualizar..."
$foundFiles = @()
$missingFiles = @()

foreach ($file in $filesToProcess) {
  $fullPath = Join-Path $PSScriptRoot $file
  if (Test-Path $fullPath) {
    $foundFiles += $fullPath
  }
  else {
    $missingFiles += $file
  }
}

Write-Host "✅ Archivos encontrados: $($foundFiles.Count)"
if ($missingFiles.Count -gt 0) {
  Write-Host "⚠️  Archivos no encontrados: $($missingFiles.Count)" -ForegroundColor Yellow
}
Write-Host ""

# Opción de preview o apply
Write-Host "Opciones:"
Write-Host "  1. Ver cambios que se harían (preview)"
Write-Host "  2. Aplicar cambios"
Write-Host "  3. Salir"
$choice = Read-Host "Selecciona opción (1-3)"

switch ($choice) {
  "1" {
    Write-Host ""
    Write-Host "Preview de cambios:"
    foreach ($file in $foundFiles) {
      $content = Get-Content $file -Raw
      $hasChanges = $false
      
      foreach ($placeholder in $placeholders.GetEnumerator()) {
        if ($content -contains $placeholder.Key) {
          $hasChanges = $true
          Write-Host ""
          Write-Host "Archivo: $(Split-Path $file -Leaf)"
          Write-Host "  Reemplazar: $($placeholder.Key)"
          Write-Host "  Por: $($placeholder.Value)"
        }
      }
    }
    Write-Host ""
    Write-Host "Para aplicar, ejecuta: .\update-placeholders.ps1 -Apply"
  }
  
  "2" {
    Write-Host ""
    Write-Host "⏳ Aplicando cambios..."
    $filesModified = 0
    
    foreach ($file in $foundFiles) {
      $content = Get-Content $file -Raw
      $originalContent = $content
      
      foreach ($placeholder in $placeholders.GetEnumerator()) {
        $content = $content -replace [regex]::Escape($placeholder.Key), $placeholder.Value
      }
      
      if ($content -ne $originalContent) {
        Set-Content $file $content -Encoding UTF8
        Write-Host "✅ Actualizado: $(Split-Path $file -Leaf)"
        $filesModified++
      }
    }
    
    Write-Host ""
    Write-Host "✅ Cambios aplicados a $filesModified archivos"
    Write-Host ""
    Write-Host "Próximos pasos:"
    Write-Host "  1. Si usas Git, haz commit de los cambios"
    Write-Host "  2. Verifica los valores en los archivos críticos"
    Write-Host "  3. Comienza con el módulo 1 del workshop"
  }
  
  "3" {
    Write-Host "Operación cancelada"
    exit 0
  }
  
  default {
    Write-Host "Opción inválida"
    exit 1
  }
}

Write-Host ""
Write-Host "Para más información, consulta README.md"
