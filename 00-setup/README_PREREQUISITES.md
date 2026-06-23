# Prerequisites Installation Guide (Windows)

Este documento te guía para instalar todos los tools necesarios para ejecutar el workshop AKS CI/CD + GitOps en Windows.

## Opción 1: Instalación automática con winget (recomendado)

Si tienes **Windows 11** o **Windows 10 con winget**, abre PowerShell como administrador y corre:

```powershell
# Actualizar winget
winget upgrade winget

# Instalar Azure CLI (necesario para instalar kubectl optimizado para AKS)
winget install Microsoft.AzureCLI

# Después de instalar Azure CLI, instala kubectl optimizado para AKS
az aks install-cli

# Instalar Docker Desktop (opcional pero recomendado para builds locales)
winget install Docker.DockerDesktop

# Instalar Git
winget install Git.Git

# Instalar PowerShell Core (opcional pero recomendado)
winget install Microsoft.PowerShell
```

Si algun comando falla, continúa con la opción manual o usa el script `install-prerequisites.ps1`.

## Opción 2: Instalación con script PowerShell

Abre PowerShell **como administrador** en esta carpeta y corre:

```powershell
.\install-prerequisites.ps1
```

El script:
- Detecta qué tools están instalados
- Instala los que faltan
- Valida las versiones
- Crea los directorios necesarios

## Opción 3: Instalación manual

Si prefieres instalar manualmente:

### Azure CLI
1. Descarga desde: https://aka.ms/installazurecliwindows
2. O con chocolatey: `choco install azure-cli`
3. O con winget: `winget install Microsoft.AzureCLI`

### kubectl
**Recomendado (con Azure CLI):**
```powershell
# Primero instala Azure CLI, luego:
az aks install-cli
```

**Alternativas:**
1. Manual desde: https://kubernetes.io/docs/tasks/tools/install-kubectl-on-windows/
2. Con winget: `winget install Kubernetes.kubectl`
3. Con chocolatey: `choco install kubernetes-cli`

### Docker Desktop
1. Descarga desde: https://www.docker.com/products/docker-desktop
2. O con winget: `winget install Docker.DockerDesktop`
3. O con chocolatey: `choco install docker-desktop`

### Git
1. Descarga desde: https://git-scm.com/download/win
2. O con winget: `winget install Git.Git`
3. O con chocolatey: `choco install git`

### PowerShell Core (opcional)
1. Descarga desde: https://github.com/PowerShell/PowerShell/releases
2. O con winget: `winget install Microsoft.PowerShell`
3. O con chocolatey: `choco install powershell-core`

## Validación de instalación

Después de instalar, abre una **nueva** terminal PowerShell y verifica:

```powershell
# Azure CLI
az --version

# kubectl (instalado via az aks install-cli)
kubectl version --client

# Verificar ubicación de kubectl
where kubectl

# Docker (si lo instalaste)
docker --version

# Git
git --version

# PowerShell (si es Core)
$PSVersionTable.PSVersion
```

Deberías ver versiones sin errores.

## Configuración post-instalación

### 1. Autenticarte en Azure

```powershell
az login
```

Se abrirá una ventana del navegador para que completes la autenticación.

### 2. Configurar Azure CLI con tu suscripción

```powershell
# Listar suscripciones
az account list --output table

# Establecer suscripción predeterminada
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 3. Crear directorio para credentials (opcional)

```powershell
mkdir -p ~/.azure
mkdir -p ~/.kube
```

## Troubleshooting

### "winget no found"
- Windows 11 viene con winget por defecto
- En Windows 10, descárgalo desde: https://github.com/microsoft/winget-cli/releases
- O usa chocolatey en su lugar: `choco install <package>`

### "Az command not found" después de instalar
- Cierra la terminal actual y abre una nueva
- Az CLI modifica el PATH, necesitas recargar la sesión

### "Docker Desktop needs WSL2"
- Instala WSL2: `wsl --install`
- Reinicia tu máquina
- Abre Docker Desktop de nuevo

### "kubectl no reconocido"
- Verifica que está en el PATH: `where kubectl`
- Si está vacío, reinstala con winget

### Permission denied en script
- Abre PowerShell como **administrador**
- O corre: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Versiones mínimas recomendadas

- Azure CLI: 2.50.0+ (instala kubectl automáticamente)
- kubectl: 1.20.0+ (instalado via `az aks install-cli`)
- Docker Desktop: 4.20.0+ (si la usas)
- Git: 2.35.0+
- PowerShell: 5.1+ (Windows PowerShell) o 7.0+ (PowerShell Core)

## Por qué instalar kubectl con Azure CLI

✅ **Ventajas:**
- Optimizado para AKS
- Actualización automática incluida
- Compatible con todas las versiones de AKS
- Se instala en la ubicación estándar de Azure CLI
- Incluye herramientas adicionales de AKS (az aks, etc.)

⚠️ Otras instalaciones pueden quedar desincronizadas con las versiones de AKS.

## Próximos pasos

Una vez instalados todos los tools, ejecuta:

```powershell
cd ../
.\deploy-infrastructure.ps1
```

Para desplegar la infraestructura en Azure.
