#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Display an overview of the AKS cluster.

.DESCRIPTION
    Shows cluster nodes, workloads, and events for a given namespace.

.PARAMETER Namespace
    Kubernetes namespace to inspect. Defaults to 'aks-workshop'.

.EXAMPLE
    .\aks-overview.ps1

.EXAMPLE
    .\aks-overview.ps1 -Namespace "default"
#>

param(
  [string]$Namespace = 'aks-workshop'
)

Write-Host 'Cluster nodes:' -ForegroundColor Cyan
kubectl get nodes -o wide

Write-Host "`nWorkloads:" -ForegroundColor Cyan
kubectl get all -n $Namespace

Write-Host "`nEvents:" -ForegroundColor Cyan
kubectl get events -n $Namespace --sort-by=.metadata.creationTimestamp
