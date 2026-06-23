#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Connect to an Azure Kubernetes Service (AKS) cluster.

.DESCRIPTION
    Retrieves credentials for an AKS cluster and configures kubectl context.

.PARAMETER ResourceGroup
    Name of the Azure resource group containing the AKS cluster (required).

.PARAMETER ClusterName
    Name of the AKS cluster (required).

.PARAMETER SubscriptionId
    Optional subscription ID. If not provided, uses the currently set subscription.

.EXAMPLE
    .\connect-aks.ps1 -ResourceGroup "aks-workshop-rg-123" -ClusterName "aks-cluster-123"

.EXAMPLE
    .\connect-aks.ps1 -ResourceGroup "aks-workshop-rg-123" -ClusterName "aks-cluster-123" -SubscriptionId "12345678-1234-1234-1234-123456789012"
#>

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
