#!/usr/bin/env pwsh

# Script para desplegar la infraestructura completa de AKS en Azure

param(
  [Parameter(Mandatory = $false)]
  [string]$SubscriptionId,
  
  [Parameter(Mandatory = $false)]
  [string]$ResourceGroup,
  
  [Parameter(Mandatory = $false)]
  [string]$Location = 'eastus',
  
  [Parameter(Mandatory = $false)]
  [string]$AksClusterName,
  
  [Parameter(Mandatory = $false)]
  [string]$AcrName,
  
  [Parameter(Mandatory = $false)]
  [string]$NodeCount = 2,
  
  [Parameter(Mandatory = $false)]
  [string]$VmSize = 'Standard_B2s',
  
  [switch]$SkipValidation
)

Write-Host "================================================"
Write-Host "AKS Workshop - Infrastructure Deployment"
Write-Host "================================================"
Write-Host ""

# Validar herramientas requeridas
Write-Host "Validando herramientas requeridas..."
$requiredTools = @('az', 'kubectl')
$missingTools = @()

foreach ($tool in $requiredTools) {
  if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
    $missingTools += $tool
  }
}

if ($missingTools.Count -gt 0) {
  Write-Host "❌ Faltan herramientas requeridas: $($missingTools -join ', ')" -ForegroundColor Red
  Write-Host "   Ejecuta primero: .\install-prerequisites.ps1"
  exit 1
}
Write-Host "✅ Todas las herramientas requeridas están disponibles"
Write-Host ""

# Autenticación en Azure
Write-Host "Validando autenticación en Azure..."
$currentAccount = az account show --output json 2>$null | ConvertFrom-Json
if (-not $currentAccount) {
  Write-Host "❌ No estás autenticado en Azure"
  Write-Host "   Ejecuta: az login"
  exit 1
}
Write-Host "✅ Autenticado como: $($currentAccount.user.name)"
Write-Host ""

# Seleccionar suscripción
if ($SubscriptionId) {
  az account set --subscription $SubscriptionId
}
else {
  $accounts = az account list --output json | ConvertFrom-Json
  if ($accounts.Count -eq 1) {
    $SubscriptionId = $accounts[0].id
    Write-Host "Usando suscripción: $($accounts[0].name)"
  }
  elseif ($accounts.Count -gt 1) {
    Write-Host "Selecciona una suscripción:"
    for ($i = 0; $i -lt $accounts.Count; $i++) {
      Write-Host "$($i + 1). $($accounts[$i].name) ($($accounts[$i].id))"
    }
    $selection = Read-Host "Número de suscripción (1-$($accounts.Count))"
    $SubscriptionId = $accounts[$selection - 1].id
    az account set --subscription $SubscriptionId
  }
}
Write-Host ""

# Parámetros interactivos si no están definidos
while (-not $ResourceGroup) {
  $ResourceGroup = (Read-Host "Nombre del grupo de recursos (ej: aks-workshop-rg)").Trim()
  if (-not $ResourceGroup) { Write-Host "⚠️  El nombre del grupo de recursos es obligatorio" -ForegroundColor Yellow }
}

while (-not $AksClusterName) {
  $AksClusterName = (Read-Host "Nombre del clúster AKS (ej: aks-workshop)").Trim()
  if (-not $AksClusterName) { Write-Host "⚠️  El nombre del clúster AKS es obligatorio" -ForegroundColor Yellow }
}

