param(
  [string]$Namespace = 'aks-workshop'
)

kubectl top pods -n $Namespace
kubectl top nodes
kubectl rollout history deployment/workshop-app -n $Namespace
kubectl get events -n $Namespace --sort-by=.metadata.creationTimestamp
