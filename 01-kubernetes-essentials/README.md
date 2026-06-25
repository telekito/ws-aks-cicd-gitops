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

### Objetos Principales de Kubernetes

#### Workloads (Cargas de Trabajo)
- **Pod**: La unidad más pequeña en Kubernetes. Es un wrapper alrededor de uno o más contenedores (típicamente uno). Los pods comparten recursos de red y almacenamiento. No se crean directamente; se gestionan a través de Deployments.
  
- **Deployment**: Objeto de nivel superior que define y gestiona réplicas de pods. Proporciona actualizaciones sin interrución (rolling updates), reversiones y escalado. Es el recurso más común para aplicaciones stateless.

- **StatefulSet**: Similar a Deployment pero para aplicaciones stateful (como bases de datos). Garantiza identidades de red estables y almacenamiento persistente para cada pod.

- **DaemonSet**: Asegura que una copia de un pod se ejecute en cada nodo del clúster. Útil para tareas de monitoreo, logging y recolección de métricas.

- **Job**: Ejecuta una tarea hasta su finalización. Útil para procesos batch o trabajos puntuales.

#### Exposición de Servicios
- **Service**: Abstracción que expone pods con balanceo de carga y descubrimiento de servicios. Tipos:
  - **ClusterIP** (default): Expone el servicio solo dentro del clúster
  - **NodePort**: Expone el servicio en cada nodo en un puerto específico
  - **LoadBalancer**: Asigna una IP pública externa (en AKS, crea un Load Balancer de Azure)

- **Ingress**: Gestiona acceso HTTP/HTTPS externo a múltiples servicios. Proporciona enrutamiento por hostname y path.

#### Gestión de Configuración
- **ConfigMap**: Almacena datos de configuración en pares clave-valor. Se inyecta en pods como variables de entorno o archivos.

- **Secret**: Similar a ConfigMap pero para datos sensibles (contraseñas, tokens, certificados). Codificados en base64 (cifrado en etcd cuando está habilitado).

#### Organización
- **Namespace**: Aislamiento lógico de recursos dentro de un clúster. Permite multi-tenancy y control de acceso granular. Namespaces principales:
  - `default`: namespace por defecto
  - `kube-system`: componentes del sistema de Kubernetes
  - `kube-public`: recursos públicos

#### Escalado Automático
- **HPA (Horizontal Pod Autoscaler)**: Escala automáticamente el número de réplicas de un Deployment basado en métricas (CPU, memoria, métricas personalizadas). Rango configurable de mínimo/máximo de pods.
  ```yaml
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: workshop-app-hpa
  spec:
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: workshop-app
    minReplicas: 2
    maxReplicas: 10
    metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
  ```

- **VPA (Vertical Pod Autoscaler)**: Ajusta automáticamente solicitudes de recursos (CPU/memoria) de los contenedores basándose en uso real.

### Azure Kubernetes Service (AKS)

- **Control Plane**: Componentes maestros de Kubernetes (API Server, etcd, scheduler) gestionados completamente por Azure. No incurres en costos de nodos para estos.

- **Node Pools**: Grupos de nodos con la misma configuración (tamaño VM, SO, etiquetas). Un clúster puede tener múltiples node pools para diferentes tipos de workloads (pools de computación intensiva, GPU, etc.).

- **RBAC (Role-Based Access Control)**: Control de acceso granular integrado con Azure Entra ID. Permite:
  - Roles predefinidos: `view`, `edit`, `admin`
  - Roles personalizados
  - Vinculación con identidades de Azure

- **Escalado**: Dos niveles:
  - **Escalado horizontal** (HPA): Aumenta/disminuye el número de pods
  - **Escalado de nodos** (Cluster Autoscaler): Aumenta/disminuye el número de nodos VM en el clúster

- **ACR (Azure Container Registry)**: Registro privado de imágenes Docker. AKS puede autenticarse automáticamente para descargar imágenes.

- **Managed Identity**: Identidades gestionadas por Azure para que AKS acceda a otros recursos Azure (ACR, Key Vault, Storage) sin credenciales explícitas.

## Resultado esperado
Al finalizar este módulo:
- ✓ Puedes conectarte a AKS con kubectl
- ✓ Entiendes la arquitectura de Kubernetes y AKS
- ✓ Puedes desplegar, inspeccionar y diagnosticar aplicaciones
- ✓ La aplicación workshop está accesible con IP pública

## Siguiente módulo
Ir a `02-azure-devops-cicd/` para configurar despliegues automatizados mediante CI/CD.
