#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════════
#  CYBREIGN — Installer
#  Usage : curl -fsSL https://raw.githubusercontent.com/cybreign/cybreign-core/main/install.sh | bash
#  Repo  : https://github.com/cybreign/cybreign-core
# ═══════════════════════════════════════════════════════════════════════════════

REPO="${CYBREIGN_REPO:-https://raw.githubusercontent.com/cybreign/cybreign-core/main}"
CYBREIGN_DEB_URL="$REPO/packages/main/cybreign.deb"
CYBREIGN_SCRIPT_URL="$REPO/cybreign"

TMPDIR_CLEAN="${TMPDIR:-/tmp}/cybreign_install_$$"
INSTALLED=0

# ── Colors ────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  R='\033[0m'; B='\033[1m'
  GRN='\033[0;32m'; CYN='\033[0;36m'
  YLW='\033[0;33m'; RED='\033[0;31m'
else
  R=''; B=''; GRN=''; CYN=''; YLW=''; RED=''
fi

msg()  { printf "${CYN}[cybreign]${R} %s\n" "$1"; }
ok()   { printf "${GRN}[cybreign] ✓${R} %s\n" "$1"; }
warn() { printf "${YLW}[cybreign] !${R} %s\n" "$1"; }
err()  { printf "${RED}[cybreign] ✗${R} %s\n" "$1" >&2; }
die()  { err "$1"; cleanup; exit 1; }

# ── Cleanup on exit ───────────────────────────────────────────────────────────

cleanup() {
  rm -rf "$TMPDIR_CLEAN" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

mkdir -p "$TMPDIR_CLEAN"

# ── Dependency check ──────────────────────────────────────────────────────────

check_deps() {
  local missing=""
  for dep in curl; do
    command -v "$dep" >/dev/null 2>&1 || missing="$missing $dep"
  done
  if [ -n "$missing" ]; then
    err "required tools not found:$missing"
    msg "install them first:"
    msg "  Termux : pkg install curl"
    msg "  Debian : sudo apt install curl"
    msg "  Fedora : sudo dnf install curl"
    exit 1
  fi
}

# ── Platform + arch detection ─────────────────────────────────────────────────

detect_platform() {
  ARCH="$(uname -m)"
  case "$ARCH" in
    aarch64|arm64) ARCH="aarch64" ;;
    armv7*|armhf)  ARCH="armhf"   ;;
    x86_64)        ARCH="x86_64"  ;;
    *)             ARCH="unknown" ;;
  esac

  if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX/bin" ]; then
    PLATFORM="termux"
    INSTALL_DIR="$PREFIX/bin"

  elif [ "$(uname)" = "Darwin" ]; then
    PLATFORM="macos"
    INSTALL_DIR="/usr/local/bin"

  elif grep -qi microsoft /proc/version 2>/dev/null; then
    PLATFORM="wsl"
    INSTALL_DIR="/usr/local/bin"

  elif [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    PLATFORM="${ID:-linux}"
    INSTALL_DIR="/usr/local/bin"

  else
    PLATFORM="linux"
    INSTALL_DIR="/usr/local/bin"
  fi

  export PLATFORM ARCH INSTALL_DIR
}

# ── sudo helper ───────────────────────────────────────────────────────────────

# Use sudo only when needed and available
need_sudo() {
  [ ! -w "$INSTALL_DIR" ] || return 1
  command -v sudo >/dev/null 2>&1 || {
    err "cannot write to $INSTALL_DIR and sudo is not available"
    err "run as root or ensure $INSTALL_DIR is writable"
    exit 1
  }
  return 0
}

