param(
  [string]$ImageName = 'workshop-app',
  [string]$Tag = 'latest',
  [string]$ContextPath = '..\workshop-app'
)

if (-not (Test-Path $ContextPath)) {
  Write-Host "ERROR: Context path $ContextPath no existe"
  exit 1
}

if (-not (Test-Path "$ContextPath\Dockerfile")) {
  Write-Host "ERROR: Dockerfile no encontrado en $ContextPath"
  exit 1
}

$fullTag = "$ImageName`:$Tag"
Write-Host "Building $fullTag from $ContextPath..."

docker build -t $fullTag $ContextPath
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: Build failed"
  exit 1
}

Write-Host "Success: Built $fullTag"
docker images $ImageName
