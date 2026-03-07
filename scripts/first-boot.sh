#!/usr/bin/env bash
# axiOS First-Boot Wizard
# Collects values that couldn't be gathered during installation
# (email, tailnet domain) and writes them into the NixOS config.
set -euo pipefail

MARKER="${HOME}/.cache/axios-first-boot-done"
CONFIG_DIR="/etc/nixos"

# ──────────────────────────────────────────────────────────────────
# Help & flags
# ──────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: axios-first-boot [OPTIONS]

axiOS first-boot wizard — collects email and tailnet domain.

Options:
  -h, --help    Show this help message
  --force       Run even if the wizard has already completed
EOF
  exit 0
fi

if [[ "${1:-}" == "--force" ]]; then
  rm -f "$MARKER"
fi

# Already done?
if [ -f "$MARKER" ]; then
  echo "First-boot wizard already completed. Use --force to re-run."
  exit 0
fi

# ──────────────────────────────────────────────────────────────────
# Prerequisites
# ──────────────────────────────────────────────────────────────────
if ! command -v gum >/dev/null 2>&1; then
  echo "Error: gum is required but not found on PATH."
  exit 1
fi

# ──────────────────────────────────────────────────────────────────
# Trap: clean exit on Ctrl-C
# ──────────────────────────────────────────────────────────────────
cleanup() {
  echo ""
  gum style --foreground 208 "Cancelled. Run 'axios-first-boot' to try again."
  exit 130
}
trap cleanup INT

