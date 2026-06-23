param(
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroup,

  [Parameter(Mandatory = $true)]
  [string]$ClusterName,

  [string]$SubscriptionId
)

if ($SubscriptionId) {
  az account set --subscription $SubscriptionId
}

az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing
kubectl config current-context
