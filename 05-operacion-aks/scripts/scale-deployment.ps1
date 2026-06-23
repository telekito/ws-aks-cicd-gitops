param(
  [Parameter(Mandatory = $true)]
  [string]$Namespace,

  [Parameter(Mandatory = $true)]
  [string]$Deployment,

  [Parameter(Mandatory = $true)]
  [int]$Replicas
)

kubectl scale deployment $Deployment --replicas=$Replicas -n $Namespace
kubectl get deploy,pods -n $Namespace
