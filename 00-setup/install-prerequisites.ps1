#!/usr/bin/env pwsh

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
      winget install $tool.WingetId --accept-source-agreements
      
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
      
      # Verify installation
      if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
        Write-Host "✅ $($tool.Name) instalado correctamente"
        $installedCount++
        Invoke-Expression $tool.Version
      }
      else {
        Write-Host "❌ $($tool.Name) no se pudo instalar automáticamente"
        Write-Host "   Instálalo manualmente desde: $($tool.WingetId)"
        $failedCount++
      }
    }
    catch {
      Write-Host "❌ Error instalando $($tool.Name): $_" -ForegroundColor Red
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

if ($failedCount -eq 0) {
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
  Write-Host "`n⚠️  Algunos tools fallaron en la instalación automática"
  Write-Host "   Instálalos manualmente o corre el script con -SkipDocker -SkipPowerShellCore"
  Write-Host "   Ver README_PREREQUISITES.md para instrucciones"
  exit 1
}
