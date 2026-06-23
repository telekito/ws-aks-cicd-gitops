param(
  [string]$Namespace = 'argocd'
)

kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n $Namespace -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment/argocd-server -n $Namespace --timeout=10m

# Patch service to LoadBalancer for public IP access
Write-Host ""
Write-Host "Configurando acceso público a Argo CD..."
kubectl patch svc argocd-server -n $Namespace -p '{"spec":{"type":"LoadBalancer"}}'

Write-Host ""
Write-Host "✅ Argo CD instalado exitosamente con acceso público."
Write-Host ""
Write-Host "Para obtener la IP pública del servicio:"
Write-Host "  kubectl get svc argocd-server -n $Namespace -o wide"
Write-Host ""
