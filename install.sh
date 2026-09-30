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

# Install WezTerm if not present
install_wezterm() {
    if command -v wezterm &>/dev/null; then
        ok "WezTerm already installed: $(wezterm --version 2>/dev/null || echo 'unknown version')"
        return
    fi

    info "WezTerm not found — installing..."

    if [[ "$(uname)" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            err "Homebrew not found. Install it first: https://brew.sh"
            echo "  Or install WezTerm manually: https://wezfurlong.org/wezterm/installation.html"
            exit 1
        fi
        brew install --cask wezterm
    elif command -v apt-get &>/dev/null; then
        # Debian/Ubuntu — install from official repo
        curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/wezterm-fury.gpg 2>/dev/null || true
        echo "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
        sudo apt-get update -qq && sudo apt-get install -y wezterm
    elif command -v dnf &>/dev/null; then
        sudo dnf copr enable -y wezfury/wezterm 2>/dev/null || true
        sudo dnf install -y wezterm
    else
        err "Unsupported package manager. Install WezTerm manually:"
        echo "  https://wezfurlong.org/wezterm/installation.html"
        exit 1
    fi

    ok "WezTerm installed: $(wezterm --version 2>/dev/null || echo 'unknown version')"
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

# ── Shell stack (oh-my-zsh + tools) ───────────────────────────────────

OMZ_DIR="${HOME}/.oh-my-zsh"
ZSH_CUSTOM="${OMZ_DIR}/custom"
ZSHRC="${HOME}/.zshrc"
ZSHRC_TEMPLATE="${SCRIPT_DIR}/shell/zshrc"

ensure_brew() {
    if command -v brew &>/dev/null; then
        return
    fi
    if [[ "$(uname)" != "Darwin" ]]; then
        return 1
    fi
    err "Homebrew not found. Install it first: https://brew.sh"
    exit 1
}

install_shell_tools() {
    info "Installing shell tools (eza, zoxide)..."

    if [[ "$(uname)" == "Darwin" ]]; then
        ensure_brew
        brew install eza zoxide 2>/dev/null || true
    elif command -v apt-get &>/dev/null; then
        # Debian/Ubuntu — eza may be missing from older apt; zoxide is available
        sudo apt-get install -y zoxide 2>/dev/null || warn "zoxide not in apt — install manually"
        if ! command -v eza &>/dev/null; then
            warn "eza not in apt — trying cargo/static install is skipped; install via https://eza.rocks"
        fi
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y zoxide 2>/dev/null || warn "zoxide not in dnf — install manually"
    fi

    command -v eza &>/dev/null && ok "eza: $(eza --version 2>/dev/null | head -1)" || warn "eza not installed"
    command -v zoxide &>/dev/null && ok "zoxide: $(zoxide --version 2>/dev/null)" || warn "zoxide not installed"
}

clone_or_update() {
    local repo="$1"
    local dest="$2"
    if [[ -d "${dest}/.git" ]]; then
        git -C "$dest" pull --ff-only --quiet 2>/dev/null || warn "Could not update $dest (kept existing)"
    else
        git clone --depth=1 --quiet "$repo" "$dest"
    fi
}

install_oh_my_zsh() {
    if [[ -d "$OMZ_DIR" ]]; then
        ok "oh-my-zsh already installed"
        return
    fi

    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        >/dev/null
    ok "oh-my-zsh installed"
}

install_omz_plugins() {
    info "Installing oh-my-zsh plugins and themes..."

    clone_or_update \
        "https://github.com/zsh-users/zsh-autosuggestions.git" \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions"

    clone_or_update \
        "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting"

    clone_or_update \
        "https://github.com/romkatv/powerlevel10k.git" \
        "${ZSH_CUSTOM}/themes/powerlevel10k"
    ok "powerlevel10k (theme available as powerlevel10k/powerlevel10k)"
}

install_zshrc() {
    if [[ ! -f "$ZSHRC_TEMPLATE" ]]; then
        err "Template not found: $ZSHRC_TEMPLATE"
        return 1
    fi

    if [[ -f "$ZSHRC" ]]; then
        local backup="${ZSHRC}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Existing ~/.zshrc found"
        info "Backing up to $backup"
        cp "$ZSHRC" "$backup"
        ok "Backup created"
    fi

    info "Installing ~/.zshrc"
    cp "$ZSHRC_TEMPLATE" "$ZSHRC"
    ok "~/.zshrc installed"
}

setup_shell() {
    echo ""
    echo "  Shell setup (oh-my-zsh + eza + zoxide)"
    echo "  ──────────────────────────────────────"
    install_shell_tools
    install_oh_my_zsh
    install_omz_plugins
    install_zshrc
}

# Install required Nerd Fonts
install_fonts() {
    local fonts=("Monaspace:Monaspace.zip" "JetBrainsMono:JetBrainsMono.zip")

    if [[ "$(uname)" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            warn "Homebrew not found — skipping font installation"
            warn "Install fonts manually: https://github.com/ryanoasis/nerd-fonts/releases"
            return
        fi
        info "Installing Nerd Fonts via Homebrew..."
        brew install --cask font-monaspace-nerd-font 2>/dev/null || ok "Monaspace Nerd Font already installed"
        brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || ok "JetBrains Mono Nerd Font already installed"
        ok "Fonts installed"
        return
    fi

    # Linux — download and install manually
    if ! command -v unzip &>/dev/null; then
        warn "unzip not found — attempting to install..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y unzip
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y unzip
        else
            err "Cannot install unzip. Install it manually and re-run."
            return 1
        fi
    fi

    local fonts_dir
    if [[ "$(uname)" == "Darwin" ]]; then
        fonts_dir="${HOME}/Library/Fonts"
    else
        fonts_dir="${HOME}/.local/share/fonts"
    fi
    mkdir -p "$fonts_dir"

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    for entry in "${fonts[@]}"; do
        local name="${entry%%:*}"
        local asset="${entry##*:}"

        info "Downloading ${name} Nerd Font..."
        local download_url
        download_url="$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
            | grep -o "\"browser_download_url\": \"[^\"]*${asset}\"" \
            | head -1 \
            | sed 's/"browser_download_url": "//;s/"$//')"

        if [[ -z "$download_url" ]]; then
            warn "Could not find ${asset} in latest release — skipping"
            continue
        fi

        curl -fSL "$download_url" -o "${tmp_dir}/${asset}"

        info "Extracting ${name}..."
        unzip -qo "${tmp_dir}/${asset}" -d "${tmp_dir}/${name}"

        info "Installing ${name} fonts..."
        find "${tmp_dir}/${name}" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -f {} "$fonts_dir/" \;

        ok "${name} Nerd Font installed"
    done

    rm -rf "$tmp_dir"

    # Refresh font cache
    if command -v fc-cache &>/dev/null; then
        info "Refreshing font cache..."
        fc-cache -f "$fonts_dir"
        ok "Font cache updated"
    fi
}

main() {
    echo ""
    echo "  WezTerm Installer"
    echo "  ─────────────────"
    echo ""
    install_wezterm
    backup_config
    install_config
    cleanup_config
    install_fonts
    setup_shell
    echo ""
    ok "Installation complete!"
    echo ""
    echo "  Next steps:"
    echo "    1. Restart WezTerm (or reload config with Leader + Ctrl+R)"
    echo "    2. Open a new zsh session (or run: exec zsh)"
    echo "    3. Verify the Catppuccin Mocha theme and status bar are visible"
    echo "    4. Optional: switch prompt to Powerlevel10k in ~/.zshrc"
    echo "       (ZSH_THEME=\"powerlevel10k/powerlevel10k\") and run: p10k configure"
    echo "    5. If icons appear as boxes, ensure Nerd Fonts are installed and"
    echo "       selected in your terminal profile"
    echo ""
}

main "$@"
