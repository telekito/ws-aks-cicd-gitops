# 07. Buenas Prácticas y Cierre

## Objetivo
Cerrar el workshop con recomendaciones prácticas para llevar el patrón a entornos reales.

## Contenido
- Separación de entornos (dev, staging, prod).
- Uso de ACR con políticas de imagen.
- Git como base de configuración.
- Seguridad base con Key Vault y secretos.

## Scripts y archivos
- `scripts/cleanup-workshop.ps1`: limpia namespaces del lab y de Argo CD para empezar de cero si lo necesitas.

## Recomendaciones por escenario

### Escenario 1: Equipo pequeño, 1-2 aplicaciones
```
Git (repo único)
  ├── app1/src
  ├── app1/Dockerfile
  ├── app2/src
  └── k8s/ (Kubernetes manifests for both)
    ├── app1-deployment.yaml
    ├── app2-deployment.yaml
    └── ...

CI/CD Pipeline: Build y push → ACR
GitOps: Argo CD sincroniza manifests
```

### Escenario 2: Equipo grande, multi-aplicación, multi-cluster
```
Repo 1: App1 (code + Dockerfile)
Repo 2: App2 (code + Dockerfile)
Repo 3: GitOps manifests (centralizado)
  ├── overlays/
  │   ├── dev/
  │   ├── staging/
  │   └── prod/
  └── apps/
      ├── app1/
      └── app2/

CI/CD: Build y push per app → ACR
GitOps: Argo ApplicationSet auto-sincroniza múltiples clusters
```

## Buenas prácticas de seguridad

1. **Secretos en Key Vault, no en Git**
   ```powershell
   # En lugar de hardcodear en configmap.yaml
   kubectl create secret generic db-credentials \
     --from-literal=username=admin \
     --from-literal=password=$(az keyvault secret show --name db-password --vault-name my-vault -o tsv)
   ```

2. **RBAC en Kubernetes**
   - Crear service accounts por aplicación.
   - Usar network policies para limitar tráfico.

3. **Imagen scanning en ACR**
   - Habilitar vulnerability scanning.
   - Rechazar imágenes con vulnerabilidades críticas.

4. **Auditoría y logs**
   - Habilitar Azure Monitor + Container Insights.
   - Centralizar logs en Log Analytics.

## Laboratorio final paso a paso

### Pasos de limpieza e integración

1. **Validar que ambos modelos están funcionando**
   ```powershell
   kubectl get all -n aks-workshop
   kubectl get application -n argocd
   ```

2. **Revisar la arquitectura implementada**
   ```powershell
   kubectl describe nodes
   kubectl get persistentvolumes
   ```

3. **Ejecutar limpieza completa** (si necesitas empezar de cero)
   ```powershell
   .\scripts\cleanup-workshop.ps1
   ```
   **Validación esperada**: namespaces borrados, clúster sin workloads del lab.

### Entregables finales

1. **Documentar tu decisión**: ¿CI/CD, GitOps o híbrido?
2. **Arquitectura del equipo**: ¿cómo organizan repos, pipelines, manifests?
3. **Checklist de seguridad**: qué controles hay en cada entorno.
4. **Plan de rollback**: cómo revertir cambios en caso de problema.

## Siguientes pasos recomendados

1. **Helm Charts**: templating avanzado para Kubernetes.
2. **Kustomize**: customización sin templating.
3. **Istio/Service Mesh**: trafficmanagement avanzado.
4. **Backup & Disaster Recovery**: Velero para backups.
5. **Cost Optimization**: autoscaling, rightsizing, Azure Advisor.

## Recursos útiles

- [Azure Kubernetes Service docs](https://docs.microsoft.com/azure/aks)
- [Argo CD documentation](https://argo-cd.readthedocs.io)
- [Kubernetes best practices](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [GitOps best practices](https://www.cncf.io/blog/2023/08/01/gitops-best-practices/)

## Resultado esperado
El participante termina con una visión práctica, coherente y aplicable del stack completo AKS + CI/CD + GitOps.
