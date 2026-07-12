#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME}/.config/wezterm"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
err()   { echo -e "${RED}[error]${NC} $*" >&2; }

# Check if WezTerm is installed
check_wezterm() {
    if ! command -v wezterm &>/dev/null; then
        err "WezTerm is not installed or not in PATH."
        echo "  Install it from: https://wezfurlong.org/wezterm/installation.html"
        exit 1
    fi
    ok "WezTerm found: $(wezterm --version 2>/dev/null || echo 'unknown version')"
}

# Backup existing config
backup_config() {
    if [[ -d "$CONFIG_DIR" ]]; then
        local backup="${CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Existing config found at $CONFIG_DIR"
        info "Backing up to $backup"
        mv "$CONFIG_DIR" "$backup"
        ok "Backup created"
    fi
}

# Copy config files
install_config() {
    info "Creating $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"

    info "Copying configuration files..."
    # Copy only config-relevant directories and files
    for item in config ui utils themes wezterm.lua; do
        if [[ -e "${SCRIPT_DIR}/${item}" ]]; then
            cp -r "${SCRIPT_DIR}/${item}" "$CONFIG_DIR/"
        fi
    done
    ok "Configuration files installed"
}

# Remove non-config files that may have been copied
cleanup_config() {
    info "Removing non-config files from $CONFIG_DIR"
    local items=(
        ".git" ".gitignore" ".DS_Store"
        "screenshots" "docs" "README.md" "LICENSE"
        "install.sh" "install.ps1"
    )
    for item in "${items[@]}"; do
        rm -rf "${CONFIG_DIR:?}/${item}"
    done
    ok "Cleanup complete"
}

# Install fonts on macOS
install_fonts_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        return
    fi
    if ! command -v brew &>/dev/null; then
        warn "Homebrew not found — skipping font installation"
        warn "Install fonts manually: https://github.com/ryanoasis/nerd-fonts/releases"
        return
    fi
    info "Installing Nerd Fonts via Homebrew..."
    brew install --cask font-monaspace-nerd-font 2>/dev/null || ok "Monaspace Nerd Font already installed"
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || ok "JetBrains Mono Nerd Font already installed"
    ok "Fonts installed"
}

main() {
    echo ""
    echo "  WezTerm Configuration Installer"
    echo "  ────────────────────────────────"
    echo ""
    check_wezterm
    backup_config
    install_config
    cleanup_config
    install_fonts_macos
    echo ""
    ok "Installation complete!"
    echo ""
    echo "  Next steps:"
    echo "    1. Restart WezTerm (or reload config with Leader + Ctrl+R)"
    echo "    2. Verify the Catppuccin Mocha theme and status bar are visible"
    echo "    3. If icons appear as boxes, ensure Nerd Fonts are installed and"
    echo "       selected in your terminal profile"
    echo ""
}

main "$@"