while (-not $AcrName) {
  $AcrName = (Read-Host "Nombre del ACR sin .azurecr.io (ej: aksworkshoproeg)").Trim()
  if (-not $AcrName) { Write-Host "⚠️  El nombre del ACR es obligatorio" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "================================================"
Write-Host "Parámetros de despliegue"
Write-Host "================================================"
Write-Host "Grupo de recursos: $ResourceGroup"
Write-Host "Ubicación: $Location"
Write-Host "Clúster AKS: $AksClusterName"
Write-Host "ACR: $AcrName.azurecr.io"
Write-Host "Nodos: $NodeCount"
Write-Host "VM Size: $VmSize"
Write-Host ""

$confirm = Read-Host "¿Desplegar con estos parámetros? (s/n)"
if ($confirm -ne 's' -and $confirm -ne 'S') {
  Write-Host "Despliegue cancelado"
  exit 0
}

# Crear grupo de recursos
Write-Host ""
Write-Host "Creando grupo de recursos..."
az group create `
  --name $ResourceGroup `
  --location $Location `
  --output none
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Error creando grupo de recursos" -ForegroundColor Red
  exit 1
}
Write-Host "✅ Grupo de recursos creado"

# Crear ACR
Write-Host ""
Write-Host "Creando Azure Container Registry..."
az acr create `
  --resource-group $ResourceGroup `
  --name $AcrName `
  --sku Basic `
  --output none
if ($LASTEXITCODE -ne 0) {
  Write-Host "⚠️  Error creando ACR (puede que ya exista o el nombre no esté disponible)" -ForegroundColor Yellow
} else {
  Write-Host "✅ ACR creado: $AcrName.azurecr.io"
}

# Crear AKS
Write-Host ""
Write-Host "Creando clúster AKS (esto puede tomar 5-10 minutos)..."
$startTime = Get-Date

az aks create `
  --resource-group $ResourceGroup `
  --name $AksClusterName `
  --node-count $NodeCount `
  --vm-set-type VirtualMachineScaleSets `
  --load-balancer-sku standard `
  --enable-managed-identity `
  --network-plugin azure `
  --enable-addons monitoring `
  --enable-app-routing `
  --node-vm-size $VmSize `
  --attach-acr $AcrName `
  --output none

if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Error creando AKS" -ForegroundColor Red
  exit 1
}
$duration = (Get-Date) - $startTime
Write-Host "✅ Clúster AKS creado en $([math]::Round($duration.TotalMinutes, 1))m"

# Obtener credenciales
Write-Host ""
Write-Host "Obteniendo credenciales de kubectl..."
az aks get-credentials `
  --resource-group $ResourceGroup `
  --name $AksClusterName `
  --overwrite-existing `
  --output none
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Error obteniendo credenciales" -ForegroundColor Red
  exit 1
}
Write-Host "✅ Credenciales configuradas"

# Verificar conexión
Write-Host ""
Write-Host "Verificando conexión al clúster..."
$nodesJson = kubectl get nodes -o json 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "⚠️  No se pudo verificar conexión al clúster" -ForegroundColor Yellow
} else {
  $nodes = $nodesJson | ConvertFrom-Json
  Write-Host "✅ Conectado al clúster"
  Write-Host "   Nodos disponibles: $($nodes.items.Count)"
  foreach ($node in $nodes.items) {
    $ready = $node.status.conditions | Where-Object { $_.type -eq 'Ready' } | Select-Object -ExpandProperty status
    Write-Host "   - $($node.metadata.name): $ready"
  }
}

# Resumen final
Write-Host ""
Write-Host "================================================"
Write-Host "✅ Despliegue completado"
Write-Host "================================================"
Write-Host ""
Write-Host "Información importante:"
Write-Host "  Grupo de recursos: $ResourceGroup"
Write-Host "  Clúster AKS: $AksClusterName"
Write-Host "  ACR: $AcrName.azurecr.io"
Write-Host "  Ubicación: $Location"
Write-Host ""
Write-Host "Próximos pasos:"
Write-Host "  1. Guardar estos valores en tu sesión de terminal"
Write-Host "  2. Crear repositorio Git para GitOps"
Write-Host "  3. Configurar Azure DevOps (opcional)"
Write-Host ""
Write-Host "Ejemplo de cómo guardar en variables:"
Write-Host "  `$ResourceGroup = '$ResourceGroup'"
Write-Host "  `$AksClusterName = '$AksClusterName'"
Write-Host "  `$AcrName = '$AcrName'"
Write-Host ""
Write-Host "Reemplaza estos valores en todos los scripts del workshop"
Write-Host ""
Write-Host "Para comenzar el workshop, ejecuta:"
Write-Host "  cd ../01-kubernetes-essentials"
Write-Host ""

# Guardar valores en archivo de configuración
$configFile = "workshop-config.json"
$config = @{
  resourceGroup = $ResourceGroup
  aksClusterName = $AksClusterName
  acrName = $AcrName
  location = $Location
  subscriptionId = $SubscriptionId
  deploymentDate = Get-Date -Format 'o'
}

$config | ConvertTo-Json | Out-File $configFile -Encoding UTF8
Write-Host "Configuración guardada en: $configFile"
