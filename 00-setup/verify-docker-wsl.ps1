# Script para verificar la configuración de Hyper-V, Docker y WSL después del reinicio

Write-Host "================================================"
Write-Host "Verificación de Hyper-V, Docker y WSL 2"
Write-Host "================================================"
Write-Host ""

# Verificar Hyper-V por confirmación del usuario
Write-Host "--- Hyper-V ---"
$hyperVConfirm = Read-Host "¿Confirmas que Hyper-V está habilitado en Windows Features? (s/n)"
if ($hyperVConfirm -ne 's' -and $hyperVConfirm -ne 'S') {
  Write-Host "❌ Hyper-V no confirmado" -ForegroundColor Red
  Write-Host "   Habilítalo en: Panel de Control > Programas > Activar o desactivar características de Windows"
  Write-Host "   Marca 'Hyper-V' y reinicia el equipo"
  exit 1
}
Write-Host "✅ Hyper-V confirmado por el usuario"

# Verificar virtualización CPU por confirmación del usuario
Write-Host ""
Write-Host "--- Virtualización en CPU ---"
$cpuVirtConfirm = Read-Host "¿Confirmas que la virtualización del CPU (VT-x/AMD-V) está habilitada en BIOS? (s/n)"
if ($cpuVirtConfirm -ne 's' -and $cpuVirtConfirm -ne 'S') {
  Write-Host "❌ Virtualización CPU no confirmada" -ForegroundColor Red
  Write-Host "   Habilita VT-x (Intel) o AMD-V (AMD) en BIOS y reinicia"
  exit 1
}
Write-Host "✅ Virtualización CPU confirmada por el usuario"

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

Write-Host ""
Write-Host "================================================"
Write-Host "Resumen"
Write-Host "================================================"
Write-Host ""
Write-Host "Cuando todo esté verificado:"
Write-Host "  cd .\00-setup"
Write-Host "  .\deploy-infrastructure.ps1"
Write-Host ""
