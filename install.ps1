#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path $env:USERPROFILE ".config\wezterm"

function Write-Info  { param([string]$Msg) Write-Host "[info]  $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[ok]    $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[warn]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[error] $Msg" -ForegroundColor Red }

# Install WezTerm if not present
function Install-WezTerm {
    $cmd = Get-Command wezterm -ErrorAction SilentlyContinue
    if ($cmd) {
        $version = try { & wezterm --version 2>$null } catch { "unknown" }
        Write-Ok "WezTerm already installed: $version"
        return
    }

    Write-Info "WezTerm not found — downloading latest release..."
    $tempDir = Join-Path $env:TEMP "wezterm-install"
    if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/wezterm/wezterm/releases/latest" -Headers @{ 'User-Agent' = 'WezTerm-Installer' }
        $asset = $release.assets | Where-Object { $_.name -match '\.exe$' -and $_.name -notmatch 'portable' } | Select-Object -First 1
        if (-not $asset) {
            $asset = $release.assets | Where-Object { $_.name -match '\.exe$' } | Select-Object -First 1
        }
        if (-not $asset) {
            Write-Err "Could not find WezTerm installer in latest release"
            Write-Host "  Install manually from: https://wezfurlong.org/wezterm/installation.html"
            exit 1
        }

        Write-Info "Downloading $($asset.name)..."
        $exePath = Join-Path $tempDir $asset.name
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $exePath -Headers @{ 'User-Agent' = 'WezTerm-Installer' }

        Write-Info "Running WezTerm installer (silent)..."
        Start-Process -FilePath $exePath -ArgumentList "/S" -Wait -NoNewWindow
        Write-Ok "WezTerm installed"
    }
    catch {
        Write-Err "Failed to install WezTerm: $_"
        Write-Host "  Install manually from: https://wezfurlong.org/wezterm/installation.html"
        exit 1
    }
    finally {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Refresh PATH so wezterm is available in this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
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

# Install required Nerd Fonts
function Install-Fonts {
    $fonts = @(
        @{
            Name   = "MonaspiceNe Nerd Font"
            Repo   = "ryanoasis/nerd-fonts"
            Asset  = "Monaspace.zip"
            Folder = "Monaspace"
        },
        @{
            Name   = "JetBrainsMono Nerd Font"
            Repo   = "ryanoasis/nerd-fonts"
            Asset  = "JetBrainsMono.zip"
            Folder = "JetBrainsMono"
        }
    )

    $fontsDir = [System.Environment]::GetFolderPath('Fonts')
    $tempDir  = Join-Path $env:TEMP "nerd-fonts-install"

    if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    foreach ($font in $fonts) {
        # Check if font is already installed
        $installed = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue |
            Where-Object { $_.PSObject.Properties.Value -match ($font.Name -replace '\s', '') }

        if ($installed) {
            Write-Ok "$($font.Name) already installed"
            continue
        }

        Write-Info "Downloading $($font.Name)..."
        $latestUrl = "https://api.github.com/repos/$($font.Repo)/releases/latest"
        try {
            $release = Invoke-RestMethod -Uri $latestUrl -Headers @{ 'User-Agent' = 'WezTerm-Installer' }
            $asset = $release.assets | Where-Object { $_.name -eq $font.Asset } | Select-Object -First 1
            if (-not $asset) {
                Write-Warn "Asset $($font.Asset) not found in latest release — skipping"
                continue
            }
            $zipPath = Join-Path $tempDir $font.Asset
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -Headers @{ 'User-Agent' = 'WezTerm-Installer' }
        }
        catch {
            Write-Warn "Failed to download $($font.Name): $_"
            continue
        }

        Write-Info "Extracting $($font.Name)..."
        $extractDir = Join-Path $tempDir $font.Folder
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

        Write-Info "Installing $($font.Name)..."
        $ttfFiles = Get-ChildItem -Path $extractDir -Include "*.ttf", "*.otf" -Recurse
        foreach ($ttf in $ttfFiles) {
            $dest = Join-Path $fontsDir $ttf.Name
            Copy-Item -Path $ttf.FullName -Destination $dest -Force
            # Register font in the registry
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $fontName = $ttf.BaseName
            $ext = $ttf.Extension.ToLower()
            if ($ext -eq ".ttf") {
                $regValue = "$fontName (TrueType)"
            } else {
                $regValue = "$fontName (OpenType)"
            }
            try {
                New-ItemProperty -Path $regPath -Name $regValue -Value $ttf.Name -PropertyType String -Force | Out-Null
            }
            catch {
                Write-Warn "Could not register font $fontName — run installer as Administrator"
            }
        }
        Write-Ok "$($font.Name) installed ($($ttfFiles.Count) files)"
    }

    # Cleanup
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
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
Write-Host "  WezTerm Installer"
Write-Host "  -----------------"
Write-Host ""

Install-WezTerm
Backup-Config
Install-Config
Cleanup-Config
Install-Fonts

Write-Host ""
Write-Ok "Installation complete!"
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    1. Restart WezTerm (or reload config with Leader + Ctrl+R)"
Write-Host "    2. Verify the Catppuccin Mocha theme and status bar are visible"
Write-Host "    3. If icons appear as boxes, restart your terminal or re-login"
Write-Host ""
