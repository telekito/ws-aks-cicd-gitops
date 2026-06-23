
# Script para eliminar todos los recursos de Azure creados por el workshop

param(
  [Parameter(Mandatory = $false)]
  [string]$ConfigFile = 'workshop-config.json',
  
  [Parameter(Mandatory = $false)]
  [switch]$Force  # Skip confirmation prompts
)

Write-Host "================================================"
Write-Host "Workshop Cleanup - Eliminar recursos de Azure"
Write-Host "================================================"
Write-Host ""

# Validar que estamos autenticados en Azure
try {
  $account = az account show 2>$null | ConvertFrom-Json
  if (-not $account) {
    throw "No autenticado"
  }
  Write-Host "[OK] Autenticado como: $($account.user.name)"
  Write-Host "     Suscripcion: $($account.name) ($($account.id))"
}
catch {
  Write-Host "[ERROR] No estas autenticado en Azure" -ForegroundColor Red
  Write-Host "        Ejecuta: az login"
  exit 1
}

Write-Host ""

# Cargar configuración del workshop si existe
$resourceGroup = $null

if (Test-Path $ConfigFile) {
  Write-Host "Leyendo configuración de: $ConfigFile"
  $config = Get-Content $ConfigFile | ConvertFrom-Json
  $resourceGroup = $config.resourceGroup
  Write-Host "  Grupo de recursos: $resourceGroup"
  Write-Host ""
}
else {
  Write-Host "[WARNING] No se encontro $ConfigFile"
  Write-Host "          Deberas especificar el nombre del grupo de recursos"
  Write-Host ""
}

# Si no tenemos el RG del config, pedirlo al usuario
if (-not $resourceGroup) {
  Write-Host "Grupos de recursos disponibles:"
  $rgs = az group list --query "[].name" -o tsv
  
  if (-not $rgs) {
    Write-Host "[ERROR] No hay grupos de recursos en esta suscripcion"
    exit 0
  }
  
  $rgs | ForEach-Object { Write-Host "  - $_" }
  Write-Host ""
  
  $resourceGroup = Read-Host "Nombre del grupo de recursos a eliminar"
  
  if (-not $resourceGroup) {
    Write-Host "[ERROR] Debes especificar un grupo de recursos"
    exit 1
  }
}

Write-Host ""

# Verificar que el grupo existe
Write-Host "Verificando grupo de recursos..."
$rgExists = az group exists --name $resourceGroup 2>$null | ConvertFrom-Json

if (-not $rgExists) {
  Write-Host "[ERROR] El grupo de recursos '$resourceGroup' no existe o ya fue eliminado"
  exit 0
}

Write-Host "[OK] Grupo de recursos encontrado: $resourceGroup"
Write-Host ""

# Listar recursos que se van a eliminar
Write-Host "Recursos en el grupo de recursos:"
Write-Host ""

$resources = az resource list --resource-group $resourceGroup --query "[].{Type: type, Name: name}" -o json | ConvertFrom-Json

if ($resources.Count -eq 0) {
  Write-Host "El grupo de recursos esta vacio"
  Write-Host ""
}
else {
  $resources | ForEach-Object {
    $type = $_.Type -split "/" | Select-Object -Last 1
    Write-Host "  [$type] $($_.Name)"
  }
  Write-Host ""
}

# Pedir confirmación (a menos que use -Force)
Write-Host "[WARNING] Esto eliminara TODOS los recursos en '$resourceGroup'"
Write-Host ""

if (-not $Force) {
  $confirm = Read-Host "Estas seguro? Escribe SI para confirmar"
  
  if ($confirm -ne "SI") {
    Write-Host "[CANCELLED] Operacion cancelada"
    exit 0
  }
}

Write-Host ""
Write-Host "[PROGRESS] Eliminando grupo de recursos '$resourceGroup'..."
Write-Host ""

try {
  az group delete --name $resourceGroup --yes --no-wait
  
  Write-Host "[OK] Se inicio la eliminacion del grupo de recursos"
  Write-Host ""
  Write-Host "[INFO] Esto puede tardar 5-10 minutos en completarse"
  Write-Host "       Puedes monitorear el progreso en Azure Portal"
  Write-Host ""
  Write-Host "Para verificar el estado:"
  Write-Host "  az group show --name $resourceGroup"
  Write-Host ""
  
  # Ofrecer monitoreo en tiempo real
  $monitor = Read-Host "Deseas monitorear el progreso? (s/n)"
  
  if ($monitor -eq "s" -or $monitor -eq "S") {
    Write-Host ""
    Write-Host "Monitoreando eliminación..."
    
    $maxWait = 600  # 10 minutos
    $elapsed = 0
    $interval = 10
    
    while ($elapsed -lt $maxWait) {
      $rgExists = az group exists --name $resourceGroup 2>$null | ConvertFrom-Json
      
      if (-not $rgExists) {
        Write-Host ""
        Write-Host "[OK] Grupo de recursos eliminado completamente"
        break
      }
      
      $percent = [int](($elapsed / $maxWait) * 100)
      Write-Host -NoNewline "`r[$([Math]::Round($elapsed/60, 1))m] Eliminando... ($percent`%)"
      
      Start-Sleep $interval
      $elapsed += $interval
    }
    
    if ($rgExists) {
      Write-Host ""
      Write-Host "[WARNING] La eliminacion sigue en progreso en Azure"
      Write-Host "          Revisa Azure Portal para mas detalles"
    }
  }
}
catch {
  Write-Host "[ERROR] Error al eliminar el grupo de recursos: $_" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "================================================"
Write-Host "Limpieza completada"
Write-Host "================================================"
Write-Host ""
Write-Host "Proximos pasos:"
Write-Host "  1. Puedes volver a ejecutar deploy-infrastructure.ps1 para un nuevo workshop"
Write-Host "  2. O eliminar la carpeta local del workshop"
Write-Host ""
