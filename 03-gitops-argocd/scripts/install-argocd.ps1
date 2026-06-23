param(
  [string]$Namespace = 'argocd'
)

kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n $Namespace -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment/argocd-server -n $Namespace --timeout=10m
