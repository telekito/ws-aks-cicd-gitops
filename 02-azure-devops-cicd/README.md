# 02. Despliegue con Azure DevOps

## Objetivo
Desplegar una aplicación mediante un flujo CI/CD orientado a pipeline.

## Contenido
- Repositorio como origen del código.
- Azure Pipelines en YAML.
- Build de imagen Docker.
- Push a ACR.
- Deploy automatizado en AKS.

## Demo guiada
- Revisar el pipeline.
- Ver el build de la imagen.
- Publicar la imagen en ACR.
- Desplegar en AKS.

## Scripts y archivos
- `azure-pipelines.yml`: pipeline de CI/CD.
- `scripts/build-and-push-image.ps1`: construye y sube la imagen a ACR.
- `scripts/build-image.ps1`: build local para practicar.
- `scripts/deploy-to-aks.ps1`: despliegue manual equivalente al pipeline.
- `..\workshop-app`: aplicación de ejemplo común.
- `..\workshop-app\k8s`: manifiestos base de Kubernetes.

## Laboratorio
1. Revisar el YAML del pipeline.
2. Ejecutar build y push.
3. Desplegar la aplicación.
4. Validar acceso desde el clúster.

## Laboratorio paso a paso

### Prerequisitos
- Tener el módulo 1 (Kubernetes & AKS Essentials) completado
- kubectl conectado a AKS y namespace aks-workshop creado
- Tener un ACR creado y credenciales disponibles
- Tener acceso a un Azure DevOps Project
- Tener el código en un repositorio con `azure-pipelines.yml` en la raíz y la app en `workshop-app/`

**Estructura mínima esperada del repositorio:**

```text
<repo-root>/
├── azure-pipelines.yml
└── workshop-app/
   ├── Dockerfile
   └── k8s/
      ├── namespace.yaml
      ├── configmap.yaml
      ├── deployment.yaml
      └── service.yaml
```

**Validación rápida (antes de ejecutar pipeline):**
- En la raíz del repo debe existir `azure-pipelines.yml`.
- En `workshop-app/` debe existir `Dockerfile`.
- En `workshop-app/k8s/` deben existir los manifests de Kubernetes.
- La rama principal del repositorio debe ser `main` (o ajustar el trigger del pipeline).

### Pasos

1. **Revisar el pipeline**
   - Abre `azure-pipelines.yml`
   - Identifica las dos etapas: Build y Deploy
   - Nota los placeholders que necesitan reemplazo

2. **Configurar los valores del pipeline**
   Reemplaza en `azure-pipelines.yml`:
   - `<ACR_NAME>`: nombre de tu ACR (sin .azurecr.io)
   - `<AKS_RESOURCE_GROUP>`: grupo de recursos del AKS
   - `<AKS_CLUSTER_NAME>`: nombre del clúster AKS
   - `<AZURE_DEVOPS_SERVICE_CONNECTION>`: nombre de conexión service en Azure DevOps
   - `<AZURE_DEVOPS_SERVICE_CONNECTION_TO_ACR>`: nombre de conexión Docker en Azure DevOps

   **Guía paso a paso para obtener las Service Connections:**

   1. Entra a tu proyecto en Azure DevOps.
   2. Ve a **Project settings** (esquina inferior izquierda).
   3. En el menú de la izquierda, abre **Service connections**.
   4. Identifica o crea estas dos conexiones:
      - **Azure Resource Manager**: esta se usa para `<AZURE_DEVOPS_SERVICE_CONNECTION>` (deploy a AKS).
      - **Docker Registry** (apuntando a ACR): esta se usa para `<AZURE_DEVOPS_SERVICE_CONNECTION_TO_ACR>` (build/push de imagen).
   5. Copia el valor exacto de la columna **Name** de cada conexión y pégalo en `azure-pipelines.yml`.

   **Qué debe apuntar cada una:**
   - `<AZURE_DEVOPS_SERVICE_CONNECTION>`: debe tener acceso al Resource Group y al clúster AKS.
   - `<AZURE_DEVOPS_SERVICE_CONNECTION_TO_ACR>`: debe apuntar al ACR correcto y permitir push de imágenes.

   **Validación rápida:**
   - Abre `azure-pipelines.yml` y verifica que esos nombres coinciden exactamente con los nombres listados en **Project settings > Service connections**.
   - Si hay diferencia de mayúsculas, espacios o guiones, el pipeline fallará al resolver la conexión.

3. **Ejecutar el build localmente (opcional)**
   ```powershell
   .\scripts\build-image.ps1 -ImageName workshop-app -Tag 1.0.0 -ContextPath ..\workshop-app
   ```
   **Validación esperada**: imagen built sin errores.

4. **Construir y subir la imagen a ACR**
   ```powershell
   # Con tag 'latest' (default)
   .\scripts\build-and-push-image.ps1
   
   # O con tag personalizado
   .\scripts\build-and-push-image.ps1 -ImageTag "v1.0"
   
   # Solo build local sin push
   .\scripts\build-and-push-image.ps1 -SkipPush
   ```
   **Validación esperada**: imagen buildada y subida a ACR sin errores.

5. **Ejecutar el despliegue manual equivalente al pipeline**
   ```powershell
   .\scripts\deploy-to-aks.ps1 -Namespace aks-workshop -ImageTag latest -AcrName <ACR_NAME>
   ```
   **Validación esperada**: deployment completado, pods en estado Running.

6. **Verificar el despliegue**
   ```powershell
   kubectl get all -n aks-workshop
   kubectl logs $(kubectl get pods -n aks-workshop -o jsonpath='{.items[0].metadata.name}') -n aks-workshop
   ```
   **Validación esperada**: 2 pods running, logs mostrando app escuchando en puerto 3000.

7. **Test de conectividad**
   ```powershell
   kubectl port-forward svc/workshop-app 8080:80 -n aks-workshop
   # En otra terminal
   Invoke-WebRequest http://localhost:8080
   ```
   **Validación esperada**: respuesta JSON con detalles del pod y environment.

### Errores típicos

- **Error: imagen no encontrada**: verifica que el build push fue exitoso en ACR con `az acr repository list`.
- **Error: Pods en CrashLoopBackOff**: revisa los logs con `kubectl logs <pod>` y `kubectl describe pod <pod>`.
- **Error: conexión de servicio no configurada**: crea la conexión manualmente en Azure DevOps Settings.

## Resultado esperado
La aplicación queda desplegada mediante CI/CD y el participante entiende el flujo push hacia el clúster.
