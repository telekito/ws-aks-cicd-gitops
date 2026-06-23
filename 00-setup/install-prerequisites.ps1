
# Instalación automática de prerequisitos con winget

param(
  [switch]$SkipDocker,
  [switch]$SkipPowerShellCore
)

$tools = @(
  @{ Name = 'Azure CLI'; WingetId = 'Microsoft.AzureCLI'; Command = 'az'; Version = 'az --version' }
  @{ Name = 'Git'; WingetId = 'Git.Git'; Command = 'git'; Version = 'git --version' }
  @{ Name = 'Visual Studio Code'; WingetId = 'Microsoft.VisualStudioCode'; Command = 'code'; Version = 'code --version' }
  @{ Name = 'k9s'; WingetId = 'Derailed.k9s'; Command = 'k9s'; Version = 'k9s version' }
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
Write-Host ""
Write-Host "Este script instalará:"
Write-Host "  • Hyper-V (para Docker Desktop y virtualización)"
Write-Host "  • WSL 2 (Windows Subsystem for Linux)"
Write-Host "  • Docker Desktop"
Write-Host "  • Azure CLI, Git, VS Code, k9s, kubectl, PowerShell Core"
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $isAdmin) {
  Write-Host "⚠️  Este script debe ejecutarse como administrador" -ForegroundColor Yellow
  Write-Host "Por favor, abre PowerShell como administrador e intenta de nuevo"
  exit 1
}

# Validar CPU soporta virtualización
Write-Host "`n--- Validando soporte de virtualización en CPU ---"
try {
  $cpuVirtualization = Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty VirtualizationFirmwareEnabled
  if ($null -eq $cpuVirtualization) {
    Write-Host "⚠️  No se puede determinar si virtualización está habilitada en el BIOS" -ForegroundColor Yellow
    Write-Host "   Verifica en la configuración del BIOS que la virtualización esté habilitada"
    Write-Host "   (VT-x para Intel, AMD-V para AMD)"
  }
  elseif ($cpuVirtualization) {
    Write-Host "✅ Virtualización está habilitada en el CPU"
  }
  else {
    Write-Host "❌ Virtualización NO está habilitada en el BIOS" -ForegroundColor Red
    Write-Host "   Requiere: Reiniciar en BIOS y habilitar VT-x (Intel) o AMD-V (AMD)"
    exit 1
  }
}
catch {
  Write-Host "⚠️  No se pudo validar virtualización del CPU" -ForegroundColor Yellow
}

# Validar Hyper-V es un pre-requisito
Write-Host "`n--- Validando y habilitando Hyper-V (REQUISITO PREVIO) ---"
$hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName Hyper-V -ErrorAction SilentlyContinue
$hyperVEnabled = $hyperVFeature.State -eq 'Enabled'

if ($hyperVEnabled) {
  Write-Host "✅ Hyper-V ya está habilitado"
}
else {
  Write-Host "⏳ Habilitando Hyper-V (necesario para Docker)..."
  try {
    Enable-WindowsOptionalFeature -Online -FeatureName Hyper-V -All -NoRestart
    Write-Host "✅ Hyper-V habilitado exitosamente"
    Write-Host "⚠️  IMPORTANTE: Debes REINICIAR tu PC para completar la activación de Hyper-V"
    $hyperVRebootRequired = $true
  }
  catch {
    Write-Host "❌ Error habilitando Hyper-V: $_" -ForegroundColor Red
    Write-Host "   Intenta habilitarlo manualmente:"
    Write-Host "   Panel de Control > Programas > Activar o desactivar características de Windows"
    Write-Host "   Marca 'Hyper-V' y reinicia"
    exit 1
  }
}

# Check winget availability
Write-Host "`nValidando winget..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "❌ winget no encontrado"
  Write-Host "Descárgalo desde: https://github.com/microsoft/winget-cli/releases"
  exit 1
}
Write-Host "✅ winget disponible"

# Validar que Microsoft Store (msstore) está disponible para winget
Write-Host "`nValidando fuente Microsoft Store (msstore)..."
$wingetSources = winget source list 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "⚠️  No se pudo consultar las fuentes de winget. Intentando reparar..." -ForegroundColor Yellow
  winget source reset --force 2>$null
  $wingetSources = winget source list 2>$null
}

