# Workshop Facilitator Checklist

## Antes del workshop

### Preparación de infraestructura (1-2 días antes)
- [ ] AKS cluster creado y accesible
- [ ] ACR registry creado
- [ ] Azure DevOps project con acceso a todos los participantes
- [ ] Git repo creado para GitOps (con contenido de workshop-app/k8s)
- [ ] Conexiones de servicio configuradas en Azure DevOps:
  - [ ] Conexión ARM para AKS
  - [ ] Conexión Docker para ACR

### Preparación de materiales (día anterior)
- [ ] Todos los placeholders (`<ACR_NAME>`, etc.) documentados para los participantes
- [ ] Scripts PowerShell copiados a máquinas de participantes o acceso compartido
- [ ] Manifiestos YAML revisados y listos
- [ ] `azure-pipelines.yml` con placeholders claros

### Comunicación a participantes
- [ ] Enviar [índice.md](index.md) con prerequisitos
- [ ] Aclarar qué tools necesitan instalados (Azure CLI, kubectl, PowerShell)
- [ ] Dar acceso a repos (código + GitOps)

## Durante el workshop

### Módulo 1 (25-30 min)
- [ ] Explicar conceptos Kubernetes base
- [ ] Ejecutar `kubectl-basics.ps1` juntos
- [ ] Particip ejecuta `inspect-workload.ps1` en su máquina
- [ ] **Checkpoint**: todos ven 2 pods running

### Módulo 2 (35-40 min)
- [ ] Explicar qué aporta AKS
- [ ] Particip corre `connect-aks.ps1` con sus valores
- [ ] Particip corre `aks-overview.ps1`
- [ ] **Checkpoint**: todos logueados en el mismo clúster

### Módulo 3 (45 min)
- [ ] Explicar pipeline CI/CD
- [ ] Revisar `azure-pipelines.yml` línea por línea
- [ ] Opcional: ejecutar `build-image.ps1` localmente
- [ ] Ejecutar `deploy-to-aks.ps1` para despliegue manual
- [ ] **Checkpoint**: app desplegada y accesible

### Módulo 4 (50 min)
- [ ] Explicar GitOps y Argo CD
- [ ] Particip corre `install-argocd.ps1`
- [ ] Acceso a UI de Argo CD (port-forward)
- [ ] Aplicar `application.yaml`
- [ ] **Checkpoint**: App sincronizada en Argo CD

### Módulo 5 (40-45 min)
- [ ] Explicar operación y escalado
- [ ] Particip corre `scale-deployment.ps1` a 4 replicas
- [ ] Particip corre `show-telemetry.ps1`
- [ ] Demo: Argo auto-heal (borrar un pod)
- [ ] **Checkpoint**: auto-healing verificado

### Módulo 6 (15 min)
- [ ] Comparativa tabla en README
- [ ] Resumen: cuándo usar cada modelo
- [ ] Preguntas abiertas del grupo

### Módulo 7 (15-20 min)
- [ ] Recomendaciones finales
- [ ] Checklist de seguridad
- [ ] Recursos para continuar aprendiendo
- [ ] Cleanup opcional con `cleanup-workshop.ps1`

## Después del workshop

### Encuesta y feedback (5 min)
- [ ] Distribuir encuesta de satisfacción
- [ ] Recopilar feedback sobre cada módulo

### Documentación
- [ ] Guardar logs de ejecución
- [ ] Notar qué módulos tomaron más tiempo
- [ ] Problemas encontrados y cómo resolverlos

## Troubleshooting rápido

| Problema | Solución |
|----------|----------|
| kubectl context vacío | Ejecutar `connect-aks.ps1` con parámetros correctos |
| App pods en CrashLoopBackOff | Ver logs: `kubectl logs <pod>`, revisar Dockerfile |
| Argo CD no sincroniza | Verificar URL del repo y credenciales Git |
| Permisos insuficientes | Contactar al admin de Azure/DevOps |
| No hay connectivity | Comprobar `kubectl cluster-info` |

## Tiempos reales (estimados)

- Módulo 1: 30 min (con deployment)
- Módulo 2: 40 min (si hay retrasos en conexión)
- Módulo 3: 50 min (build + deploy)
- Módulo 4: 60 min (instalación de Argo + UI)
- Módulo 5: 35 min (demos rápidas)
- Módulo 6: 10 min (comparativa)
- Módulo 7: 15 min (cierre)

**Total**: 240 min aprox. (puede variar ±30 min)

## Notas del facilitador

- Mantener velocidad: si alguien se atrasa, ayudarlo en paralelo
- Enfatizar: CI/CD vs GitOps no son excluyentes
- Demo live si es posible (código → commit → pipeline)
- Recordar: "todos aprenderemos de los errores"
