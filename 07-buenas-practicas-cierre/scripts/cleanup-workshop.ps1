param(
  [string]$Namespace = 'aks-workshop',
  [string]$ArgoNamespace = 'argocd'
)

kubectl delete namespace $Namespace --ignore-not-found
kubectl delete namespace $ArgoNamespace --ignore-not-found
