#!/usr/bin/env bash
# axios init - Interactive configuration generator for axiOS
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"

echo -e "${BOLD}${BLUE}"
cat << 'EOF'
   ____ __  ___(_)___  _____ 
  / __ `/ |/_/ / __ \/ ___/ 
 / /_/ />  </ / /_/ (__  )  
 \__,_/_/|_/_/\____/____/   
                            
 Configuration Generator
EOF
echo -e "${NC}"

echo -e "${GREEN}Welcome to axiOS!${NC}"
echo "This tool will help you create a personalized NixOS configuration."
echo ""

# Helper function to prompt for input
prompt() {
  local prompt_text="$1"
  local default_value="${2:-}"
  local result
  
  if [ -n "$default_value" ]; then
    echo -ne "${BLUE}${prompt_text}${NC} [${default_value}]: " >&2
    read result
    echo "${result:-$default_value}"
  else
    echo -ne "${BLUE}${prompt_text}${NC}: " >&2
    read result
    while [ -z "$result" ]; do
      echo -e "${RED}This field is required.${NC}" >&2
      echo -ne "${BLUE}${prompt_text}${NC}: " >&2
      read result
    done
    echo "$result"
  fi
}

# Helper function to prompt yes/no
prompt_bool() {
  local prompt_text="$1"
  local default_value="${2:-n}"
  local result
  
  if [ "$default_value" = "y" ]; then
    echo -ne "${BLUE}${prompt_text}${NC} [Y/n]: " >&2
    read result
    result="${result:-y}"
  else
    echo -ne "${BLUE}${prompt_text}${NC} [y/N]: " >&2
    read result
    result="${result:-n}"
  fi
  
  case "${result,,}" in
    y|yes) echo "true" ;;
    *) echo "false" ;;
  esac
}

# Helper function to choose from options
prompt_choice() {
  local prompt_text="$1"
  local default_value="$2"
  shift 2
  local options=("$@")
  
  echo -e "${BLUE}${prompt_text}${NC}" >&2
  for i in "${!options[@]}"; do
    if [ "${options[$i]}" = "$default_value" ]; then
      echo -e "  ${GREEN}$((i+1))) ${options[$i]} (default)${NC}" >&2
    else
      echo "  $((i+1))) ${options[$i]}" >&2
    fi
  done
  
  while true; do
    echo -ne "Choice [1-${#options[@]}]: " >&2
    read choice
    choice="${choice:-1}"
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      echo "${options[$((choice-1))]}"
      return
    fi
    echo -e "${RED}Invalid choice. Please enter a number between 1 and ${#options[@]}.${NC}" >&2
  done
}

echo -e "${BOLD}Let's configure your system:${NC}"
echo ""

echo -e "${BOLD}System Information:${NC}"
# Collect information
HOSTNAME=$(prompt "Hostname" "$(hostname 2>/dev/null || echo nixos)")
USERNAME=$(prompt "Username" "$(whoami 2>/dev/null || echo user)")
FULLNAME=$(prompt "Full name" "$(getent passwd $(whoami 2>/dev/null || echo $USER) 2>/dev/null | cut -d: -f5 | cut -d, -f1 || echo "$USERNAME")")
EMAIL=$(prompt "Email address")

echo ""
echo -e "${BOLD}Hardware Configuration:${NC}"
FORMFACTOR=$(prompt_choice "Form factor?" "desktop" "desktop" "laptop")
CPU=$(prompt_choice "CPU vendor?" "amd" "amd" "intel")
GPU=$(prompt_choice "GPU vendor?" "amd" "amd" "nvidia" "intel")

echo ""
echo -e "${BOLD}Optional Features:${NC}"
HAS_SSD=$(prompt_bool "Do you have an SSD?" "y")
ENABLE_GAMING=$(prompt_bool "Enable gaming support (Steam, GameMode)?" "n")
ENABLE_VIRT=$(prompt_bool "Enable virtualization (QEMU, virt-manager)?" "n")
ENABLE_SERVICES=$(prompt_bool "Enable system services (Caddy, Home Assistant, etc)?" "n")

# Derived values
IS_LAPTOP=$([ "$FORMFACTOR" = "laptop" ] && echo "true" || echo "false")
HOME_PROFILE="$FORMFACTOR"  # "desktop" becomes "workstation", but we'll use the formfactor
if [ "$FORMFACTOR" = "desktop" ]; then
  HOME_PROFILE="workstation"
fi

HAS_SSD_TEXT=""
if [ "$HAS_SSD" = "true" ]; then
  HAS_SSD_TEXT=", SSD"
fi

EXTRA_GROUPS=""
if [ "$ENABLE_VIRT" = "true" ]; then
  EXTRA_GROUPS='      "libvirtd"     # virtualization'
fi

DESCRIPTION="NixOS configuration for ${HOSTNAME}"
DATE=$(date +"%Y-%m-%d")

echo ""
echo -e "${GREEN}Configuration summary:${NC}"
echo "  Hostname: $HOSTNAME"
echo "  User: $USERNAME ($FULLNAME)"
echo "  Email: $EMAIL"
echo "  Form factor: $FORMFACTOR"
echo "  CPU: $CPU, GPU: $GPU"
echo "  SSD: $HAS_SSD"
echo "  Gaming: $ENABLE_GAMING"
echo "  Virtualization: $ENABLE_VIRT"
echo "  Services: $ENABLE_SERVICES"
echo ""
echo -ne "${BLUE}Generate configuration in current directory?${NC} [Y/n]: " >&2
read confirm
confirm="${confirm:-y}"

if [[ ! "${confirm,,}" =~ ^(y|yes)$ ]]; then
  echo "Cancelled."
  exit 0
fi

# Check if current directory is empty
if [ "$(ls -A . 2>/dev/null | wc -l)" -gt 0 ]; then
  echo -e "${YELLOW}Warning: Current directory is not empty.${NC}" >&2
  echo -ne "Continue anyway? [y/N]: " >&2
  read force
  if [[ ! "${force,,}" =~ ^(y|yes)$ ]]; then
    echo "Cancelled. Please run from an empty directory."
    exit 1
  fi
fi

echo ""
echo -e "${GREEN}Generating configuration files...${NC}"

# Generate files from templates
for template in flake.nix user.nix disks.nix README.md; do
  if [ -f "${TEMPLATE_DIR}/${template}.template" ]; then
    sed -e "s|{{HOSTNAME}}|${HOSTNAME}|g" \
        -e "s|{{USERNAME}}|${USERNAME}|g" \
        -e "s|{{FULLNAME}}|${FULLNAME}|g" \
        -e "s|{{EMAIL}}|${EMAIL}|g" \
        -e "s|{{FORMFACTOR}}|${FORMFACTOR}|g" \
        -e "s|{{CPU}}|${CPU}|g" \
        -e "s|{{GPU}}|${GPU}|g" \
        -e "s|{{HAS_SSD}}|${HAS_SSD}|g" \
        -e "s|{{IS_LAPTOP}}|${IS_LAPTOP}|g" \
        -e "s|{{HOME_PROFILE}}|${HOME_PROFILE}|g" \
        -e "s|{{ENABLE_GAMING}}|${ENABLE_GAMING}|g" \
        -e "s|{{ENABLE_VIRT}}|${ENABLE_VIRT}|g" \
        -e "s|{{ENABLE_SERVICES}}|${ENABLE_SERVICES}|g" \
        -e "s|{{DESCRIPTION}}|${DESCRIPTION}|g" \
        -e "s|{{DATE}}|${DATE}|g" \
        -e "s|{{HAS_SSD_TEXT}}|${HAS_SSD_TEXT}|g" \
        -e "s|{{EXTRA_GROUPS}}|${EXTRA_GROUPS}|g" \
        "${TEMPLATE_DIR}/${template}.template" > "${template}"
    echo "  ✓ ${template}"
  fi
done

# Create .gitignore
if [ -f "${TEMPLATE_DIR}/gitignore.template" ]; then
  cp "${TEMPLATE_DIR}/gitignore.template" .gitignore
  echo "  ✓ .gitignore"
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Configuration generated successfully!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  ${YELLOW}1. Review disk configuration:${NC}"
echo "     Edit disks.nix and change /dev/sda to your disk device"
echo "     Use 'lsblk' to find your disk"
echo ""
echo -e "  ${YELLOW}2. Initialize git repository:${NC}"
echo "     git init"
echo "     git add ."
echo "     git commit -m 'Initial axiOS configuration'"
echo ""
echo -e "  ${YELLOW}3. Install or rebuild:${NC}"
echo "     # For fresh installation:"
echo "     sudo nixos-install --flake .#${HOSTNAME}"
echo ""
echo "     # For existing system:"
echo "     sudo nixos-rebuild switch --flake .#${HOSTNAME}"
echo ""
echo -e "See ${BOLD}README.md${NC} for complete documentation."
echo ""
echo -e "${BLUE}Welcome to axiOS! 🚀${NC}"
