#!/usr/bin/env pwsh
# Terraform/OpenTofu bootstrap and dev environment setup script
# Run this script from the repository root directory
#
# Usage:
#   Windows:  .\scripts\start.ps1
#   Linux:    pwsh ./scripts/start.ps1

$ErrorActionPreference = "Stop"

# Required OpenTofu version
$RequiredVersion = "1.11.2"

# Check if OpenTofu is installed
Write-Host "Checking OpenTofu installation..." -ForegroundColor Cyan

$tofuCommand = Get-Command tofu -ErrorAction SilentlyContinue
if (-not $tofuCommand) {
    Write-Host "ERROR: OpenTofu is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Required version: v$RequiredVersion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installation instructions:" -ForegroundColor Cyan
    Write-Host "  Fedora/RHEL:" -ForegroundColor White
    Write-Host "    sudo dnf install opentofu-$RequiredVersion" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Ubuntu/Debian:" -ForegroundColor White
    Write-Host "    sudo apt-get install opentofu=$RequiredVersion" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Or visit: https://opentofu.org/docs/intro/install/" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Check OpenTofu version
$tofuVersionOutput = tofu --version | Select-Object -First 1
if ($tofuVersionOutput -match "OpenTofu v(\d+\.\d+\.\d+)") {
    $currentVersion = $matches[1]
    Write-Host "Current OpenTofu version: $currentVersion" -ForegroundColor Yellow

    if ($currentVersion -ne $RequiredVersion) {
        Write-Host "WARNING: You are using OpenTofu v$currentVersion" -ForegroundColor Red
        Write-Host "         The intended version is v$RequiredVersion" -ForegroundColor Red
        Write-Host "         This may cause compatibility issues!" -ForegroundColor Red

        $continue = Read-Host "`nDo you want to continue anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "Aborted by user." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "✓ Version check passed!" -ForegroundColor Green
    }
} else {
    Write-Host "WARNING: Could not detect OpenTofu version!" -ForegroundColor Red
}

Write-Host ""

# Bootstrap phase
$deployBootstrap = Read-Host "Do you want to deploy bootstrap? (y/N)"
if ($deployBootstrap -eq "y" -or $deployBootstrap -eq "Y") {
    Write-Host "`nStarting bootstrap deployment..." -ForegroundColor Cyan
    Set-Location ../bootstrap
    tofu init
    tofu fmt --recursive
    tofu plan
    tofu apply -auto-approve
    Set-Location ..
    Write-Host "✓ Bootstrap complete!" -ForegroundColor Green
} else {
    Write-Host "Skipping bootstrap deployment." -ForegroundColor Yellow
}

# Dev environment phase
$deployDev = Read-Host "`nDo you want to deploy dev environment? (y/N)"
if ($deployDev -eq "y" -or $deployDev -eq "Y") {
    Write-Host "`nStarting dev environment deployment..." -ForegroundColor Cyan
    Set-Location envs/dev
    tofu init
    tofu fmt --recursive
    tofu plan
    tofu apply -auto-approve
    Set-Location ../..
    Write-Host "✓ Dev environment complete!" -ForegroundColor Green
} else {
    Write-Host "Skipping dev environment deployment." -ForegroundColor Yellow
}

# Stage environment phase
$deployStage = Read-Host "`nDo you want to deploy stage environment? (y/N)"
if ($deployStage -eq "y" -or $deployStage -eq "Y") {
    Write-Host "`nStarting stage environment deployment..." -ForegroundColor Cyan
    Set-Location envs/stage
    tofu init
    tofu fmt --recursive
    tofu plan
    tofu apply -auto-approve
    Set-Location ../..
    Write-Host "✓ Stage environment complete!" -ForegroundColor Green
} else {
    Write-Host "Skipping stage environment deployment." -ForegroundColor Yellow
}

# Prod environment phase
$deployProd = Read-Host "`nDo you want to deploy prod environment? (y/N)"
if ($deployProd -eq "y" -or $deployProd -eq "Y") {
    Write-Host "`nStarting prod environment deployment..." -ForegroundColor Cyan
    Set-Location envs/prod
    tofu init
    tofu fmt --recursive
    tofu plan
    tofu apply -auto-approve
    Set-Location ../..
    Write-Host "✓ Prod environment complete!" -ForegroundColor Green
} else {
    Write-Host "Skipping prod environment deployment." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "All selected deployments complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
