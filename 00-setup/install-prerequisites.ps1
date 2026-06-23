
# Instalación automática de prerequisitos con winget

param(
  [switch]$SkipDocker,
  [switch]$SkipPowerShellCore
)

$tools = @(
  @{ Name = 'Azure CLI'; WingetId = 'Microsoft.AzureCLI'; Command = 'az'; Version = 'az --version' }
  @{ Name = 'Git'; WingetId = 'Git.Git'; Command = 'git'; Version = 'git --version' }
)

if (-not $SkipDocker) {
  $tools += @{ Name = 'Docker Desktop'; WingetId = 'Docker.DockerDesktop'; Command = 'docker'; Version = 'docker --version' }
}

if (-not $SkipPowerShellCore) {
  $tools += @{ Name = 'PowerShell Core'; WingetId = 'Microsoft.PowerShell'; Command = 'pwsh'; Version = 'pwsh -NoProfile -Command { $PSVersionTable.PSVersion }' }
}

Write-Host "================================================"
Write-Host "AKS Workshop - Prerequisites Installation"
Write-Host "================================================"

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $isAdmin) {
  Write-Host "⚠️  Este script debe ejecutarse como administrador" -ForegroundColor Yellow
  Write-Host "Por favor, abre PowerShell como administrador e intenta de nuevo"
  exit 1
}

# Check winget availability
Write-Host "`nValidando winget..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "❌ winget no encontrado"
  Write-Host "Descárgalo desde: https://github.com/microsoft/winget-cli/releases"
  exit 1
}
Write-Host "✅ winget disponible"

# Validar requisitos previos para Docker
if (-not $SkipDocker) {
  Write-Host "`n--- Validando requisitos previos para Docker ---"
  
  # Verificar si Hyper-V está habilitado
  $hyperVEnabled = (Get-WindowsOptionalFeature -Online -FeatureName Hyper-V -ErrorAction SilentlyContinue).State -eq 'Enabled'
  if (-not $hyperVEnabled) {
    Write-Host "⚠️  Hyper-V no está habilitado" -ForegroundColor Yellow
    Write-Host "   Docker Desktop requiere Hyper-V. Habilitándolo..."
    try {
      Enable-WindowsOptionalFeature -Online -FeatureName Hyper-V -All -NoRestart
      Write-Host "   ⚠️  Hyper-V se ha habilitado. REINICIA tu PC después de completar la instalación."
    }
    catch {
      Write-Host "   ❌ No se pudo habilitar Hyper-V automáticamente" -ForegroundColor Red
      Write-Host "   Habilítalo manualmente en 'Panel de Control > Programas > Activar o desactivar características de Windows'"
    }
  }
  else {
    Write-Host "✅ Hyper-V está habilitado"
  }
}

# Install/verify each tool
$installedCount = 0
$failedCount = 0

foreach ($tool in $tools) {
  Write-Host "`n--- $($tool.Name) ---"
  
  if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
    Write-Host "✅ $($tool.Name) ya está instalado"
    $installedCount++
    Invoke-Expression $tool.Version
  }
  else {
    Write-Host "⏳ Instalando $($tool.Name)..."
    try {
      winget install $tool.WingetId --accept-source-agreements -h
      
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
      
      # Para Docker Desktop, esperar un poco más
      if ($tool.Name -eq 'Docker Desktop') {
        Write-Host "   Esperando que Docker se inicialice..."
        Start-Sleep -Seconds 5
      }
      
      # Verify installation
      if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
        Write-Host "✅ $($tool.Name) instalado correctamente"
        $installedCount++
        if ($tool.Name -eq 'Docker Desktop') {
          Write-Host "   ⚠️  Docker Desktop requiere un REINICIO de la máquina para funcionar correctamente"
        }
        Invoke-Expression $tool.Version
      }
      else {
        Write-Host "⚠️  $($tool.Name) se instaló pero no está accesible en PATH" -ForegroundColor Yellow
        if ($tool.Name -eq 'Docker Desktop') {
          Write-Host "   Esto es normal. Docker Desktop requiere un REINICIO para completar la instalación"
          Write-Host "   Reinicia la máquina y vuelve a ejecutar este script"
        }
      }
    }
    catch {
      Write-Host "❌ Error instalando $($tool.Name): $_" -ForegroundColor Red
      if ($tool.Name -eq 'Docker Desktop') {
        Write-Host "   Instálalo manualmente desde: https://www.docker.com/products/docker-desktop"
        Write-Host "   Asegúrate de que Hyper-V esté habilitado antes de instalar"
      }
      $failedCount++
    }
  }
}

# Instalar kubectl con Azure CLI (recomendado)
Write-Host "`n--- kubectl (via Azure CLI) ---"
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
  Write-Host "✅ kubectl ya está instalado"
  $installedCount++
  kubectl version --client
}
else {
  Write-Host "⏳ Instalando kubectl con az aks install-cli..."
  try {
    # Necesita Azure CLI instalado primero
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
      Write-Host "❌ Azure CLI no está disponible. Instálalo primero."
      $failedCount++
    }
    else {
      az aks install-cli
      
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
      
      if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        Write-Host "✅ kubectl instalado correctamente (via Azure CLI)"
        $installedCount++
        kubectl version --client
      }
      else {
        Write-Host "❌ kubectl no se pudo instalar"
        $failedCount++
      }
    }
  }
  catch {
    Write-Host "❌ Error instalando kubectl: $_" -ForegroundColor Red
    $failedCount++
  }
}

Write-Host "`n================================================"
Write-Host "Resumen de instalación"
Write-Host "================================================"
Write-Host "Instalados: $installedCount"
if ($failedCount -gt 0) {
  Write-Host "Fallidos: $failedCount" -ForegroundColor Yellow
}

# Verificar si Docker fue instalado
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
$dockerDesktopInstalled = Test-Path "$env:ProgramFiles\Docker\Docker\Docker.exe"

if (-not $SkipDocker -and ($dockerInstalled -or $dockerDesktopInstalled)) {
  Write-Host "`n⚠️  IMPORTANTE - Docker Desktop instalado" -ForegroundColor Yellow
  Write-Host "Docker Desktop requiere que reinicies tu PC para funcionar correctamente."
  Write-Host ""
  Write-Host "Pasos siguientes:"
  Write-Host "  1. REINICIA tu PC"
  Write-Host "  2. Abre Docker Desktop desde el menú Inicio"
  Write-Host "  3. Verifica con: docker --version"
  Write-Host "  4. Luego ejecuta: .\deploy-infrastructure.ps1"
}
elseif ($failedCount -eq 0) {
  Write-Host "`n✅ Todos los prerequisitos están instalados"
  
  # Final validation
  Write-Host "`nValidación final..."
  Write-Host "Ejecuta los siguientes comandos para verificar:"
  Write-Host "  az --version"
  Write-Host "  kubectl version --client"
  Write-Host "  git --version"
  if (-not $SkipDocker) { Write-Host "  docker --version" }
  
  Write-Host "`n✅ Ahora puedes ejecutar: .\deploy-infrastructure.ps1"
}
else {
  Write-Host "`n⚠️  Algunos tools fallaron en la instalación automática" -ForegroundColor Yellow
  Write-Host "   Instálalos manualmente o corre el script con -SkipDocker -SkipPowerShellCore"
  Write-Host "   Ver README_PREREQUISITES.md para instrucciones"
  exit 1
}
