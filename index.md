# AKS From Zero to Hero

Workshop de 4 horas orientado a hands-on lab para trabajar AKS en un contexto real con dos modelos de despliegue:
CI/CD con Azure DevOps y GitOps con Argo CD.

## Objetivo

- Entender AKS en un contexto práctico.
- Desplegar aplicaciones con Azure DevOps (CI/CD).
- Desplegar aplicaciones con GitOps usando Argo CD.
- Comprender cuándo usar cada modelo.

## Prerequisitos

Antes de comenzar, asegurate de que tienes:

- **Azure CLI**: instalado y autenticado (`az login`)
- **kubectl**: instalado (versión 1.20+)
- **Docker** (opcional): solo si vas a hacer build local
- **PowerShell**: versión 5.1 o superior (Core recomendado)
- **Clúster AKS**: ya existe o hay permisos para crearlo
- **ACR**: un registro de contenedores de Azure ya existe o hay permisos para crearlo
- **Azure DevOps**: con acceso a un proyecto (para el módulo 3)
- **Git**: acceso a un repositorio para GitOps (módulo 4)

## Estructura

Cada bloque del workshop vive en su propia carpeta para separar contenido, ejercicios y recursos.

1. [Kubernetes essentials](01-kubernetes-essentials/README.md) — 25-30 min
2. [AKS: base de trabajo](02-aks-base/README.md) — 35-40 min
3. [Despliegue con Azure DevOps](03-azure-devops-cicd/README.md) — 45 min
4. [Despliegue con GitOps y Argo CD](04-gitops-argocd/README.md) — 50 min
5. [Operación de AKS](05-operacion-aks/README.md) — 40-45 min
6. [Comparativa: CI/CD vs GitOps](06-comparativa/README.md) — 15 min
7. [Buenas prácticas y cierre](07-buenas-practicas-cierre/README.md) — 15-20 min

## Configuración de valores iniciales

Antes de ejecutar cualquier módulo, debes definir tus valores de Azure. Reemplaza estos placeholders en los scripts y manifiestos:

- `<ACR_NAME>`: nombre de tu Azure Container Registry sin .azurecr.io (ej: micontainer)
- `<AKS_RESOURCE_GROUP>`: nombre del grupo de recursos (ej: mi-rg)
- `<AKS_CLUSTER_NAME>`: nombre del clúster AKS (ej: mi-aks)
- `<AZURE_DEVOPS_SERVICE_CONNECTION>`: nombre de la conexión de servicio en Azure DevOps
- `<AZURE_DEVOPS_SERVICE_CONNECTION_TO_ACR>`: nombre de la conexión de Docker en Azure DevOps
- `<GIT_REPOSITORY_URL>`: URL completa del repositorio Git (para GitOps)

## Flujo del workshop

```
Módulo 1 & 2: Entender AKS y kubectl (conexión)
           ↓
Módulo 3: Desplegar con CI/CD (push model)
           ↓
Módulo 4: Desplegar con GitOps (pull model)
           ↓
Módulo 5: Operar, escalar, diagnosticar
           ↓
Módulo 6: Comparar modelos y decidir
           ↓
Módulo 7: Limpieza y siguientes pasos
```

## Guía de uso

- Cada carpeta contiene README con pasos detallados, scripts y manifiestos.
- Los scripts están en PowerShell (.ps1) y son reutilizables.
- Los manifiestos en `workshop-app/k8s/` se aplican en todos los módulos.
- La app de ejemplo es una HTTP simple con health checks.

## Errores comunes

- **Placeholders sin reemplazar**: asegurate de cambiar todos los `<...>` por valores reales.
- **Contexto de kubectl incorrecto**: verifica `kubectl config current-context`.
- **Namespace no existe**: los scripts aplican namespace.yaml primero.
- **Permisos insuficientes**: confirma acceso a ACR, AKS y Azure DevOps.

## Soporte y diagnóstico

Si algo falla, revisa:
1. Los pasos detallados en cada README.
2. Los errores típicos documentados en cada módulo.
3. Ejecuta `kubectl get events -n aks-workshop` para ver qué pasó en el clúster.