# ──────────────────────────────────────────────────────────────────
# Gum wrapper functions (matching init-config.sh style)
# ──────────────────────────────────────────────────────────────────
banner() {
  gum style \
    --border double \
    --border-foreground 33 \
    --padding "1 3" \
    --align center \
    --bold \
    '   ____ __  ___(_)___  _____
  / __ `/ |/_/ / __ \/ ___/
 / /_/ />  </ / /_/ (__  )
 \__,_/_/|_/_/\____/____/

 First-Boot Setup'
}

section_header() {
  echo ""
  gum style --foreground 33 --bold "$1"
}

info_box() {
  gum style \
    --border rounded \
    --border-foreground 243 \
    --padding "0 2" \
    "$@"
}

ask_input() {
  local prompt="$1"
  local default="${2:-}"
  if [ -n "$default" ]; then
    gum input --placeholder "$prompt" --value "$default" --prompt "> " --width 50
  else
    local result=""
    while [ -z "$result" ]; do
      result=$(gum input --placeholder "$prompt" --prompt "> " --width 50)
      if [ -z "$result" ]; then
        gum style --foreground 196 "This field is required."
      fi
    done
    echo "$result"
  fi
}

ask_confirm() {
  local prompt="$1"
  local default="${2:-no}"
  if [ "$default" = "yes" ]; then
    gum confirm --default=yes "$prompt"
  else
    gum confirm "$prompt"
  fi
}

# ──────────────────────────────────────────────────────────────────
# Detect current user and hostname
# ──────────────────────────────────────────────────────────────────
CURRENT_USER="$(whoami)"
HOSTNAME="$(hostname)"

# ──────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────
banner

echo ""
info_box \
  "Welcome to axiOS!" \
  "" \
  "This wizard collects a few values that couldn't be" \
  "gathered during installation. It only runs once."

# ──────────────────────────────────────────────────────────────────
# Email
# ──────────────────────────────────────────────────────────────────
USER_FILE="${CONFIG_DIR}/users/${CURRENT_USER}.nix"
NEEDS_EMAIL="false"
CURRENT_EMAIL=""

if [ -f "$USER_FILE" ]; then
  # Check if the user file has an email field already
  if grep -q 'email\s*=' "$USER_FILE"; then
    CURRENT_EMAIL=$(grep -oP 'email\s*=\s*"\K[^"]+' "$USER_FILE" 2>/dev/null || echo "")
  fi
  if [ -z "$CURRENT_EMAIL" ]; then
    NEEDS_EMAIL="true"
  fi
fi

EMAIL=""
if [ "$NEEDS_EMAIL" = "true" ]; then
  section_header "Email Address"
  echo "Your email is used for git config and account settings."
  EMAIL=$(ask_input "Email address")
fi

# ──────────────────────────────────────────────────────────────────
# Tailnet Domain
# ──────────────────────────────────────────────────────────────────
NEEDS_TAILNET="false"
TAILNET_DOMAIN=""
HOST_FILE="${CONFIG_DIR}/hosts/${HOSTNAME}.nix"

if [ -f "$HOST_FILE" ]; then
  if grep -q 'CHANGE-ME\.ts\.net' "$HOST_FILE"; then
    NEEDS_TAILNET="true"
  fi
fi

if [ "$NEEDS_TAILNET" = "true" ]; then
  section_header "Tailscale Configuration"
  info_box \
    "Your configuration has placeholder tailnet domains." \
    "You can find your tailnet domain at:" \
    "  https://login.tailscale.com/admin/dns"
  echo ""
  TAILNET_DOMAIN=$(ask_input "Tailnet domain (e.g. taile0fb4.ts.net)")
fi

# ──────────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────────
HAS_CHANGES="false"

section_header "Summary"
summary_lines=()

if [ -n "$EMAIL" ]; then
  summary_lines+=("Email: $EMAIL")
  HAS_CHANGES="true"
fi

if [ -n "$TAILNET_DOMAIN" ]; then
  summary_lines+=("Tailnet domain: $TAILNET_DOMAIN")
  HAS_CHANGES="true"
fi

if [ "$HAS_CHANGES" = "false" ]; then
  info_box "No changes needed — your configuration is complete!"
  mkdir -p "$(dirname "$MARKER")"
  touch "$MARKER"
  echo ""
  gum style --foreground 42 "Setup complete!"
  echo ""
  echo "Press Enter to close."
  read -r
  exit 0
fi

info_box "${summary_lines[@]}"

echo ""
if ! ask_confirm "Apply these changes?"; then
  gum style --foreground 208 "Cancelled. Run 'axios-first-boot' to try again."
  exit 0
fi

# ──────────────────────────────────────────────────────────────────
# Apply changes
# ──────────────────────────────────────────────────────────────────
section_header "Applying changes..."

if [ -n "$EMAIL" ] && [ -f "$USER_FILE" ]; then
  # Insert email into axios.users.users block
  if grep -q "axios.users.users.${CURRENT_USER}" "$USER_FILE"; then
    # Add email after fullName line
    sudo sed -i "/fullName\s*=/a\\    email = \"${EMAIL}\";" "$USER_FILE"
  fi

  # Insert email into home-manager.users block if it exists
  if grep -q "home-manager.users.${CURRENT_USER}" "$USER_FILE"; then
    # Add axios.user.email inside the home-manager block
    sudo sed -i "/home-manager.users.${CURRENT_USER}\s*=\s*{/a\\    axios.user.email = \"${EMAIL}\";" "$USER_FILE"
  fi
  gum style --foreground 42 "  Updated email in ${USER_FILE}"
fi

if [ -n "$TAILNET_DOMAIN" ]; then
  # Replace all CHANGE-ME.ts.net occurrences in host configs
  for f in "${CONFIG_DIR}"/hosts/*.nix; do
    [ -f "$f" ] || continue
    if grep -q 'CHANGE-ME\.ts\.net' "$f"; then
      sudo sed -i "s/CHANGE-ME\.ts\.net/${TAILNET_DOMAIN}/g" "$f"
      gum style --foreground 42 "  Updated tailnet domain in ${f}"
    fi
  done
fi

# ──────────────────────────────────────────────────────────────────
# Offer rebuild
# ──────────────────────────────────────────────────────────────────
echo ""
if ask_confirm "Rebuild system now to apply changes?" "yes"; then
  echo ""
  gum style --foreground 33 --bold "Rebuilding system..."
  echo ""
  sudo nixos-rebuild switch --flake "${CONFIG_DIR}#${HOSTNAME}"
fi

# ──────────────────────────────────────────────────────────────────
# Mark done
# ──────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"

echo ""
gum style --foreground 42 --bold "First-boot setup complete!"
echo ""
echo "Press Enter to close."
read -r
