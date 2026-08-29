#!/usr/bin/env bash
set -euo pipefail

# ── WezTerm Pro Setup — Master Build Script ────────────────────────
# Builds distributable installers for macOS (.dmg) and Windows (.exe)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-1.0.0}"
PLATFORM="${2:-all}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[info]${NC} $*"; }
ok()      { echo -e "${GREEN}[ok]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
err()     { echo -e "${RED}[error]${NC} $*" >&2; }

usage() {
    echo "Usage: $0 [VERSION] [PLATFORM]"
    echo ""
    echo "  VERSION   Version string (default: 1.0.0)"
    echo "  PLATFORM  macos | windows | all (default: all)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Build all, version 1.0.0"
    echo "  $0 1.1.0            # Build all, version 1.1.0"
    echo "  $0 1.1.0 macos      # macOS only"
    echo "  $0 1.1.0 windows    # Windows only"
    exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

# ── Preflight checks ──────────────────────────────────────────────
echo ""
echo "  WezTerm Pro Setup — Build"
echo "  ─────────────────────────"
echo ""
info "Version: $VERSION"
info "Platform: $PLATFORM"
echo ""

# Check tools
check_tool() {
    if ! command -v "$1" &>/dev/null; then
        err "$1 not found. Install it first."
        return 1
    fi
}

build_macos() {
    info "Building macOS installer..."
    if ! check_tool productbuild || ! check_tool hdiutil; then
        err "macOS build tools not available (need productbuild, hdiutil)"
        return 1
    fi
    check_tool create-dmg || warn "create-dmg not found — will create basic DMG"
    bash "$SCRIPT_DIR/installer/macos/build.sh" "$VERSION"
}

build_windows() {
    info "Building Windows installer..."
    if ! check_tool makensis; then
        err "makensis (NSIS) not found. Install: brew install nsis"
        return 1
    fi
    bash "$SCRIPT_DIR/installer/windows/build.sh" "$VERSION"
}

# ── Build ──────────────────────────────────────────────────────────
case "$PLATFORM" in
    macos)
        build_macos
        ;;
    windows)
        build_windows
        ;;
    all)
        build_macos
        echo ""
        build_windows
        ;;
    *)
        err "Unknown platform: $PLATFORM (use: macos, windows, all)"
        exit 1
        ;;
esac

# ── Final summary ─────────────────────────────────────────────────
echo ""
echo "  ──────────────────────────────────────"
ok "All builds complete!"
echo ""
echo "  Artifacts in dist/:"
ls -lh "$SCRIPT_DIR/dist/" 2>/dev/null || echo "  (no artifacts found)"
echo ""
