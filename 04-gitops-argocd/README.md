# 04. Despliegue con GitOps y Argo CD

## Objetivo
Gestionar el despliegue con un modelo declarativo basado en Git como fuente de verdad.

## Contenido
- Git como fuente de verdad.
- Modelo pull.
- Desired state vs actual state.
- Arquitectura Git -> Argo CD -> AKS.

## Scripts y archivos
- `scripts/install-argocd.ps1`: instala Argo CD en el clúster.
- `scripts/get-argocd-access.ps1`: obtiene el acceso inicial a la UI.
- `manifests/application.yaml`: definición GitOps de la aplicación.

## Laboratorio paso a paso

### Prerequisitos
- Tener módulo 3 completado (app desplegada con CI/CD)
- Acceso a un repositorio Git con permisos de lectura
- El contenido de `workshop-app/k8s/` debe estar en ese repositorio bajo la misma estructura

### Pasos

1. **Instalar Argo CD**
   ```powershell
   .\scripts\install-argocd.ps1 -Namespace argocd
   ```
   **Validación esperada**: deployment/argocd-server available, pods en estado Running.

2. **Obtener credenciales de acceso**
   ```powershell
   .\scripts\get-argocd-access.ps1
   ```
   **Validación esperada**: muestra contraseña admin y comando de port-forward.

3. **Acceder a la UI de Argo CD**
   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   # Abre en navegador: https://localhost:8080
   # Login: admin / <password>
   ```
   **Validación esperada**: dashboard de Argo CD sin errores, lista vacía de Applications.

4. **Configurar el repositorio Git en Argo CD**
   - En UI: Settings > Repositories > Connect Repo
   - Type: Git
   - Repository URL: `<GIT_REPOSITORY_URL>`
   - Si es privado, añade credenciales

5. **Revisar el manifiesto de Application**
   - Abre `manifests/application.yaml`
   - Reemplaza `<GIT_REPOSITORY_URL>` con la URL real del repo
   - Nota: ya apunta a `workshop-app/k8s` como path

6. **Crear la Application en Argo CD**
   ```powershell
   kubectl apply -f .\manifests\application.yaml
   ```
   **Validación esperada**: application.argoproj.io/workshop-app created.

7. **Verificar que Argo CD sincroniza**
   ```powershell
   kubectl get application -n argocd
   kubectl describe application workshop-app -n argocd
   ```
   **Validación esperada**: Application en estado Synced, Health Healthy.

8. **Ver la app sincronizada en el namespace**
   ```powershell
   kubectl get all -n aks-workshop
   ```
   **Validación esperada**: Deployment y pods están, igual que con CI/CD pero gestionados por Argo CD.

9. **Demostración de GitOps: cambiar algo en Git y ver sync automático**
   - Modifica un valor en `workshop-app/k8s/configmap.yaml` (ej: ENVIRONMENT)
   - Haz commit y push
   - Vuelve a la UI de Argo CD y observa sync automático (unos 3-5 seg)
   - O ejecuta `kubectl apply -f ./manifests/application.yaml --force-sync`

### Errores típicos

- **Error: Argo CD no se instala**: verifica que la URL del manifest es correcta y hay acceso a internet.
- **Error: Application no sincroniza**: revisa que la URL del repo y path son correctos con `kubectl describe application`.
- **Error: Password no funciona**: borra el namespace y reinstala con `kubectl delete namespace argocd`.

## Resultado esperado
La aplicación queda gestionada de forma declarativa y los cambios en Git se reflejan en el clúster sin intervención manual.
