#!/usr/bin/env bash
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION="${1:-1.0.0}"

PKG_ID="com.m3etis.wezterm-pro-setup"
DMG_NAME="WezTerm-Pro-Setup-${VERSION}.dmg"
WEZTERM_TAG="${WEZTERM_TAG:-20240203-110809-5046fc22}"
WEZTERM_ZIP="WezTerm-macos-${WEZTERM_TAG}.zip"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[info]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Clean ──────────────────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/payload/fonts" "$BUILD_DIR/payload/config" "$BUILD_DIR/payload/Applications" "$BUILD_DIR/scripts"

# ── 1. Download WezTerm.app ────────────────────────────────────────
info "Downloading WezTerm ${WEZTERM_TAG}..."
WEZTERM_URL="https://github.com/wez/wezterm/releases/download/${WEZTERM_TAG}/${WEZTERM_ZIP}"
curl -fSL "$WEZTERM_URL" -o "$BUILD_DIR/${WEZTERM_ZIP}"
unzip -qo "$BUILD_DIR/${WEZTERM_ZIP}" -d "$BUILD_DIR/wezterm-unpack"

# The zip contains a single folder with WezTerm.app inside
APP_SRC="$(find "$BUILD_DIR/wezterm-unpack" -maxdepth 2 -type d -name 'WezTerm.app' | head -1)"
if [[ -z "$APP_SRC" ]]; then
    err "WezTerm.app not found in ${WEZTERM_ZIP}"
    exit 1
fi
cp -R "$APP_SRC" "$BUILD_DIR/payload/Applications/WezTerm.app"
rm -rf "$BUILD_DIR/wezterm-unpack" "$BUILD_DIR/${WEZTERM_ZIP}"
ok "WezTerm.app bundled ($(du -sh "$BUILD_DIR/payload/Applications/WezTerm.app" | cut -f1))"

# ── 2. Download fonts ─────────────────────────────────────────────
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
    unzip -qo "$BUILD_DIR/$asset" -d "$BUILD_DIR/payload/fonts/$name"
    rm "$BUILD_DIR/$asset"

    # Keep only the needed font variants
    info "  Filtering $name (keeping ${prefix}*)..."
    find "$BUILD_DIR/payload/fonts/$name" -type f \( -name '*.ttf' -o -name '*.otf' \) \
        ! -name "${prefix}*" -delete
done

ok "Fonts downloaded ($(du -sh "$BUILD_DIR/payload/fonts" | cut -f1))"

# ── 3. Copy config files ──────────────────────────────────────────
info "Copying configuration files..."

for item in config ui utils themes wezterm.lua; do
    src="$PROJECT_DIR/$item"
    if [[ -e "$src" ]]; then
        cp -r "$src" "$BUILD_DIR/payload/config/"
    fi
done

ok "Configuration copied"

# ── 4. Create postinstall script ──────────────────────────────────
info "Creating postinstall script..."

# IMPORTANT: .pkg postinstall runs as root. $HOME is /var/root then.
# Resolve the real console user so config/fonts land in the right place.
cat > "$BUILD_DIR/scripts/postinstall" << 'POSTINSTALL'
#!/bin/bash
set -euo pipefail

PAYLOAD_DIR="/tmp/.wezterm-pro-setup"
INSTALL_LOG="/var/log/wezterm-pro-setup.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$INSTALL_LOG" >&2; }

# ── Resolve the logged-in user (not root) ─────────────────────────
CONSOLE_USER="$(stat -f%Su /dev/console 2>/dev/null || true)"
if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" || "$CONSOLE_USER" == "loginwindow" ]]; then
    CONSOLE_USER="$(echo "show State:/Users/ConsoleUser" | scutil 2>/dev/null | awk '/Name :/ { print $3 }' || true)"
fi

if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" || "$CONSOLE_USER" == "loginwindow" ]]; then
    log "ERROR: could not resolve console user; falling back to SUDO_USER=${SUDO_USER:-}"
    CONSOLE_USER="${SUDO_USER:-}"
fi

if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" ]]; then
    log "ERROR: no target user found. Installing to /var/root is not useful."
    log "Config and fonts left in $PAYLOAD_DIR for manual copy."
    exit 0
fi