if (-not ($wingetSources | Select-String -Pattern '\bmsstore\b')) {
  Write-Host "⚠️  La fuente 'msstore' no está registrada en winget. Intentando restaurar..." -ForegroundColor Yellow
  winget source reset --force 2>$null
  $wingetSources = winget source list 2>$null
}

if (-not ($wingetSources | Select-String -Pattern '\bmsstore\b')) {
  Write-Host "❌ Microsoft Store no está disponible para winget" -ForegroundColor Red
  Write-Host "   Esto es necesario para instalar paquetes como Docker Desktop/WSL/VS Code"
  Write-Host "   Abre Microsoft Store, actualiza App Installer y vuelve a ejecutar el script"
  Write-Host "   También puedes ejecutar: winget source reset --force"
  exit 1
}
Write-Host "✅ Fuente 'msstore' disponible"

# Instalación de WSL 2 (requerido para Docker en Windows)
Write-Host "`n--- Windows Subsystem for Linux 2 (WSL 2) ---"
$wslInstalled = wsl --list --verbose 2>$null | Select-String "Ubuntu"
if ($wslInstalled) {
  Write-Host "✅ WSL 2 con distribución Linux ya está instalado"
}
else {
  Write-Host "⏳ Instalando WSL 2..."
  try {
    # Habilitar características de Windows requeridas para WSL
    Write-Host "   Habilitando características de Windows..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
    
    # Instalar WSL 2 kernel update
    Write-Host "   Instalando WSL 2 kernel update..."
    winget install Microsoft.WSL --accept-source-agreements
    
    # Establecer WSL 2 como versión por defecto
    wsl --set-default-version 2 2>$null
    
    # Instalar distribución Ubuntu
    Write-Host "   Instalando distribución Ubuntu para WSL..."
    winget install Canonical.Ubuntu --accept-source-agreements
    
    Write-Host "✅ WSL 2 instalado exitosamente"
    Write-Host "   ⚠️  IMPORTANTE: Debes REINICIAR tu PC para completar la instalación de WSL"
    $wslRebootRequired = $true
  }
  catch {
    Write-Host "⚠️  Error instalando WSL 2: $_" -ForegroundColor Yellow
    Write-Host "   Puedes instalarlo manualmente ejecutando: wsl --install"
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
  Write-Host "Docker Desktop requiere configuración con WSL 2 para funcionar correctamente."
  Write-Host ""
  Write-Host "Pasos necesarios:"
  Write-Host "  1. REINICIA tu PC (muy importante para WSL y Hyper-V)"
  Write-Host "  2. Abre 'Ubuntu' desde el menú Inicio para completar la instalación de WSL"
  Write-Host "  3. Abre Docker Desktop desde el menú Inicio"
  Write-Host "  4. En Docker Desktop > Settings > Resources > WSL integration:"
  Write-Host "     - Habilita 'Enable WSL 2 based engine'"
  Write-Host "     - Habilita la integración con 'Ubuntu'"
  Write-Host "  5. Verifica con: docker --version"
  Write-Host "  6. Verifica con: code --version"
  Write-Host "  7. Verifica con: k9s version"
  Write-Host "  8. Luego ejecuta: .\deploy-infrastructure.ps1"
  Write-Host ""
  Write-Host "Para verificar WSL:"
  Write-Host "  wsl --list --verbose"
}
elseif ($failedCount -eq 0) {
  Write-Host "`n✅ Todos los prerequisitos están instalados"
  
  # Final validation
  Write-Host "`nValidación final..."
  Write-Host "Ejecuta los siguientes comandos para verificar:"
  Write-Host "  az --version"
  Write-Host "  kubectl version --client"
  Write-Host "  git --version"
  Write-Host "  code --version"
  Write-Host "  k9s version"
  if (-not $SkipDocker) { Write-Host "  docker --version" }
  
  Write-Host "`n✅ Ahora puedes ejecutar: .\deploy-infrastructure.ps1"
}
else {
  Write-Host "`n⚠️  Algunos tools fallaron en la instalación automática" -ForegroundColor Yellow
  Write-Host "   Instálalos manualmente o corre el script con -SkipDocker -SkipPowerShellCore"
  Write-Host "   Ver README_PREREQUISITES.md para instrucciones"
  exit 1
}
