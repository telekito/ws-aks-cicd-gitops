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

### Archivos a copiar al repo GitOps (obligatorio)

Debes copiar **solo** estos archivos desde este repo hacia el repo GitOps dedicado:

- `workshop-app/k8s-argo/namespace.yaml`
- `workshop-app/k8s-argo/configmap.yaml`
- `workshop-app/k8s-argo/deployment.yaml`
- `workshop-app/k8s-argo/service.yaml`
- `workshop-app/k8s-argo/ingress.yaml` (opcional si no usas ingress controller)

El repo GitOps debe quedar así:

```text
<repo-gitops>/
└── k8s-argo/
    ├── namespace.yaml
    ├── configmap.yaml
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

Comando ejemplo para copiar en Windows (desde la raíz de este repo):

Después de copiar:

1. Haz `git add .`
2. Haz `git commit -m "Add Argo manifests"`
3. Haz `git push`

**Importante:** los cambios de GitOps deben hacerse siempre en ese repo dedicado, no en este repo del workshop.

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
   - Si es privado, añade credenciales (HTTPS con usuario + token)
   - Para Azure DevOps usa URL tipo: `https://dev.azure.com/<org>/<project>/_git/<repo>`

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
- **Error: `Failed to load target state: ... failed to list refs: authentication required`**:
  1. En Argo CD, ve a Settings > Repositories y confirma que el repo esté en estado **Successful**.
  2. Si no está Successful, elimina y vuelve a conectar el repo con credenciales válidas.
  3. Si usas Azure DevOps por HTTPS, verifica PAT con scope **Code (Read)** como mínimo.
  4. Verifica que la URL sea exacta (`https://dev.azure.com/<org>/<project>/_git/<repo>`).
  5. Revisa detalle con `kubectl describe application workshop-app -n argocd`.
- **Error: Application no sincroniza**: revisa URL del repo GitOps y path `k8s-argo` en `kubectl describe application workshop-app -n argocd`.
- **Error: no detecta cambios**: confirma que hiciste commit/push en el repo GitOps (no en este repo).

## Resultado esperado
La aplicación queda gestionada de forma declarativa desde un repositorio GitOps dedicado, sin ensuciar el repositorio del workshop.