run_privileged() {
  if need_sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

# ── Termux install (via .deb) ─────────────────────────────────────────────────

install_termux() {
  local deb="$TMPDIR_CLEAN/cybreign.deb"

  msg "downloading cybreign.deb..."
  curl -fsSL --progress-bar "$CYBREIGN_DEB_URL" -o "$deb" \
    || die "download failed from $CYBREIGN_DEB_URL"

  msg "installing via dpkg..."
  dpkg -i "$deb" || die "dpkg install failed"

  INSTALLED=1
}

# ── Script install (all other platforms) ─────────────────────────────────────

install_script() {
  local tmp="$TMPDIR_CLEAN/cybreign"

  msg "downloading cybreign script..."
  curl -fsSL "$CYBREIGN_SCRIPT_URL" -o "$tmp" \
    || die "download failed from $CYBREIGN_SCRIPT_URL"

  # Sanity check — make sure we got a shell script, not a 404 HTML page
  if ! head -1 "$tmp" | grep -q '^#!'; then
    die "downloaded file does not look like a shell script — check $CYBREIGN_SCRIPT_URL"
  fi

  msg "installing to $INSTALL_DIR/cybreign..."
  mkdir -p "$INSTALL_DIR" 2>/dev/null || true
  run_privileged install -m 755 "$tmp" "$INSTALL_DIR/cybreign" \
    || die "failed to install script to $INSTALL_DIR"

  INSTALLED=1
}

# ── macOS note ────────────────────────────────────────────────────────────────

install_macos() {
  # Ensure /usr/local/bin exists (may not on fresh macOS)
  if [ ! -d "/usr/local/bin" ]; then
    sudo mkdir -p /usr/local/bin
  fi
  install_script
}

# ── Verify installation ───────────────────────────────────────────────────────

verify_install() {
  # Refresh PATH (Termux especially)
  export PATH="$INSTALL_DIR:$PATH"

  if command -v cybreign >/dev/null 2>&1; then
    local ver
    ver=$(cybreign --version 2>/dev/null || echo "installed")
    ok "cybreign $ver is ready"
  else
    warn "cybreign installed to $INSTALL_DIR but not found in PATH"
    warn "add this to your shell profile and restart terminal:"
    warn "  export PATH=\"$INSTALL_DIR:\$PATH\""
  fi
}

# ── Already installed? ────────────────────────────────────────────────────────

check_existing() {
  if command -v cybreign >/dev/null 2>&1; then
    local ver
    ver=$(cybreign --version 2>/dev/null | awk '{print $2}' || echo "unknown")
    warn "cybreign v$ver is already installed — reinstalling/upgrading..."
  fi
}

# ── Print banner ──────────────────────────────────────────────────────────────

print_banner() {
  printf "\n${B}${CYN}"
  echo "  ██████╗██╗   ██╗██████╗ ██████╗ ███████╗██╗ ██████╗ ███╗  ██╗"
  echo " ██╔════╝╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║██╔════╝ ████╗ ██║"
  echo " ██║      ╚████╔╝ ██████╔╝██████╔╝█████╗  ██║██║  ███╗██╔██╗██║"
  echo " ██║       ╚██╔╝  ██╔══██╗██╔══██╗██╔══╝  ██║██║   ██║██║╚████║"
  echo " ╚██████╗   ██║   ██████╔╝██║  ██║███████╗██║╚██████╔╝██║ ╚███║"
  echo "  ╚═════╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝"
  printf "${R}\n"
  printf "  ${B}Universal Tool Manager${R}  —  github.com/cybreign/cybreign-core\n\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  print_banner

  check_deps
  detect_platform

  msg "platform : $PLATFORM ($ARCH)"
  msg "installing to : $INSTALL_DIR"
  echo

  check_existing

  case "$PLATFORM" in
    termux)
      install_termux
      ;;
    macos)
      install_macos
      ;;
    ubuntu|debian|kali|linuxmint|pop|elementary|zorin|raspbian|wsl)
      install_script
      ;;
    fedora|rhel|centos|almalinux|rocky)
      warn "RPM-based distro detected — installing script directly (no .rpm yet)"
      install_script
      ;;
    arch|manjaro|endeavouros)
      warn "Arch-based distro detected — installing script directly (no PKGBUILD yet)"
      install_script
      ;;
    opensuse*|sles)
      warn "openSUSE detected — installing script directly"
      install_script
      ;;
    *)
      warn "unknown platform '$PLATFORM' — attempting generic script install"
      install_script
      ;;
  esac

  echo
  verify_install

  echo
  printf "  ${GRN}Get started:${R}\n"
  printf "    cybreign list\n"
  printf "    cybreign install javix\n"
  printf "    cybreign help\n\n"
}

main "$@"
