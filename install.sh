#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Installs Starship, the JetBrainsMono Nerd Font, and only the AI CLI tools
# you explicitly opt into. Nothing else. Idempotent -- safe to re-run.
#
# AI CLI tools are opt-in, one at a time:
#   INSTALL_CLAUDE=true ./install.sh
#   INSTALL_CODEX=true INSTALL_GEMINI=true ./install.sh
#   INSTALL_CLAUDE=true INSTALL_CODEX=true INSTALL_GEMINI=true INSTALL_AGY=true ./install.sh
# ---------------------------------------------------------------------------

INSTALL_CLAUDE="${INSTALL_CLAUDE:-true}"
INSTALL_CODEX="${INSTALL_CODEX:-false}"
INSTALL_GEMINI="${INSTALL_GEMINI:-false}"
INSTALL_AGY="${INSTALL_AGY:-false}"

# ── Colours & helpers ─────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

ok()      { printf "${GREEN}  [OK]${NC} %s\n" "$*"; }
skip()    { printf "${YELLOW}  [SKIP]${NC} %s\n" "$*"; }
info()    { printf "${BLUE}  [INFO]${NC} %s\n" "$*"; }
err()     { printf "${RED}  [ERROR]${NC} %s\n" "$*" >&2; }
section() { printf "\n${BOLD}── %s ──${NC}\n" "$*"; }

# ── 1. Shell prompt (Starship) ────────────────────────────────────────────

section "Starship"

if command -v starship &>/dev/null; then
    skip "starship (already installed)"
else
    info "Installing starship ..."
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
    ok "starship installed to $HOME/.local/bin"
fi

STARSHIP_TEMPLATE="$SCRIPT_DIR/starship-toml-template"
STARSHIP_CONFIG="$HOME/.config/starship.toml"

if [[ -f "$STARSHIP_TEMPLATE" ]]; then
    mkdir -p "$HOME/.config"
    if [[ -L "$STARSHIP_CONFIG" ]] && [[ "$(readlink -f "$STARSHIP_CONFIG")" == "$(readlink -f "$STARSHIP_TEMPLATE")" ]]; then
        skip "starship.toml (already linked)"
    else
        if [[ -e "$STARSHIP_CONFIG" || -L "$STARSHIP_CONFIG" ]]; then
            BACKUP="$STARSHIP_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
            info "Backing up existing starship.toml to $BACKUP"
            mv "$STARSHIP_CONFIG" "$BACKUP"
        fi
        ln -s "$STARSHIP_TEMPLATE" "$STARSHIP_CONFIG"
        ok "starship.toml linked to $STARSHIP_CONFIG"
    fi
fi

# ── 2. AI CLI tools (opt-in, per tool) ────────────────────────────────────

section "AI CLI tools"

npm_ensure_user_prefix() {
    command -v npm &>/dev/null || return
    local prefix dir
    prefix="$(npm config get prefix 2>/dev/null)"
    dir="$prefix"
    while [[ ! -d "$dir" ]]; do
        dir="$(dirname "$dir")"
    done
    if [[ ! -w "$dir" ]]; then
        info "npm global prefix ($prefix) isn't writable; switching to $HOME/.local"
        mkdir -p "$HOME/.local/bin"
        npm config set prefix "$HOME/.local"
    fi
}

npm_ensure_user_prefix

npm_global_install() {
    local cmd="$1" pkg="$2"
    if command -v "$cmd" &>/dev/null; then
        skip "$cmd (already installed)"
    elif ! command -v npm &>/dev/null; then
        err "$cmd -- npm not found, install Node.js first"
    else
        info "Installing $pkg ..."
        npm install -g "$pkg"
        ok "$cmd installed"
    fi
}

if [[ "$INSTALL_CLAUDE" == "true" ]]; then
    npm_global_install "claude" "@anthropic-ai/claude-code"
else
    skip "claude (set INSTALL_CLAUDE=true to install)"
fi

if [[ "$INSTALL_CODEX" == "true" ]]; then
    npm_global_install "codex" "@openai/codex"
else
    skip "codex (set INSTALL_CODEX=true to install)"
fi

if [[ "$INSTALL_GEMINI" == "true" ]]; then
    npm_global_install "gemini" "@google/gemini-cli"
else
    skip "gemini (set INSTALL_GEMINI=true to install)"
fi

if [[ "$INSTALL_AGY" == "true" ]]; then
    if command -v agy &>/dev/null; then
        skip "agy (already installed)"
    else
        info "Installing Antigravity CLI ..."
        curl -fsSL https://antigravity.google/cli/install.sh | bash
        ok "Antigravity CLI installed"
    fi
else
    skip "agy (set INSTALL_AGY=true to install)"
fi

# ── 3. Nerd Font ───────────────────────────────────────────────────────────

section "Nerd Font"

FONT_DIR="$HOME/.local/share/fonts"

if fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
    skip "JetBrainsMono Nerd Font already installed"
else
    if ! command -v unzip &>/dev/null; then
        info "Installing unzip (needed to unpack the font) ..."
        sudo apt-get install -y unzip
    fi

    info "Downloading JetBrainsMono Nerd Font ..."
    mkdir -p "$FONT_DIR"
    FONT_ZIP="$(mktemp --suffix=.zip)"
    curl -fsSL -o "$FONT_ZIP" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -oq "$FONT_ZIP" -d "$FONT_DIR"
    rm -f "$FONT_ZIP"

    if command -v fc-cache &>/dev/null; then
        fc-cache -f "$FONT_DIR" &>/dev/null
    fi
    ok "JetBrainsMono Nerd Font installed to $FONT_DIR"
fi

printf "\n"
ok "Done."
