param(
  [Parameter(Mandatory = $true)]
  [string]$Namespace = 'aks-workshop',

  [Parameter(Mandatory = $true)]
  [string]$Deployment = 'workshop-app'
)

kubectl patch deployment $Deployment -n $Namespace -p '{"spec":{"template":{"metadata":{"annotations":{"lab/change":"gitops-demo"}}}}}'
