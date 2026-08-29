#!/usr/bin/env bash
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION="${1:-1.0.0}"

PKG_ID="com.m3etis.wezterm-pro-setup"
DMG_NAME="WezTerm-Pro-Setup-${VERSION}.dmg"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[info]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Clean ──────────────────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/payload/fonts" "$BUILD_DIR/payload/config" "$BUILD_DIR/scripts"

# ── 1. Download fonts ─────────────────────────────────────────────
info "Downloading Nerd Fonts..."

declare -A FONTS=(
    ["Monaspace.zip"]="MonaspiceNeNerdFont-"
    ["JetBrainsMono.zip"]="JetBrainsMonoNerdFont-"
)

for asset in "${!FONTS[@]}"; do
    prefix="${FONTS[$asset]}"
    info "  Fetching $asset..."
    url="$(curl -sL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep -o "\"browser_download_url\": \"[^\"]*${asset}\"" \
        | head -1 \
        | sed 's/"browser_download_url": "//;s/"$//')"
    curl -fSL "$url" -o "$BUILD_DIR/$asset"
    name="${asset%.zip}"
    unzip -qo "$BUILD_DIR/$asset" -d "$BUILD_DIR/payload/fonts/$name"
    rm "$BUILD_DIR/$asset"

    # Keep only the needed font variants
    info "  Filtering $name (keeping ${prefix}*)..."
    find "$BUILD_DIR/payload/fonts/$name" -type f \( -name '*.ttf' -o -name '*.otf' \) \
        ! -name "${prefix}*" -delete
done

ok "Fonts downloaded ($(du -sh "$BUILD_DIR/payload/fonts" | cut -f1))"

# ── 2. Copy config files ──────────────────────────────────────────
info "Copying configuration files..."

for item in config ui utils themes wezterm.lua; do
    src="$PROJECT_DIR/$item"
    if [[ -e "$src" ]]; then
        cp -r "$src" "$BUILD_DIR/payload/config/"
    fi
done

ok "Configuration copied"

# ── 3. Create postinstall script ──────────────────────────────────
info "Creating postinstall script..."

cat > "$BUILD_DIR/scripts/postinstall" << 'POSTINSTALL'
#!/bin/bash
set -euo pipefail

# Payload is installed to /tmp/.wezterm-pro-setup by pkgbuild
PAYLOAD_DIR="/tmp/.wezterm-pro-setup"
CONFIG_DIR="${HOME}/.config/wezterm"

# Install fonts
FONTS_DIR="${HOME}/.local/share/fonts"
mkdir -p "$FONTS_DIR"

if [[ -d "$PAYLOAD_DIR/fonts" ]]; then
    find "$PAYLOAD_DIR/fonts" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -f {} "$FONTS_DIR/" \;
    if command -v fc-cache &>/dev/null; then
        fc-cache -f "$FONTS_DIR"
    fi
fi

# Install config
if [[ -d "$CONFIG_DIR" ]]; then
    mv "$CONFIG_DIR" "${CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
fi
mkdir -p "$CONFIG_DIR"

if [[ -d "$PAYLOAD_DIR/config" ]]; then
    cp -r "$PAYLOAD_DIR/config/"* "$CONFIG_DIR/"
fi

# Remove non-config artifacts
for item in .git .gitignore .DS_Store screenshots docs README.md LICENSE install.sh install.ps1; do
    rm -rf "${CONFIG_DIR:?}/$item" 2>/dev/null || true
done

# Cleanup payload
rm -rf "$PAYLOAD_DIR"

exit 0
POSTINSTALL

chmod +x "$BUILD_DIR/scripts/postinstall"

ok "Postinstall script created"

# ── 4. Build .pkg ─────────────────────────────────────────────────
info "Building .pkg..."

pkgbuild \
    --root "$BUILD_DIR/payload" \
    --scripts "$BUILD_DIR/scripts" \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    --install-location "/tmp/.wezterm-pro-setup" \
    "$BUILD_DIR/WezTerm-Pro-Setup.pkg"

ok ".pkg built ($(du -h "$BUILD_DIR/WezTerm-Pro-Setup.pkg" | cut -f1))"

# ── 5. Create product definition ───────────────────────────────────
cat > "$BUILD_DIR/Distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>WezTerm Pro Setup</title>
    <options customize="never" require-scripts="true" hostArchitectures="x86_64,arm64"/>
    <domains enable_localSystem="true"/>
    <choices-outline>
        <line choice="default"/>
    </choices-outline>
    <choice id="default" title="WezTerm Pro Setup">
        <pkg-ref id="$PKG_ID"/>
    </choice>
    <pkg-ref id="$PKG_ID" version="$VERSION">WezTerm-Pro-Setup.pkg</pkg-ref>
</installer-gui-script>
EOF

productbuild \
    --distribution "$BUILD_DIR/Distribution.xml" \
    --package-path "$BUILD_DIR" \
    "$BUILD_DIR/WezTerm-Pro-Setup-${VERSION}.pkg"

ok "Product archive built ($(du -h "$BUILD_DIR/WezTerm-Pro-Setup-${VERSION}.pkg" | cut -f1))"

# ── 6. Create .dmg ─────────────────────────────────────────────────
info "Creating .dmg..."

DMG_STAGING="$BUILD_DIR/dmg-staging"
mkdir -p "$DMG_STAGING"
cp "$BUILD_DIR/WezTerm-Pro-Setup-${VERSION}.pkg" "$DMG_STAGING/WezTerm Pro Setup.pkg"
ln -sf /Applications "$DMG_STAGING/Applications" 2>/dev/null || true

create-dmg \
    --volname "WezTerm Pro Setup" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "WezTerm Pro Setup.pkg" 180 180 \
    --icon "Applications" 480 180 \
    --hide-extension "WezTerm Pro Setup.pkg" \
    --app-drop-link 480 180 \
    "$BUILD_DIR/$DMG_NAME" \
    "$DMG_STAGING" 2>/dev/null || {
    info "create-dmg layout failed, creating simple DMG..."
    hdiutil create -volname "WezTerm Pro Setup" \
        -srcfolder "$DMG_STAGING" \
        -ov -format UDZO \
        "$BUILD_DIR/$DMG_NAME"
}

ok ".dmg created ($(du -h "$BUILD_DIR/$DMG_NAME" | cut -f1))"

# ── 7. Copy to dist ───────────────────────────────────────────────
DIST_DIR="$PROJECT_DIR/dist"
mkdir -p "$DIST_DIR"
cp "$BUILD_DIR/$DMG_NAME" "$DIST_DIR/"
cp "$BUILD_DIR/WezTerm-Pro-Setup-${VERSION}.pkg" "$DIST_DIR/"

echo ""
ok "Build complete!"
echo ""
echo "  Artifacts:"
ls -lh "$DIST_DIR/" | grep -v total | awk '{print "    "$NF" ("$5")"}'
echo ""
