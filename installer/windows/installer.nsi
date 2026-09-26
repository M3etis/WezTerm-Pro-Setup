; WezTerm-Pro-Setup Windows Installer
; Builds a single .exe that installs WezTerm, Nerd Fonts, and configuration

!include "MUI2.nsh"
!include "FileFunc.nsh"

; ── General ────────────────────────────────────────────────────────
Name "WezTerm Pro Setup"
OutFile "WezTerm-Pro-Setup-${VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\WezTerm"
RequestExecutionLevel admin
BrandingText "WezTerm Pro Setup v${VERSION}"

; ── Variables ──────────────────────────────────────────────────────
Var WezTermExe
Var ConfigDir

; ── Interface settings ─────────────────────────────────────────────
!define MUI_ABORTWARNING

; ── Pages ──────────────────────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENSE_PATH}"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$WezTermExe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch WezTerm"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ── Languages ──────────────────────────────────────────────────────
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Russian"

; ── Installer sections ─────────────────────────────────────────────

Section "WezTerm" SecWezTerm
    SectionIn RO

    SetOutPath "$INSTDIR"

    ; Install WezTerm
    DetailPrint "Installing WezTerm..."
    File /oname=wezterm-install.exe "${WEZTERM_EXE}"
    ExecWait '"$INSTDIR\wezterm-install.exe" /S' $0
    Delete "$INSTDIR\wezterm-install.exe"

    ; Find wezterm.exe for the finish page
    SearchPath $WezTermExe wezterm.exe
    IfFileExists "$WezTermExe" wezterm_found 0
    StrCpy $WezTermExe "$INSTDIR\wezterm.exe"
    IfFileExists "$WezTermExe" wezterm_found 0
    StrCpy $WezTermExe "$PROGRAMFILES64\WezTerm\wezterm.exe"
    IfFileExists "$WezTermExe" wezterm_found 0
    StrCpy $WezTermExe "$PROGRAMFILES\WezTerm\wezterm.exe"
    IfFileExists "$WezTermExe" wezterm_found 0
    StrCpy $WezTermExe "$LOCALAPPDATA\Programs\WezTerm\wezterm.exe"
    wezterm_found:

    DetailPrint "WezTerm installed successfully"
SectionEnd

Section "Nerd Fonts" SecFonts
    SetShellVarContext all
    SetOutPath "$INSTDIR\fonts"

    DetailPrint "Installing MonaspiceNe Nerd Font..."
    File /nonfatal /r "${FONTS_DIR}\Monaspace\*.otf"

    DetailPrint "Installing JetBrainsMono Nerd Font..."
    File /nonfatal /r "${FONTS_DIR}\JetBrainsMono\*.ttf"

    ; Install font registration script
    SetOutPath "$INSTDIR"
    File "${SCRIPTS_DIR}\install-fonts.ps1"

    ; Run font registration
    DetailPrint "Registering fonts..."
    nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\install-fonts.ps1" -SourceDir "$INSTDIR\fonts"'

    ; Cleanup
    Delete "$INSTDIR\install-fonts.ps1"
    RMDir /r "$INSTDIR\fonts"

    DetailPrint "Fonts installed and registered"
SectionEnd

Section "Configuration" SecConfig
    SetOutPath "$ConfigDir"

    DetailPrint "Installing WezTerm configuration..."

    ; Backup existing config
    IfFileExists "$ConfigDir\wezterm.lua" 0 no_backup
        StrCpy $0 "$ConfigDir.bak"
        StrCpy $1 0
        find_backup:
            IfFileExists "$0.$1" +3 0
                Rename "$ConfigDir" "$0.$1"
                goto no_backup
            IntOp $1 $1 + 1
            StrCmp $1 999 no_backup
            goto find_backup
    no_backup:

    CreateDirectory "$ConfigDir"

    ; Copy config structure
    File /r "${CONFIG_DIR}\config"
    File /r "${CONFIG_DIR}\ui"
    File /r "${CONFIG_DIR}\utils"
    File /r "${CONFIG_DIR}\themes"
    File "${CONFIG_DIR}\wezterm.lua"

    DetailPrint "Configuration installed"
SectionEnd

; ── Section descriptions ───────────────────────────────────────────
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecWezTerm}  "WezTerm terminal emulator (required)"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecFonts}    "MonaspiceNe and JetBrainsMono Nerd Fonts for icons and powerline"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecConfig}   "Pre-configured Catppuccin Mocha theme, powerline tabs, and status bar"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ── Init callback ──────────────────────────────────────────────────
Function .onInit
    StrCpy $ConfigDir "$PROFILE\.config\wezterm"
FunctionEnd

; ── Create uninstaller ────────────────────────────────────────────
Section "-WriteUninstaller"
    SetOutPath "$INSTDIR"
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; ── Uninstaller ────────────────────────────────────────────────────
Section "Uninstall"
    ; Remove config
    RMDir /r "$ConfigDir"

    ; Remove WezTerm (silent uninstall)
    ExecWait '"$INSTDIR\uninstall.exe" /S'

    ; Remove install dir
    RMDir /r "$INSTDIR"
SectionEnd
