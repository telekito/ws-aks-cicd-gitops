# Script para verificar la configuración de Docker y WSL después del reinicio

Write-Host "================================================"
Write-Host "Verificación de Docker y WSL 2"
Write-Host "================================================"
Write-Host ""

# Verificar WSL
Write-Host "--- Windows Subsystem for Linux 2 (WSL) ---"
Write-Host "Verificación de Hyper-V, Docker y WSL 2"
Write-Host "================================================"
Write-Host ""

# Verificar Hyper-V (requisito fundamental)
Write-Host "--- Hyper-V ---"
try {
  $hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName Hyper-V -ErrorAction SilentlyContinue
  if ($hyperVFeature.State -eq 'Enabled') {
    Write-Host "✅ Hyper-V está habilitado"
    
    # Verificar que Hyper-V services estén corriendo
    $services = Get-Service -Name "vmms", "HV*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }
    if ($services.Count -gt 0) {
      Write-Host "✅ Servicios de Hyper-V están activos"
    }
    else {
      Write-Host "⚠️  Algunos servicios de Hyper-V no están activos" -ForegroundColor Yellow
      Write-Host "   Esto puede significar que necesitas reiniciar"
    }
  }
  else {
    Write-Host "❌ Hyper-V NO está habilitado" -ForegroundColor Red
    Write-Host "   REQUISITO: Debe estar habilitado para Docker"
    Write-Host "   Habilítalo en: Panel de Control > Programas > Activar o desactivar características de Windows"
    Write-Host "   Luego reinicia tu PC"
    exit 1
  }
}
catch {
  Write-Host "⚠️  Error verificando Hyper-V: $_" -ForegroundColor Yellow
}

# Verificar CPU virtualización
Write-Host ""
Write-Host "--- Virtualización en CPU ---"
try {
  $cpuVirt = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue | Select-Object -ExpandProperty VirtualizationFirmwareEnabled
  if ($cpuVirt -eq $true) {
    Write-Host "✅ Virtualización en CPU habilitada"
  }
  elseif ($cpuVirt -eq $false) {
    Write-Host "❌ Virtualización en CPU NO está habilitada" -ForegroundColor Red
    Write-Host "   REQUISITO: Habilítalo en el BIOS"
    Write-Host "   Búsca 'VT-x' (Intel) o 'AMD-V' (AMD) en tu BIOS"
  }
  else {
    Write-Host "⚠️  No se puede determinar estado de virtualización en CPU" -ForegroundColor Yellow
    Write-Host "   Verifica en tu BIOS que esté habilitada"
  }
}
catch {
  Write-Host "⚠️  Error verificando CPU virtualización" -ForegroundColor Yellow
}

# Verificar WSL
Write-Host ""
Write-Host "--- Windows Subsystem for Linux 2 (WSL 2) ---"
$wslList = wsl --list --verbose 2>$null
if ($LASTEXITCODE -eq 0 -and $wslList) {
  Write-Host "✅ WSL está habilitado"
  Write-Host ""
  Write-Host "Distribuciones instaladas:"
  $wslList | Select-Object -Skip 1 | ForEach-Object {
    Write-Host "  $_"
  }
  
  # Verificar si hay alguna en WSL 2
  if ($wslList -match "2") {
    Write-Host ""
    Write-Host "✅ WSL 2 está configurado"
  }
  else {
    Write-Host ""
    Write-Host "⚠️  No hay distribuciones configuradas como WSL 2" -ForegroundColor Yellow
    Write-Host "   Ejecuta: wsl --set-version Ubuntu 2"
  }
}
else {
  Write-Host "❌ WSL no está disponible o no se instaló correctamente" -ForegroundColor Red
  Write-Host "   REQUISITO: Ejecuta: wsl --install"
  Write-Host "   Luego reinicia tu PC"
  exit 1
}

# Verificar Docker
Write-Host ""
Write-Host "--- Docker Desktop ---"
if (Get-Command docker -ErrorAction SilentlyContinue) {
  Write-Host "✅ Docker CLI está disponible"
  docker --version
  
  # Verificar si Docker daemon está corriendo
  Write-Host ""
  docker ps -q 2>$null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker daemon está ejecutándose"
    
    # Verificar integración con WSL
    Write-Host ""
    Write-Host "Para verificar la integración con WSL:"
    Write-Host "  1. Abre Docker Desktop"
    Write-Host "  2. Ve a Settings > Resources > WSL integration"
    Write-Host "  3. Verifica que 'Enable WSL 2 based engine' esté habilitado"
    Write-Host "  4. Verifica que 'Ubuntu' esté habilitado en la lista"
  }
  else {
    Write-Host "⚠️  Docker daemon no está ejecutándose" -ForegroundColor Yellow
    Write-Host "   Abre Docker Desktop desde el menú Inicio"
  }
}
else {
  Write-Host "❌ Docker CLI no está disponible" -ForegroundColor Red
  Write-Host "   Abre Docker Desktop desde el menú Inicio"
  Write-Host "   Si no está instalado, ejecuta: .\install-prerequisites.ps1"
}

# Verificar Hyper-V
Write-Host ""
Write-Host "--- Hyper-V ---"
$hyperVEnabled = (Get-WindowsOptionalFeature -Online -FeatureName Hyper-V -ErrorAction SilentlyContinue).State -eq 'Enabled'
if ($hyperVEnabled) {
  Write-Host "✅ Hyper-V está habilitado"
}
else {
  Write-Host "❌ Hyper-V no está habilitado" -ForegroundColor Red
  Write-Host "   Habilítalo en: Panel de Control > Programas > Activar o desactivar características de Windows"
  Write-Host "   Luego reinicia tu PC"
}

Write-Host ""
Write-Host "================================================"
Write-Host "Resumen"
Write-Host "================================================"
Write-Host ""
Write-Host "Cuando todo esté verificado:"
Write-Host "  cd .\00-setup"
Write-Host "  .\deploy-infrastructure.ps1"
Write-Host ""
