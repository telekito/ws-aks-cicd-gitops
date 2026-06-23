# Prerequisites Installation Guide (Windows)

Este documento te guía para instalar todos los tools necesarios para ejecutar el workshop AKS CI/CD + GitOps en Windows.

## Requisitos del Sistema

Para ejecutar Docker Desktop y el workshop, tu PC debe cumplir:

### Hardware
- **CPU con virtualización habilitada**: VT-x (Intel) o AMD-V (AMD)
  - Verifica en el BIOS: Settings > Advanced > Virtualization Technology o similar
- **RAM mínimo**: 8 GB (recomendado 16 GB)
- **Espacio en disco**: 20+ GB disponibles

### Sistema Operativo
- **Windows 10** (versión 2004+) o **Windows 11**
- **Edición**: Pro, Enterprise o Education
  - ❌ Windows 10 Home NO soporta Hyper-V (necesitas Professional o superior)

### Features a Habilitar
El script automático habilitará estos features de Windows (requieren reinicio):
- **Hyper-V** - Necesario para Docker Desktop (requisito fundamental)
- **Virtual Machine Platform** - Necesario para WSL 2
- **Windows Subsystem for Linux** - WSL 2

## Opción 1: Instalación automática con script (RECOMENDADO)

### Paso 1: Ejecutar el script de instalación

Abre PowerShell **como administrador** en la carpeta `00-setup` y ejecuta:

```powershell
.\install-prerequisites.ps1
```

Este script:
- ✅ Valida que tu CPU soporta virtualización
- ✅ Habilita Hyper-V (requisito fundamental)
- ✅ Instala WSL 2 con Ubuntu
- ✅ Instala Docker Desktop
- ✅ Instala Azure CLI, Git, kubectl, PowerShell Core
- ⏱️ Solicitará reiniciar tu PC (2-3 veces posiblemente)

### Paso 2: Reiniciar tu PC

El script habilitará features de Windows que requieren reinicio. **DEBES REINICIAR** para continuar.

```powershell
Restart-Computer
```

**IMPORTANTE**: Es posible que debas reiniciar 2-3 veces:
1. Después de habilitar Hyper-V
2. Después de instalar WSL 2
3. Después de instalar Docker Desktop

### Paso 3: Verificar la configuración

Después del reinicio, ejecuta el script de verificación:

```powershell
.\verify-docker-wsl.ps1
```

Este script verifica:
- ✅ Hyper-V está habilitado y servicios activos
- ✅ Virtualización en CPU está habilitada
- ✅ WSL 2 está instalado y configurado
- ✅ Docker Desktop está funcionando

Si alguna validación falla, el script te indicará los pasos siguientes.

### Paso 4: Completar la configuración de Docker

1. Abre **Docker Desktop** desde el menú Inicio
2. Ve a **Settings > Resources > WSL integration**
3. Habilita:
   - ✅ "Enable WSL 2 based engine"
   - ✅ "Ubuntu" en la lista de distribuciones
4. Reinicia Docker Desktop
5. Verifica:
   ```powershell
   docker --version
   docker run hello-world
   ```

## Opción 2: Instalación manual con winget

Si prefieres instalar manualmente, abre PowerShell como administrador y sigue estos pasos **en orden**:

### 1. Habilitar Hyper-V (requisito)

```powershell
# Habilitar Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Hyper-V -All
# Reinicia cuando se pida
Restart-Computer
```

O manualmente:
- Panel de Control > Programas > Activar o desactivar características de Windows
- Marca: ✅ Hyper-V
- Reinicia tu PC

### 2. Instalar WSL 2

```powershell
# Instalar WSL 2 y Ubuntu automáticamente
wsl --install

# Reinicia
Restart-Computer
```

Después del reinicio, WSL 2 y Ubuntu estarán listos.

### 3. Instalar herramientas

```powershell
# Actualizar winget
winget upgrade winget

# Azure CLI (necesario para instalar kubectl)
winget install Microsoft.AzureCLI

# kubectl optimizado para AKS
az aks install-cli

# Docker Desktop
winget install Docker.DockerDesktop

# Git
winget install Git.Git

# PowerShell Core (opcional pero recomendado)
winget install Microsoft.PowerShell
```

### 4. Configurar Docker

1. Abre **Docker Desktop** desde el menú Inicio
2. Settings > Resources > WSL integration > Habilita "Enable WSL 2 based engine" e "Ubuntu"
3. Reinicia Docker Desktop
4. Verifica:
   ```powershell
   docker --version
   docker ps
   ```

## Opción 3: Instalación completamente manual desde sitios web

Si prefieres descargar e instalar desde los sitios web originales:

### Azure CLI
1. Descarga desde: https://aka.ms/installazurecliwindows
2. Ejecuta el instalador y sigue las instrucciones
3. Reinicia PowerShell

### WSL 2
1. Lee: https://docs.microsoft.com/en-us/windows/wsl/install-win10
2. Ejecuta: `wsl --install`
3. Instala distribución Ubuntu desde Microsoft Store

### Docker Desktop
1. Descarga desde: https://www.docker.com/products/docker-desktop
2. Ejecuta el instalador
3. Sigue el wizard de configuración
4. En Settings > Resources > WSL integration, habilita Ubuntu

### kubectl
```powershell
az aks install-cli
```

### Git
Descarga desde: https://git-scm.com/download/win

### PowerShell Core (opcional)
Descarga desde: https://github.com/PowerShell/PowerShell/releases

## Troubleshooting

### Error: "Hyper-V not available"
- Tu edición de Windows no soporta Hyper-V (necesitas Pro o Enterprise, no Home)
- Solución: Actualiza a Windows Pro o usa Docker sin WSL 2

### Error: "CPU virtualization not enabled"
- Entra en el BIOS y habilita: VT-x (Intel) o AMD-V (AMD)
- Cada fabricante tiene menús diferentes, busca en el manual de tu motherboard

### Error: "WSL kernel not installed"
- Ejecuta: `wsl --install`
- O descarga el kernel manualmente: https://aka.ms/wsl2kernel

### Error: "Docker can't start"
- Verifica que Hyper-V está habilitado: `Get-WindowsOptionalFeature -Online -FeatureName Hyper-V`
- Verifica que Docker Desktop está configurado con WSL 2: Settings > Resources > WSL integration
- Reinicia Docker Desktop

### Error: "Docker command not found"
- Abre Docker Desktop desde el menú Inicio (debe estar ejecutándose)
- Espera a que termine de inicializar
- Abre una nueva PowerShell

## Próximos pasos

Una vez instalados todos los requisitos:

```powershell
cd .\00-setup
.\deploy-infrastructure.ps1
```

Esto creará:
- Grupo de recursos en Azure
- Clúster AKS
- Azure Container Registry (ACR)
- Construirá y subirá la imagen de la app al ACR

## Ayuda adicional

- Azure CLI docs: https://docs.microsoft.com/en-us/cli/azure/
- WSL docs: https://docs.microsoft.com/en-us/windows/wsl/
- Docker docs: https://docs.docker.com/
- AKS docs: https://docs.microsoft.com/en-us/azure/aks/
