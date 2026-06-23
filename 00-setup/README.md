# 00. Setup - Preparación del entorno

Este módulo contiene todo lo necesario para preparar tu máquina y desplegar la infraestructura del workshop en Azure.

## Estructura

```text
00-setup/
├── README.md (guía unificada)
├── install-prerequisites.ps1
├── verify-docker-wsl.ps1
├── deploy-infrastructure.ps1
├── update-placeholders.ps1
└── cleanup-workshop.ps1
```

## Flujo recomendado

1. Instalar prerequisitos
2. Reiniciar y validar Docker/WSL
3. Desplegar infraestructura
4. Continuar con el módulo 01

## 1) Instalar prerequisitos

Ejecuta PowerShell como administrador:

```powershell
cd 00-setup
.\install-prerequisites.ps1
```

Opciones disponibles:

```powershell
.\install-prerequisites.ps1 -SkipDocker -SkipPowerShellCore
```

El script valida e instala:

- Hyper-V (requisito)
- WSL 2
- Microsoft Store source para winget (msstore)
- Azure CLI
- kubectl (via az aks install-cli)
- Git
- Visual Studio Code
- k9s
- Docker Desktop (si no usas SkipDocker)
- PowerShell Core (si no usas SkipPowerShellCore)

## 2) Verificar Docker + WSL + Hyper-V

Después de reiniciar:

```powershell
.\verify-docker-wsl.ps1
```

Si Docker Desktop está instalado, comprueba también en la UI:

- Settings > Resources > WSL integration
- Enable WSL 2 based engine
- Integración habilitada para Ubuntu

## 3) Desplegar infraestructura

```powershell
.\deploy-infrastructure.ps1
```

Qué hace:

- Selecciona suscripción de Azure
- Genera sufijo aleatorio de 3 dígitos
- Usa defaults únicos para RG, AKS y ACR si no pasas parámetros
- Crea Resource Group, ACR y AKS
- Configura kubectl
- Construye y sube la imagen workshop-app al ACR (si Docker está disponible)
- Asigna AcrPull al usuario autenticado
- Guarda configuración en workshop-config.json

Ejemplo con parámetros explícitos:

```powershell
.\deploy-infrastructure.ps1 `
  -ResourceGroup "aks-workshop-rg-123" `
  -AksClusterName "aks-workshop-123" `
  -AcrName "aksworkshop123" `
  -Location "eastus" `
  -NodeCount 2 `
  -VmSize "Standard_B2s"
```

Modo sin confirmación:

```powershell
.\deploy-infrastructure.ps1 -SkipValidation
```

## 4) Continuar workshop

```powershell
cd ..\01-kubernetes-essentials
```

## Scripts del módulo

### install-prerequisites.ps1

- Instala prerequisitos con winget
- Verifica fuente msstore
- Configura Hyper-V/WSL para Docker

### verify-docker-wsl.ps1

- Verifica Hyper-V, virtualización CPU, WSL 2 y Docker

### deploy-infrastructure.ps1

- Despliega AKS + ACR
- Sube imagen al ACR
- Asigna rol AcrPull

### update-placeholders.ps1

- Reemplaza placeholders en archivos del workshop usando workshop-config.json

### cleanup-workshop.ps1

- Elimina recursos del workshop en Azure

## Troubleshooting rápido

### winget o msstore no disponible

```powershell
winget source reset --force
winget source list
```

Luego actualiza App Installer desde Microsoft Store.

### No autenticado en Azure

```powershell
az login
az account list --output table
```

### Docker no responde

- Abre Docker Desktop
- Espera inicialización
- Verifica integración WSL 2

### Error de ejecución de scripts

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Limpieza

```powershell
.\cleanup-workshop.ps1
```

Sin confirmación:

```powershell
.\cleanup-workshop.ps1 -Force
```
