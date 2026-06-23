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
- Lanzar el pipeline.
- Validar build/push de imagen en ACR.
- Validar despliegue en AKS.

## Archivos
- `azure-pipelines.yml`: pipeline de CI/CD.
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
   ├── src/
   │  └── server.js
   ├── Dockerfile
   └── k8s/
      ├── namespace.yaml
      ├── configmap.yaml
      ├── deployment.yaml
      └── service.yaml
```

**Validación rápida (antes de ejecutar pipeline):**
- En la raíz del repo debe existir `azure-pipelines.yml`.
- En `workshop-app/src/` debe existir el código fuente de la app (ej. `server.js`, `index.html`).
- En `workshop-app/` debe existir `Dockerfile`.
- En `workshop-app/k8s/` deben existir los manifests de Kubernetes.
- La rama principal del repositorio debe ser `main` (o ajustar el trigger del pipeline).
- El código debe estar committed y pushed al repositorio remoto (Azure DevOps/GitHub), no solo local.

### Pasos

1. **Revisar el pipeline**
   - Abre `azure-pipelines.yml`
   - Identifica las dos etapas: Build y Deploy
   - Nota los placeholders que necesitan reemplazo

   **Importante:** el pipeline construye la imagen desde el código que está en el repositorio remoto. Si cambias archivos locales en `workshop-app/src`, primero haz `git add`, `git commit` y `git push` para que esos cambios entren al build.

2. **Configurar los valores del pipeline**
   Reemplaza en `azure-pipelines.yml`:
   - `<ACR_NAME>`: nombre de tu ACR (sin .azurecr.io)
   - `<AKS_RESOURCE_GROUP>`: grupo de recursos del AKS
   - `<AKS_CLUSTER_NAME>`: nombre del clúster AKS
   - `<AZURE_DEVOPS_SERVICE_CONNECTION>`: nombre de conexión service en Azure DevOps
   
   **Nota:** este workshop usa una sola conexión **Azure Resource Manager** para build/push a ACR y deploy a AKS.

   **Guía paso a paso para obtener la Service Connection:**

   1. Entra a tu proyecto en Azure DevOps.
   2. Ve a **Project settings** (esquina inferior izquierda).
   3. En el menú de la izquierda, abre **Service connections**.
   4. Crea o identifica una conexión de tipo **Azure Resource Manager**.
   5. Copia el valor exacto de la columna **Name** y úsalo en `<AZURE_DEVOPS_SERVICE_CONNECTION>`.

   **Permisos que debe tener esta conexión ARM:**
   - Permisos sobre el Resource Group donde está AKS (para desplegar).
   - Permiso `AcrPush` sobre el ACR (para build/push de imágenes).

   **Validación rápida:**
   - Abre `azure-pipelines.yml` y verifica que `<AZURE_DEVOPS_SERVICE_CONNECTION>` coincide exactamente con el nombre listado en **Project settings > Service connections**.
   - Si hay diferencia de mayúsculas, espacios o guiones, el pipeline fallará al resolver la conexión.

3. **Crear o validar el pipeline en Azure DevOps**
   - Ve a **Pipelines > Pipelines > New pipeline**.
   - Selecciona tu repositorio.
   - Elige **Existing Azure Pipelines YAML file** y selecciona `azure-pipelines.yml`.
   - Guarda el pipeline.
   **Validación esperada**: pipeline creado y apuntando al YAML correcto.

4. **Ejecutar el pipeline (Run pipeline)**
   - Pulsa **Run pipeline** sobre la rama `main`.
   - Espera la ejecución de los stages `Build` y `Deploy`.
   **Validación esperada**: ejecución en estado `Succeeded`.

5. **Validar stage Build (imagen en ACR)**
   - Abre los logs del stage `Build`.
   - Verifica que se ejecutó login a ACR, `docker build` y `docker push`.
   - Comprueba en ACR que existe la imagen `workshop-app` con tag `Build.BuildId` y `latest`.
   **Validación esperada**: imagen publicada correctamente.

6. **Validar stage Deploy (aplicación en AKS)**
   - Abre los logs del stage `Deploy`.
   - Verifica `apply` de `namespace/configmap/service/deployment` y `rollout status` exitoso.
   **Validación esperada**: despliegue completado sin errores.

7. **Verificar el despliegue desde kubectl**
   ```powershell
   kubectl get all -n aks-workshop
   kubectl logs $(kubectl get pods -n aks-workshop -o jsonpath='{.items[0].metadata.name}') -n aks-workshop
   ```
   **Validación esperada**: 2 pods running, logs mostrando app escuchando en puerto 3000.

8. **Test de conectividad**
   ```powershell
   kubectl port-forward svc/workshop-app 8080:80 -n aks-workshop
   # En otra terminal
   Invoke-WebRequest http://localhost:8080
   ```
   **Validación esperada**: respuesta JSON con detalles del pod y environment.

### Errores típicos

- **Error: pipeline no dispara**: revisa que el YAML esté en la raíz y la rama trigger sea `main`.
- **Error: `No configuration file matching .../configmap.yaml`**: el archivo no está en la rama que está construyendo el pipeline. Verifica `workshop-app/k8s/configmap.yaml` en el repo remoto y haz `git add`, `git commit` y `git push`.
- **Error: imagen no encontrada**: verifica que el build push fue exitoso en ACR con `az acr repository list`.
- **Error: Pods en CrashLoopBackOff**: revisa los logs con `kubectl logs <pod>` y `kubectl describe pod <pod>`.
- **Error: conexión de servicio no configurada**: crea la conexión manualmente en Azure DevOps Settings.

## Resultado esperado
La aplicación queda desplegada mediante CI/CD y el participante entiende el flujo push hacia el clúster.
