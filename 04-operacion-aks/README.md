# 04. Operación de AKS

## Objetivo
Aprender a operar y diagnosticar una aplicación ya desplegada en AKS.

## Contenido
- Escalado de workloads.
- Escalado de node pools.
- Observabilidad: logs y métricas.
- Troubleshooting básico.

## Scripts y archivos
- `scripts/scale-deployment.ps1`: escala el Deployment del lab.
- `scripts/show-telemetry.ps1`: muestra métricas, eventos e historial de rollout.

## Laboratorio paso a paso

### Prerequisitos
- Tener módulo 2 o 3 completado (app desplegada)
- kubectl conectado al AKS
- Acceso al namespace de trabajo (`aks-workshop-pipeline` o `aks-workshop-argo`)

### Pasos

Define el namespace que vas a operar:

```powershell
$Namespace = 'aks-workshop-pipeline' # o 'aks-workshop-argo'
```

1. **Ver el estado actual de la app**
   ```powershell
   kubectl get all -n $Namespace
   ```
   **Validación esperada**: Deployment con 2 replicas, 2 pods running.

2. **Escalar manualmente el Deployment**
   ```powershell
   .\scripts\scale-deployment.ps1 -Namespace $Namespace -Deployment workshop-app -Replicas 4
   ```
   **Validación esperada**: ReplicaSet actualizado, 4 pods en Running tras esperar unos segundos.

3. **Ver el estado después del escalado**
   ```powershell
   kubectl get deploy,pods -n $Namespace
   ```
   **Validación esperada**: Deployment con 4 replicas, 4 pods.

4. **Ver métricas y observabilidad**
   ```powershell
   .\scripts\show-telemetry.ps1 -Namespace $Namespace
   ```
   **Validación esperada**: muestra top pods, nodos, eventos y rollout history.

5. **Ver logs de uno de los pods**
   ```powershell
   $POD = kubectl get pods -n $Namespace -o jsonpath='{.items[0].metadata.name}'
   kubectl logs $POD -n $Namespace
   ```
   **Validación esperada**: logs del servidor HTTP sin errores.

6. **Monitorear eventos en tiempo real**
   ```powershell
   kubectl get events -n $Namespace --watch
   ```
   **Validación esperada**: ves eventos de scaling, creación de pods, etc. Presiona Ctrl+C para salir.

7. **Escalar de nuevo hacia abajo**
   ```powershell
   .\scripts\scale-deployment.ps1 -Namespace $Namespace -Deployment workshop-app -Replicas 2
   ```
   **Validación esperada**: ReplicaSet termina pods hasta llegar a 2 replicas.

8. **Comprobar auto-healing (solo si Argo CD está activo)**
   ```powershell
   # Borra un pod manualmente
   $POD = kubectl get pods -n $Namespace -o jsonpath='{.items[0].metadata.name}'
   kubectl delete pod $POD -n $Namespace
   # Espera unos segundos
   kubectl get pods -n $Namespace
   ```
   **Validación esperada**: Kubernetes crea un nuevo pod para reemplazarlo inmediatamente.
   Si tienes Argo CD: además, Argo sincroniza el desired state.

### Errores típicos

- **Error: Pods no escalan**: verifica que hay recursos disponibles en los nodos con `kubectl top nodes`.
- **Error: Metrics no disponibles**: es normal si no hay metrics-server instalado. Continúa sin ellas.
- **Error: Pod termina y no se reinicia**: revisa logs con `kubectl logs <pod>` y `kubectl describe pod <pod>`.

## Resultado esperado
El participante puede diagnosticar, escalar y entender el comportamiento operativo del clúster, y ve cómo Kubernetes auto-repara despliegues.
