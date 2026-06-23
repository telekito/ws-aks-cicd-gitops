# 03. Despliegue con GitOps y Argo CD

## Objetivo
Gestionar el despliegue con un modelo declarativo basado en Git como fuente de verdad.

## Contenido
- Git como fuente de verdad.
- Modelo pull.
- Desired state vs actual state.
- Arquitectura Git -> Argo CD -> AKS.

## Scripts y archivos
- `scripts/install-argocd.ps1`: instala Argo CD en el clúster y expone IP pública.
- `scripts/get-argocd-access.ps1`: obtiene credenciales y URL de acceso.
- `scripts/deploy-gitops-app.ps1`: crea la Application y espera estado Synced/Healthy.
- `manifests/application.yaml`: definición GitOps de la aplicación.

## Laboratorio paso a paso

### Prerequisitos
- Tener módulo 2 completado (app desplegada con CI/CD)
- Acceso a un repositorio Git dedicado para GitOps (separado de este repo)
- Ese repo GitOps debe contener la carpeta `k8s-argo/` en la raíz

### Pasos

1. **Instalar Argo CD**
   ```powershell
   .\scripts\install-argocd.ps1 -Namespace argocd
   ```
   **Validación esperada**: deployment/argocd-server disponible, service con IP pública.

2. **Obtener IP pública y credenciales de acceso**
   ```powershell
   .\scripts\get-argocd-access.ps1 -Namespace argocd
   ```
   **Validación esperada**:
   - Muestra `Usuario`, `Password` y `URL pública` (si ya fue asignada)
   - Si no hay IP aún, muestra comando de port-forward temporal

3. **Acceder a la UI de Argo CD**
   - Abre en navegador: `https://<EXTERNAL-IP>`
   - Login: `admin` / `<password>`
   
   **Validación esperada**: dashboard de Argo CD sin errores.

4. **Configurar el repositorio Git dedicado en Argo CD**
   - En UI: Settings > Repositories > Connect Repo
   - Type: Git
   - Repository URL: `<GIT_REPOSITORY_URL>`
   - Si es privado, añade credenciales

5. **Desplegar la Application con script**
   ```powershell
   .\scripts\deploy-gitops-app.ps1 -GitRepositoryUrl "<GIT_REPOSITORY_URL>"
   ```
   **Validación esperada**: Application creada y en estado `Synced` / `Healthy`.

6. **Ver la app sincronizada en el namespace de Argo**
   ```powershell
   kubectl get all -n aks-workshop-argo
   ```
   **Validación esperada**: Deployment y pods en Running.

7. **Demostración GitOps (sin tocar este repo de workshop)**
   - Modifica un valor en `k8s-argo/configmap.yaml` del repo GitOps dedicado (ej: ENVIRONMENT)
   - Haz commit y push en el repo GitOps
   - Observa en Argo CD la sincronización automática

### Errores típicos

- **Error: Argo CD no se instala**: verifica acceso a internet para descargar el manifest oficial.
- **Error: no hay IP pública**: espera unos minutos y ejecuta `kubectl get svc argocd-server -n argocd -w`.
- **Error: Application no sincroniza**: revisa URL del repo GitOps y path `k8s-argo` en `kubectl describe application workshop-app -n argocd`.
- **Error: no detecta cambios**: confirma que hiciste commit/push en el repo GitOps (no en este repo).

## Resultado esperado
La aplicación queda gestionada de forma declarativa desde un repositorio GitOps dedicado, sin ensuciar el repositorio del workshop.
