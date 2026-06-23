# 01. Kubernetes Essentials

## Objetivo
Entender los conceptos base de Kubernetes que se usan durante todo el workshop.

## Contenido
- Qué problema resuelve Kubernetes.
- Arquitectura básica: control plane y nodes.
- Objetos principales: Pods, Deployments y Services.
- Conceptos de apoyo: Namespaces, ConfigMaps y Secrets.
- Comandos esenciales para inspeccionar y diagnosticar.

## Scripts y archivos
- `scripts/kubectl-basics.ps1`: resumen rápido del estado del clúster y del namespace del lab.
- `scripts/inspect-workload.ps1`: inspección de pod y logs.

## Laboratorio paso a paso

### Prerequisitos
- Tener conexión activa a un clúster AKS (`kubectl config current-context`)

### Pasos

1. **Verificar acceso al clúster**
   ```powershell
   kubectl cluster-info
   kubectl get nodes
   ```
   **Validación esperada**: deberías ver 1 o más nodos en estado Ready.

2. **Listar namespaces existentes**
   ```powershell
   kubectl get namespace
   ```
   **Validación esperada**: deberías ver default, kube-system, kube-public, kube-node-lease, al menos.

3. **Crear el namespace del lab** (si no existe)
   ```powershell
   kubectl create namespace aks-workshop --dry-run=client -o yaml | kubectl apply -f -
   ```
   **Validación esperada**: namespace/aks-workshop created (o unchanged).

4. **Desplegar la app base para inspeccionar**
   ```powershell
   kubectl apply -f ..\..\workshop-app\k8s\namespace.yaml
   kubectl apply -f ..\..\workshop-app\k8s\configmap.yaml
   kubectl apply -f ..\..\workshop-app\k8s\deployment.yaml
   kubectl apply -f ..\..\workshop-app\k8s\service.yaml
   ```
   **Validación esperada**: todos los recursos aplicados sin error.

5. **Esperar a que el Deployment esté listo** (tarda 30-60 seg)
   ```powershell
   kubectl rollout status deployment/workshop-app -n aks-workshop
   ```
   **Validación esperada**: `deployment "workshop-app" successfully rolled out`.

6. **Listar recursos del namespace**
   ```powershell
   kubectl get all -n aks-workshop
   ```
   **Validación esperada**: deberías ver Deployment, ReplicaSet, Pods (2), Service.

7. **Inspeccionar un pod específico**
   ```powershell
   # Obtén el nombre del primer pod
   $POD_NAME = kubectl get pods -n aks-workshop -o jsonpath='{.items[0].metadata.name}'
   kubectl describe pod $POD_NAME -n aks-workshop
   ```
   **Validación esperada**: deberías ver detalles del pod, ambiente, eventos.

8. **Ver los logs del pod**
   ```powershell
   kubectl logs $POD_NAME -n aks-workshop
   ```
   **Validación esperada**: deberías ver `<APP_NAME> listening on port 3000`.

9. **Revisar el Service y acceso**
   ```powershell
   kubectl get svc -n aks-workshop
   ```
   **Validación esperada**: workshop-app con ClusterIP y puerto 80.

### Errores típicos

- **Error: `kubectl config current-context`**: asegúrate de haber corrido `connect-aks.ps1` del módulo 2.
- **Error: Pods no están Ready**: espera unos segundos y vuelve a ejecutar el rollout status.
- **Error: No hay acceso al namespace**: verifica permisos RBAC con tu instructor.

## Resultado esperado
El participante sabe identificar qué está pasando en un clúster, entiende los objetos Kubernetes base y puede diagnosticar un problema con `kubectl`.
