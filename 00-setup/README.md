# 00. Setup - Preparación del entorno

Este módulo contiene todo lo necesario para preparar tu máquina local y desplegar la infraestructura en Azure para el workshop.

## Estructura

```
00-setup/
├── README.md (este archivo)
├── README_PREREQUISITES.md (guía de instalación de tools)
├── install-prerequisites.ps1 (instalación automática con winget)
├── deploy-infrastructure.ps1 (despliegue de AKS, ACR, etc.)
├── cleanup-workshop.ps1 (elimina todos los recursos de Azure)
├── update-placeholders.ps1 (reemplaza valores en scripts y manifiestos)
└── workshop-config.json (generado tras el despliegue)
```

## Flujo rápido (5-10 minutos)

### Paso 1: Instalar prerequisitos

Opción A (automático):
```powershell
# Abre PowerShell como administrador
cd 00-setup
.\install-prerequisites.ps1
```

El script instalará:
- Azure CLI (vía winget)
- kubectl (vía `az aks install-cli` — recomendado para AKS)
- Git (vía winget)
- Docker Desktop (opcional)
- PowerShell Core (opcional)

**Por qué kubectl con Azure CLI:**
- ✅ Optimizado específicamente para AKS
- ✅ Actualización automática garantizada
- ✅ Herramientas AKS adicionales incluidas
- ✅ Compatible con todas las versiones de AKS

Opción B (manual):
- Lee [README_PREREQUISITES.md](README_PREREQUISITES.md)
- Instala cada tool según tus preferencias

### Paso 2: Desplegar infraestructura en Azure

```powershell
# Desde la carpeta 00-setup
.\deploy-infrastructure.ps1
```

El script:
- Validará que estés autenticado (`az login`)
- Te pedirá el nombre del grupo de recursos
- Te pedirá el nombre del AKS
- Te pedirá el nombre del ACR
- Desplegará todo (toma ~10 minutos)
- Guardará los valores en `workshop-config.json`

### Paso 3: Guardar valores para el resto del workshop

Después de ejecutar `deploy-infrastructure.ps1`, tendrás en pantalla algo como:

```
Información importante:
  Grupo de recursos: aks-workshop-rg
  Clúster AKS: aks-workshop-cluster
  ACR: aksworshopreg.azurecr.io
```

**Guarda estos valores** porque los necesitarás para todos los scripts del workshop.

Reemplaza en todos los scripts:
- `<AKS_RESOURCE_GROUP>` → `aks-workshop-rg`
- `<AKS_CLUSTER_NAME>` → `aks-workshop-cluster`
- `<ACR_NAME>` → `aksworshopreg`

## Scripts detallado

### install-prerequisites.ps1

Instala automáticamente con winget:
- Azure CLI
- kubectl
- Git
- Docker Desktop (opcional)
- PowerShell Core (opcional)

**Uso:**
```powershell
.\install-prerequisites.ps1

# Con opciones
.\install-prerequisites.ps1 -SkipDocker -SkipPowerShellCore
```

**Qué valida:**
- Que seas administrador
- Que winget esté disponible
- Que cada tool se instala correctamente
- Que el PATH se actualiza

### deploy-infrastructure.ps1

Despliega en Azure:
- Grupo de recursos
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)
- Configura kubectl automáticamente

**Uso:**
```powershell
.\deploy-infrastructure.ps1

# Con parámetros específicos
.\deploy-infrastructure.ps1 `
  -ResourceGroup "my-rg" `
  -AksClusterName "my-aks" `
  -AcrName "myacrname" `
  -Location "eastus" `
  -NodeCount 3
```

**Parámetros:**
- `SubscriptionId`: ID de suscripción (se pide interactivamente si falta)
- `ResourceGroup`: Nombre del RG
- `Location`: Región Azure (default: eastus)
- `AksClusterName`: Nombre del clúster
- `AcrName`: Nombre del ACR (sin .azurecr.io)
- `NodeCount`: Cantidad de nodos (default: 2)
- `VmSize`: Tamaño de VM (default: Standard_B2s)

**Qué valida:**
- Autenticación en Azure
- Disponibilidad de herramientas
- Creación de recursos
- Conexión a kubectl
- Estado de nodos

**Qué genera:**
- Grupo de recursos
- ACR
- AKS con 2 nodos
- Archivo `workshop-config.json` con los valores usados

## Troubleshooting

### "No tengo winget"
Windows 11 viene con winget por defecto. En Windows 10:
- Descárgalo desde: https://github.com/microsoft/winget-cli/releases
- O instala Chocolatey en su lugar

### "Az login dice que no estoy autenticado"
```powershell
az login --use-device-code  # En redes corporativas
az login                    # En redes normales
```

### "Permission denied running PowerShell script"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "AKS tardó más de lo esperado"
Es normal que tarde 10-15 minutos. Puedes monitorear en Azure Portal.

### "Error: subscription not found"
```powershell
az account list --output table  # Ver suscripciones
az account set --subscription "<SUBSCRIPTION_ID>"
```

### "ACR already exists"
ACR solo se puede crear una vez. Si ya existe, el script continuará.

## Verificación post-deployment

Después de todo, verifica que funciona:

```powershell
# Conectado a Azure
az account show

# Conectado al AKS
kubectl cluster-info
kubectl get nodes

# ACR accesible
az acr login --name <ACR_NAME>
az acr repository list --name <ACR_NAME>
```

## Limpieza (al final del workshop)

Usa el script de limpieza para eliminar todos los recursos de Azure:

```powershell
# Desde 00-setup
.\cleanup-workshop.ps1
```

El script:
- ✅ Verifica autenticación en Azure
- ✅ Lee la configuración de `workshop-config.json`
- ✅ Lista todos los recursos que se van a eliminar
- ✅ Pide confirmación antes de proceder
- ✅ Inicia la eliminación del grupo de recursos
- ✅ Puede monitorear el progreso en tiempo real

**Alternativa manual:**
```powershell
# ⚠️ CUIDADO: Borra TODOS los recursos
az group delete --name <RESOURCE_GROUP_NAME> --yes

# Luego ejecuta de nuevo deploy-infrastructure.ps1 si necesitas
```

**Con fuerza (sin confirmación):**
```powershell
.\cleanup-workshop.ps1 -Force
```

## Costos

AKS con 2 nodos `Standard_B2s` cuesta aproximadamente:
- ~$50-70 por mes en compute
- ~$5-10 en networking/storage
- **Total estimado: $60-80/mes**

Para minimizar costos:
- Usa `Standard_B2s` (default, el más barato)
- Borra el grupo de recursos cuando no lo uses
- No la dejes corriendo en fin de semana

## Próximos pasos

Una vez completados los pasos 1-3:

1. Anota los valores de:
   - Resource Group
   - AKS Cluster Name
   - ACR Name

2. Reemplaza esos valores en todos los scripts del workshop:
   - Archivos `.ps1` en cada módulo
   - Manifiestos `.yaml` en `workshop-app/k8s/`
   - Pipeline `azure-pipelines.yml` en módulo 3

3. Ejecuta el módulo 1: `cd ../01-kubernetes-essentials && .\README.md`

¡Listo! Ahora tienes infraestructura lista en Azure para el workshop.
