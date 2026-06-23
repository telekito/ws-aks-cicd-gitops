# 02. AKS: Base de Trabajo

## Objetivo
Entender qué aporta AKS frente a Kubernetes autogestionado y dejar listo el entorno base del lab.

## Contenido
- AKS como servicio gestionado.
- Control plane gestionado.
- Node pools y escalado.
- Integraciones: Entra ID, RBAC y Azure Monitor.

## Scripts y archivos
- `scripts/connect-aks.ps1`: obtiene credenciales del clúster AKS.
- `scripts/aks-overview.ps1`: muestra nodos, workloads y eventos del namespace.

## Laboratorio paso a paso

### Prerequisitos
- Tener acceso a una suscripción de Azure (`az account show`)
- Conocer el nombre del AKS (`<AKS_CLUSTER_NAME>`) y su grupo de recursos (`<AKS_RESOURCE_GROUP>`)

### Pasos

1. **Verificar acceso a Azure**
   ```powershell
   az account show
   ```
   **Validación esperada**: deberías ver tu suscripción, cuenta y tenant.

2. **Conectarse al clúster AKS**
   ```powershell
   $ResourceGroup = '<AKS_RESOURCE_GROUP>'
   $ClusterName = '<AKS_CLUSTER_NAME>'
   .\scripts\connect-aks.ps1 -ResourceGroup $ResourceGroup -ClusterName $ClusterName
   ```
   **Validación esperada**: contexto actualizado en kubectl, ej: `aks-<cluster-name>`.

3. **Verificar el contexto actual**
   ```powershell
   kubectl config current-context
   ```
   **Validación esperada**: deberías ver algo como `aks-<cluster-name>`.

4. **Explorar los nodos del clúster**
   ```powershell
   kubectl get nodes -o wide
   ```
   **Validación esperada**: 1 o más nodos en estado Ready, con IPs internas y versión de Kubernetes.

5. **Ver información del clúster**
   ```powershell
   kubectl cluster-info
   ```
   **Validación esperada**: endpoint del control plane (gestionado por Azure).

6. **Explorar namespaces**
   ```powershell
   kubectl get namespace
   ```
   **Validación esperada**: namespace default, kube-system, kube-public, etc.

7. **Ejecutar el script de overview completo**
   ```powershell
   .\scripts\aks-overview.ps1
   ```
   **Validación esperada**: resumen de nodos, workloads y eventos sin errores.

8. **Crear el namespace del lab** (si no existe)
   ```powershell
   kubectl create namespace aks-workshop --dry-run=client -o yaml | kubectl apply -f -
   ```
   **Validación esperada**: namespace/aks-workshop created.

9. **Confirmar acceso al namespace**
   ```powershell
   kubectl get namespace aks-workshop
   ```
   **Validación esperada**: NAME STATUS con aks-workshop Active.

### Errores típicos

- **Error: `az login` sin usuario**: ejecuta `az login` y sigue el flujo de autenticación interactiva.
- **Error: clúster no encontrado**: verifica el nombre del grupo de recursos y clúster con `az aks list`.
- **Error: contexto no se actualiza**: ejecuta `kubectl config get-contexts` para ver todos los disponibles.

## Resultado esperado
El participante puede conectarse a AKS, entiende el modelo de control plane gestionado y está listo para desplegar en el siguiente módulo.
