# 05. Comparativa: CI/CD vs GitOps

## Objetivo
Entender cuándo usar Azure DevOps y cuándo usar GitOps con Argo CD.

## Contenido
- Modelo push vs modelo pull.
- Pipeline ejecuta cambios vs clúster sincroniza estado.
- Más control en pipeline vs más control en ejecución.
- Delivery vs operación.

## Scripts y archivos
- `scripts/change-image-tag.ps1`: simula un cambio de versión estilo CI/CD.
- `scripts/simulate-gitops-change.ps1`: simula un cambio declarativo sobre el despliegue.

## Comparativa de modelos

| Aspecto | CI/CD (Azure DevOps) | GitOps (Argo CD) |
|--------|----------------------|------------------|
| **Modelo** | Push | Pull |
| **Trigger** | Código en repo | Manifest en repo |
| **Ejecución** | Pipeline ejecuta cambios | Clúster sincroniza desired state |
| **Control** | Control total en pipeline | Control en ejecución |
| **Speed** | Rápido, tras trigger | Automático pero configurable |
| **Rollback** | Re-ejecutar pipeline | Git revert + auto-sync |
| **Multi-cluster** | Múltiples pipelines | Una Application por cluster |
| **Auditoría** | Pipeline logs | Git history |

## Laboratorio paso a paso

### Prerequisitos
- Tener módulos 3 y 4 completados (ambos despliegues funcionando)

### Pasos

1. **Entender el estado actual**
   ```powershell
   kubectl get all -n aks-workshop
   kubectl get application -n argocd
   ```
   **Validación esperada**: Deployment desplegado, posiblemente gestionado por ambos modelos.

2. **Demo: cambio con CI/CD**
   - Modifica `workshop-app/package.json` o `src/server.js`
   - Haz commit y push
   - El pipeline se ejecuta automáticamente
   - La app se redeploya con la nueva imagen
   ```powershell
   kubectl get events -n aks-workshop --sort-by=.metadata.creationTimestamp | tail -5
   ```
   **Validación esperada**: ves eventos de update y rollout.

3. **Demo: cambio con GitOps**
   - Modifica `workshop-app/k8s/deployment.yaml` (ej: cambias ENVIRONMENT en configmap.yaml)
   - Haz commit y push
   - Argo CD sincroniza automáticamente (3-5 seg)
   ```powershell
   kubectl get application workshop-app -n argocd -o jsonpath='{.status.sync.status}'
   ```
   **Validación esperada**: Synced.

4. **Comprobar qué cambió en cada caso**
   ```powershell
   kubectl describe deployment workshop-app -n aks-workshop
   kubectl logs $(kubectl get pods -n aks-workshop -o jsonpath='{.items[0].metadata.name}') -n aks-workshop
   ```
   **Validación esperada**: image tag es diferente en CI/CD, config es diferente en GitOps.

### Cuándo usar cada modelo

#### Usar CI/CD (Azure DevOps) cuando:
- Necesitas construir y testear aplicaciones antes de desplegar.
- Tienes procesos complejos de build.
- Integración con sistemas de calidad y compliance.
- Diferentes equipos: Dev construye, Ops despliega.
- Necesitas control total sobre cuándo se despliega.

#### Usar GitOps (Argo CD) cuando:
- Quieres Git como fuente única de verdad.
- Necesitas auditoría completa en historial de Git.
- Multi-cluster / multi-entorno sin duplicar pipelines.
- Quieres auto-healing y reconciliación automática.
- El equipo prefiere pull-based deployment.

### Modelo híbrido (recomendado)
- **CI/CD** para build, test y publicar imagen → ACR.
- **GitOps** para gestionar despliegues declarativamente → Kubernetes manifests en Git.

