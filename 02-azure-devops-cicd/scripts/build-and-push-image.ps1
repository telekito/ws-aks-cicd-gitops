#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build and push the workshop app Docker image to Azure Container Registry (ACR).

.DESCRIPTION
    This script builds the workshop app Docker image locally and pushes it to the ACR.
    It reads configuration from workshop-config.json created during infrastructure deployment.

.PARAMETER ConfigPath
    Path to the workshop configuration file. Defaults to workshop-config.json in the script directory.

.PARAMETER ImageTag
    Optional custom image tag. Defaults to 'latest'.

.PARAMETER SkipPush
    If specified, only builds the image without pushing to ACR.

.EXAMPLE
    .\build-and-push-image.ps1
    # Builds and pushes image with 'latest' tag

.EXAMPLE
    .\build-and-push-image.ps1 -ImageTag "v1.0"
    # Builds and pushes image with 'v1.0' tag

.EXAMPLE
    .\build-and-push-image.ps1 -SkipPush
    # Only builds the image locally without pushing
#>

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "workshop-config.json"),
    [string]$ImageTag = "latest",
    [switch]$SkipPush
)

# Color functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Check if config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    Write-Info "Please run 00-setup\deploy-infrastructure.ps1 first to create the configuration."
    exit 1
}

# Load configuration
Write-Info "Loading configuration from $ConfigPath"
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Validate required configuration
if (-not $config.acrLoginServer -or -not $config.acrName) {
    Write-Error "Invalid configuration: Missing ACR details"
    exit 1
}

$acrLoginServer = $config.acrLoginServer
$acrName = $config.acrName
$imageName = "workshop-app"
$imageFullName = "$acrLoginServer/$imageName`:$ImageTag"

Write-Info "Using ACR: $acrName"
Write-Info "Image: $imageFullName"

# Get the workshop app directory
$appPath = Join-Path $PSScriptRoot "..\..\workshop-app"
if (-not (Test-Path $appPath)) {
    Write-Error "Workshop app directory not found: $appPath"
    exit 1
}

# Check if Docker is running
Write-Info "Checking Docker daemon..."
try {
    $null = docker ps -q
} catch {
    Write-Error "Docker daemon is not running or not installed"
    Write-Info "Please install Docker Desktop or Docker Engine and ensure it's running"
    exit 1
}

Write-Success "Docker daemon is available"

# Build the image
Write-Info "Building Docker image: $imageFullName"
Write-Info "Context: $appPath"

Push-Location $appPath
try {
    docker build -t $imageFullName -f Dockerfile .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
} finally {
    Pop-Location
}

Write-Success "Docker image built successfully: $imageFullName"

if ($SkipPush) {
    Write-Info "Skipping push (--SkipPush specified)"
    exit 0
}

# Login to ACR
Write-Info "Logging in to ACR: $acrLoginServer"
az acr login --name $acrName
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to login to ACR"
    exit 1
}

Write-Success "Logged in to ACR"

# Push the image
Write-Info "Pushing image to ACR: $imageFullName"
docker push $imageFullName
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push image to ACR"
    exit 1
}

Write-Success "Image pushed successfully to ACR"

# Show image details
Write-Info "Image details:"
Write-Host "  Repository: $acrName"
Write-Host "  Image: $imageName"
Write-Host "  Tag: $ImageTag"
Write-Host "  Full Name: $imageFullName"

# List images in ACR
Write-Info "Verifying image in ACR..."
$acrImages = az acr repository show-tags --name $acrName --repository $imageName -o json | ConvertFrom-Json
if ($acrImages -contains $ImageTag) {
    Write-Success "Image verified in ACR repository"
    Write-Info "Available tags: $($acrImages -join ', ')"
} else {
    Write-Error "Image not found in ACR repository"
    exit 1
}

Write-Success "Build and push completed successfully!"