USER_HOME="$(dscl . -read "/Users/${CONSOLE_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
USER_HOME="${USER_HOME:-/Users/${CONSOLE_USER}}"
log "Installing for user='${CONSOLE_USER}' home='${USER_HOME}'"

# ── Install WezTerm.app to /Applications ──────────────────────────
if [[ -d "$PAYLOAD_DIR/Applications/WezTerm.app" ]]; then
    log "Installing WezTerm.app..."
    if [[ -d /Applications/WezTerm.app ]]; then
        rm -rf /Applications/WezTerm.app
    fi
    cp -R "$PAYLOAD_DIR/Applications/WezTerm.app" /Applications/WezTerm.app
    chown -R root:admin /Applications/WezTerm.app 2>/dev/null || true
    chmod -R a+rX /Applications/WezTerm.app
    xattr -dr com.apple.quarantine /Applications/WezTerm.app 2>/dev/null || true
    log "WezTerm.app installed to /Applications"
else
    log "WARN: WezTerm.app missing from payload"
fi

# ── Install fonts into the user's font directory ──────────────────
# macOS CoreText looks at ~/Library/Fonts (NOT ~/.local/share/fonts)
FONTS_DIR="${USER_HOME}/Library/Fonts"
mkdir -p "$FONTS_DIR"
chown "${CONSOLE_USER}:staff" "$FONTS_DIR" 2>/dev/null || true

if [[ -d "$PAYLOAD_DIR/fonts" ]]; then
    find "$PAYLOAD_DIR/fonts" -type f \( -name '*.ttf' -o -name '*.otf' \) \
        -exec cp -f {} "$FONTS_DIR/" \;
    chown "${CONSOLE_USER}:staff" "$FONTS_DIR"/*.{ttf,otf} 2>/dev/null || true
    log "Fonts installed to $FONTS_DIR"
fi

# ── Install config into the user's ~/.config/wezterm ──────────────
CONFIG_DIR="${USER_HOME}/.config/wezterm"

if [[ -d "$CONFIG_DIR" ]]; then
    BACKUP="${CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    log "Backing up existing config to $BACKUP"
    mv "$CONFIG_DIR" "$BACKUP"
fi

mkdir -p "$CONFIG_DIR"
if [[ -d "$PAYLOAD_DIR/config" ]]; then
    cp -R "$PAYLOAD_DIR/config/"* "$CONFIG_DIR/"
fi
chown -R "${CONSOLE_USER}:staff" "${USER_HOME}/.config" 2>/dev/null || true

# Remove non-config artifacts
for item in .git .gitignore .DS_Store screenshots docs README.md LICENSE install.sh install.ps1; do
    rm -rf "${CONFIG_DIR:?}/$item" 2>/dev/null || true
done

log "Config installed to $CONFIG_DIR"

# ── Cleanup payload ───────────────────────────────────────────────
rm -rf "$PAYLOAD_DIR"

log "Done."
exit 0
POSTINSTALL

chmod +x "$BUILD_DIR/scripts/postinstall"

ok "Postinstall script created"

# ── 5. Build .pkg ─────────────────────────────────────────────────
info "Building .pkg..."

pkgbuild \
    --root "$BUILD_DIR/payload" \
    --scripts "$BUILD_DIR/scripts" \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    --install-location "/tmp/.wezterm-pro-setup" \
    "$BUILD_DIR/WezTerm-Pro-Setup.pkg"

ok ".pkg built ($(du -h "$BUILD_DIR/WezTerm-Pro-Setup.pkg" | cut -f1))"

# ── 6. Create product definition ───────────────────────────────────
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

# ── 7. Create .dmg ─────────────────────────────────────────────────
info "Creating .dmg..."

DMG_STAGING="$BUILD_DIR/dmg-staging"
mkdir -p "$DMG_STAGING"
cp "$BUILD_DIR/WezTerm-Pro-Setup-${VERSION}.pkg" "$DMG_STAGING/WezTerm Pro Setup.pkg"
ln -sf /Applications "$DMG_STAGING/Applications" 2>/dev/null || true

# Drop the app-drop-link: this DMG ships a .pkg installer, not a .app
create-dmg \
    --volname "WezTerm Pro Setup" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "WezTerm Pro Setup.pkg" 180 180 \
    --icon "Applications" 480 180 \
    --hide-extension "WezTerm Pro Setup.pkg" \
    "$BUILD_DIR/$DMG_NAME" \
    "$DMG_STAGING" 2>/dev/null || {
    info "create-dmg layout failed, creating simple DMG..."
    hdiutil create -volname "WezTerm Pro Setup" \
        -srcfolder "$DMG_STAGING" \
        -ov -format UDZO \
        "$BUILD_DIR/$DMG_NAME"
}

ok ".dmg created ($(du -h "$BUILD_DIR/$DMG_NAME" | cut -f1))"

# ── 8. Copy to dist ───────────────────────────────────────────────
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
