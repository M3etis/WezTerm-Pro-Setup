#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path $env:USERPROFILE ".config\wezterm"

function Write-Info  { param([string]$Msg) Write-Host "[info]  $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[ok]    $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[warn]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[error] $Msg" -ForegroundColor Red }

# Check if WezTerm is installed
function Test-WezTerm {
    $cmd = Get-Command wezterm -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Err "WezTerm is not installed or not in PATH."
        Write-Host "  Install it from: https://wezfurlong.org/wezterm/installation.html"
        exit 1
    }
    $version = try { & wezterm --version 2>$null } catch { "unknown" }
    Write-Ok "WezTerm found: $version"
}

# Backup existing config
function Backup-Config {
    if (Test-Path $ConfigDir) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backup = "${ConfigDir}.bak.${timestamp}"
        Write-Warn "Existing config found at $ConfigDir"
        Write-Info "Backing up to $backup"
        Move-Item -Path $ConfigDir -Destination $backup
        Write-Ok "Backup created"
    }
}

# Copy config files
function Install-Config {
    Write-Info "Creating $ConfigDir"
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null

    Write-Info "Copying configuration files..."
    $items = @("config", "ui", "utils", "themes", "wezterm.lua")
    foreach ($item in $items) {
        $src = Join-Path $ScriptDir $item
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $ConfigDir -Recurse -Force
        }
    }
    Write-Ok "Configuration files installed"
}

# Remove non-config files
function Cleanup-Config {
    Write-Info "Removing non-config files from $ConfigDir"
    $items = @(
        ".git", ".gitignore", ".DS_Store",
        "screenshots", "docs", "README.md", "LICENSE",
        "install.sh", "install.ps1"
    )
    foreach ($item in $items) {
        $path = Join-Path $ConfigDir $item
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force
        }
    }
    Write-Ok "Cleanup complete"
}

# Main
Write-Host ""
Write-Host "  WezTerm Configuration Installer"
Write-Host "  --------------------------------"
Write-Host ""

Test-WezTerm
Backup-Config
Install-Config
Cleanup-Config

Write-Host ""
Write-Ok "Installation complete!"
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    1. Restart WezTerm (or reload config with Leader + Ctrl+R)"
Write-Host "    2. Verify the Catppuccin Mocha theme and status bar are visible"
Write-Host "    3. If icons appear as boxes, install Nerd Fonts from:"
Write-Host "       https://github.com/ryanoasis/nerd-fonts/releases"
Write-Host ""
