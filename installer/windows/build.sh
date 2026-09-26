#!/usr/bin/env bash
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION="${1:-1.0.0}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[info]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Clean ──────────────────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/fonts" "$BUILD_DIR/config" "$BUILD_DIR/assets"

# ── 1. Download WezTerm Windows installer ──────────────────────────
info "Downloading WezTerm for Windows..."

WEZTERM_VERSION="$(curl -sL https://api.github.com/repos/wez/wezterm/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "//;s/".*//')"
info "  Latest WezTerm: $WEZTERM_VERSION"

WEZTERM_URL="$(curl -sL "https://api.github.com/repos/wez/wezterm/releases/latest" \
    | grep -o '"browser_download_url": "[^"]*\.exe"' \
    | grep -v portable \
    | head -1 \
    | sed 's/"browser_download_url": "//;s/"$//')"

if [[ -z "$WEZTERM_URL" ]]; then
    # Fallback: try direct URL pattern
    WEZTERM_URL="https://github.com/wez/wezterm/releases/download/${WEZTERM_VERSION}/WezTerm-${WEZTERM_VERSION}-setup.exe"
fi

info "  URL: $WEZTERM_URL"
curl -fSL "$WEZTERM_URL" -o "$BUILD_DIR/assets/WezTerm-setup.exe"
ok "WezTerm downloaded"

# ── 2. Download Nerd Fonts ─────────────────────────────────────────
info "Downloading Nerd Fonts..."

# "zip_name:file_prefix" — avoid declare -A (macOS ships bash 3.2)
FONTS=(
    "Monaspace.zip:MonaspiceNeNerdFont-"
    "JetBrainsMono.zip:JetBrainsMonoNerdFont-"
)

for entry in "${FONTS[@]}"; do
    asset="${entry%%:*}"
    prefix="${entry##*:}"
    info "  Fetching $asset..."
    url="$(curl -sL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep -o "\"browser_download_url\": \"[^\"]*${asset}\"" \
        | head -1 \
        | sed 's/"browser_download_url": "//;s/"$//')"
    if [[ -z "$url" ]]; then
        err "Could not find ${asset} in nerd-fonts latest release"
        exit 1
    fi
    curl -fSL "$url" -o "$BUILD_DIR/$asset"
    name="${asset%.zip}"
    unzip -qo "$BUILD_DIR/$asset" -d "$BUILD_DIR/fonts/$name"
    rm "$BUILD_DIR/$asset"

    # Keep only the needed font variants
    info "  Filtering $name (keeping ${prefix}*)..."
    find "$BUILD_DIR/fonts/$name" -type f \( -name '*.ttf' -o -name '*.otf' \) \
        ! -name "${prefix}*" -delete
done

ok "Fonts downloaded ($(du -sh "$BUILD_DIR/fonts" | cut -f1))"

# ── 3. Copy config files ──────────────────────────────────────────
info "Copying configuration files..."

for item in config ui utils themes wezterm.lua; do
    src="$PROJECT_DIR/$item"
    if [[ -e "$src" ]]; then
        cp -r "$src" "$BUILD_DIR/config/"
    fi
done

ok "Configuration copied"

# ── 4. Create assets (icon placeholder, sidebar, license) ─────────
# ── 4. Build NSIS installer ────────────────────────────────────────
info "Building NSIS installer..."

LICENSE_PATH="$PROJECT_DIR/LICENSE"
if [[ ! -f "$LICENSE_PATH" ]]; then
    echo "MIT License" > "$BUILD_DIR/LICENSE"
    LICENSE_PATH="$BUILD_DIR/LICENSE"
fi

DIST_DIR="$PROJECT_DIR/dist"
mkdir -p "$DIST_DIR"

makensis \
    -DVERSION="$VERSION" \
    -DLICENSE_PATH="$LICENSE_PATH" \
    -DWEZTERM_EXE="$BUILD_DIR/assets/WezTerm-setup.exe" \
    -DFONTS_DIR="$BUILD_DIR/fonts" \
    -DCONFIG_DIR="$BUILD_DIR/config" \
    -DSCRIPTS_DIR="$SCRIPT_DIR" \
    "$SCRIPT_DIR/installer.nsi"

# Move output to dist
mv "$SCRIPT_DIR/WezTerm-Pro-Setup-${VERSION}.exe" "$DIST_DIR/" 2>/dev/null || \
    mv "$PROJECT_DIR/installer/windows/WezTerm-Pro-Setup-${VERSION}.exe" "$DIST_DIR/" 2>/dev/null || true

ok ".exe built"

# ── 6. Summary ─────────────────────────────────────────────────────
echo ""
ok "Build complete!"
echo ""
echo "  Artifact: dist/WezTerm-Pro-Setup-${VERSION}.exe"
echo ""
