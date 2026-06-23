# 01. Kubernetes & AKS Essentials

## Objetivo
Comprender los conceptos base de Kubernetes, conectarse a Azure Kubernetes Service (AKS) y estar listo para desplegar aplicaciones.

## Contenido
- Qué problema resuelve Kubernetes
- Arquitectura: control plane gestionado por AKS y nodes
- Objetos principales: Pods, Deployments, Services, Namespaces
- Conceptos de apoyo: ConfigMaps, Secrets
- Conexión a AKS y exploración del clúster
- Despliegue y diagnóstico de aplicaciones

## Scripts y archivos
- `scripts/connect-aks.ps1`: obtiene credenciales y conecta kubectl al clúster AKS
- `scripts/aks-overview.ps1`: muestra resumen de nodos, workloads y eventos
- `scripts/kubectl-basics.ps1`: referencia rápida de comandos kubectl esenciales
- `scripts/inspect-workload.ps1`: inspecciona pods y logs en un namespace
- `scripts/deploy-app.ps1`: despliega la aplicación workshop en Kubernetes

## Laboratorio paso a paso

### Prerequisitos
- Tener acceso a una suscripción de Azure: `az account show`
- Conocer el nombre del clúster AKS y su grupo de recursos
- Tener Azure CLI y kubectl instalados (desde el módulo 00)

### Pasos

#### Fase 1: Conectar a AKS

1. **Verificar acceso a Azure**
   ```powershell
   az account show
   ```
   **Validación esperada**: deberías ver tu suscripción, cuenta y tenant ID.

2. **Conectarse al clúster AKS**
   ```powershell
   $ResourceGroup = '<AKS_RESOURCE_GROUP>'      # ej: aks-workshop-rg-123
   $ClusterName = '<AKS_CLUSTER_NAME>'          # ej: aks-cluster-123
   
   .\scripts\connect-aks.ps1 -ResourceGroup $ResourceGroup -ClusterName $ClusterName
   ```
   **Validación esperada**: contexto actualizado, verás algo como `aks-cluster-123`.

3. **Verificar el contexto actual**
   ```powershell
   kubectl config current-context
   kubectl cluster-info
   ```
   **Validación esperada**: endpoint del control plane (gestionado por Azure).

#### Fase 2: Explorar el Clúster

4. **Explorar los nodos del clúster**
   ```powershell
   kubectl get nodes -o wide
   ```
   **Validación esperada**: 1 o más nodos en estado Ready, con IPs internas y versión de Kubernetes.

5. **Explorar namespaces existentes**
   ```powershell
   kubectl get namespace
   ```
   **Validación esperada**: namespaces default, kube-system, kube-public, kube-node-lease.

6. **Ejecutar overview completo**
   ```powershell
   .\scripts\aks-overview.ps1
   ```
   **Validación esperada**: resumen de nodos, workloads y eventos sin errores.

#### Fase 3: Preparar el Entorno de Laboratorio

7. **Crear el namespace del lab**
   ```powershell
   kubectl create namespace aks-workshop --dry-run=client -o yaml | kubectl apply -f -
   ```
   **Validación esperada**: `namespace/aks-workshop created` (o `unchanged` si ya existe).

8. **Confirmar acceso al namespace**
   ```powershell
   kubectl get namespace aks-workshop
   ```
   **Validación esperada**: `aks-workshop` con STATUS `Active`.

#### Fase 4: Desplegar la Aplicación Workshop

9. **Desplegar la app (requiere que workshop-config.json exista desde módulo 00)**
   ```powershell
   .\scripts\deploy-app.ps1 -Namespace aks-workshop
   ```
   **Validación esperada**: todos los recursos aplicados sin error.

10. **Esperar a que el Deployment esté listo** (tarda 30-60 segundos)
    ```powershell
    kubectl rollout status deployment/workshop-app -n aks-workshop
    ```
    **Validación esperada**: `deployment "workshop-app" successfully rolled out`.

11. **Listar recursos del namespace**
    ```powershell
    kubectl get all -n aks-workshop
    ```
    **Validación esperada**: Deployment, ReplicaSet, 2 Pods en Running, 1 Service LoadBalancer.

#### Fase 5: Inspeccionar y Diagnosticar

12. **Obtener nombre del primer pod**
    ```powershell
    $POD_NAME = kubectl get pods -n aks-workshop -o jsonpath='{.items[0].metadata.name}'
    Write-Host $POD_NAME
    ```
    **Validación esperada**: nombre tipo `workshop-app-xxxxxx-xxxxx`.

13. **Describir un pod**
    ```powershell
    kubectl describe pod $POD_NAME -n aks-workshop
    ```
    **Validación esperada**: detalles del pod, estado, eventos, variables de ambiente.

14. **Ver logs del pod**
    ```powershell
    kubectl logs $POD_NAME -n aks-workshop
    ```
    **Validación esperada**: `<APP_NAME> listening on port 3000`.

15. **Obtener la IP pública del servicio**
    ```powershell
    kubectl get svc workshop-app -n aks-workshop
    ```
    **Validación esperada**: tipo `LoadBalancer` con `EXTERNAL-IP` (puede tardar 2-3 minutos en asignarse).

16. **Acceder a la aplicación**
    Una vez que EXTERNAL-IP aparezca:
    ```powershell
    $EXTERNAL_IP = kubectl get svc workshop-app -n aks-workshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    Start-Process "http://$EXTERNAL_IP"
    ```
    **Validación esperada**: página web interactiva de la app con información del pod.

#### Opcional: Script de Referencia

17. **Ver comandos kubectl esenciales**
    ```powershell
    .\scripts\kubectl-basics.ps1
    ```

### Errores típicos

| Error | Causa | Solución |
|-------|-------|----------|
| `Error: kubeconfig: no such file` | kubectl no está conectado a AKS | Ejecuta `connect-aks.ps1` con parámetros correctos |
| `Pods no están Ready` | imagen no se descargó o ACR credenciales inválidas | Verifica logs: `kubectl logs <pod> -n aks-workshop` |
| `EXTERNAL-IP pending` | Azure aún no asignó IP pública | Espera 2-3 minutos y vuelve a ejecutar `kubectl get svc` |
| `Error: image pull error` | ACR credenciales incorrectas o imagen no existe | Verifica: `az acr repository show-tags --name <acr> --repository workshop-app` |
| `Permission denied` | permisos RBAC insuficientes | Contacta a tu administrador AKS |

## Conceptos clave

### Kubernetes
- **Pod**: Unidad más pequeña, envuelve uno o más contenedores
- **Deployment**: Define cuántas replicas del pod deben estar corriendo
- **Service**: Expone pods con balanceo de carga (ClusterIP, NodePort, LoadBalancer)
- **Namespace**: Aislamiento lógico de recursos
- **ConfigMap**: Datos de configuración (no secretos)
- **Secret**: Datos sensibles (contraseñas, tokens)

### AKS
- **Control Plane**: Gestionado por Azure (no tienes nodos dedicados a esto)
- **Node Pools**: Grupos de nodos con la misma configuración
- **RBAC**: Control de acceso basado en roles (integrado con Entra ID de Azure)
- **Escalado**: Automático con Kubernetes Autoscaler o manual

## Resultado esperado
Al finalizar este módulo:
- ✓ Puedes conectarte a AKS con kubectl
- ✓ Entiendes la arquitectura de Kubernetes y AKS
- ✓ Puedes desplegar, inspeccionar y diagnosticar aplicaciones
- ✓ La aplicación workshop está accesible con IP pública

## Siguiente módulo
Ir a `02-azure-devops-cicd/` para configurar despliegues automatizados mediante CI/CD.
