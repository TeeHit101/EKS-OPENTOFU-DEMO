# Terraform/OpenTofu bootstrap and dev environment setup script
# Run this script from the repository root directory

$ErrorActionPreference = "Stop"

Write-Host "Starting bootstrap deployment..." -ForegroundColor Cyan

# Bootstrap phase
Set-Location bootstrap
tofu init
tofu fmt --recursive
tofu plan
tofu apply -auto-approve

Write-Host "`nBootstrap complete! Starting dev environment deployment..." -ForegroundColor Cyan

# Dev environment phase
Set-Location ..\envs\dev
tofu init
tofu fmt --recursive
tofu plan
tofu apply -auto-approve

# Return to root directory
Set-Location ..\..

Write-Host "`nDeployment complete!" -ForegroundColor Green
