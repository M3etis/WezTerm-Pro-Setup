# install-fonts.ps1 — Called by NSIS installer to register Nerd Fonts
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceDir
)

$ErrorActionPreference = "Stop"

# Get Windows Fonts directory
$fontsDir = [System.Environment]::GetFolderPath('Fonts')
if (-not $fontsDir) {
    $fontsDir = "$env:WINDIR\Fonts"
}

$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

# Find all font files in source
$fontFiles = Get-ChildItem -Path $SourceDir -Include "*.ttf", "*.otf" -Recurse

foreach ($font in $fontFiles) {
    # Copy to Fonts directory
    Copy-Item -Path $font.FullName -Destination $fontsDir -Force

    # Register in registry
    if ($font.Extension -eq ".ttf") {
        $regName = "$($font.BaseName) (TrueType)"
    } else {
        $regName = "$($font.BaseName) (OpenType)"
    }
    New-ItemProperty -Path $regPath -Name $regName -Value $font.Name -PropertyType String -Force | Out-Null
}

Write-Output "Installed $($fontFiles.Count) fonts"
