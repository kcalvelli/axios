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
TEMPLATE_DIR="${AXIOS_TEMPLATE_DIR:-${SCRIPT_DIR}/templates}"

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

# Detect hardware if running on NixOS
DETECTED_CPU=""
DETECTED_GPU=""
DETECTED_LAPTOP=""
DETECTED_SSD=""

if [ -f /etc/NIXOS ]; then
  echo -e "${BLUE}Detecting hardware...${NC}"
  
  # Detect CPU vendor
  if grep -q "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
    DETECTED_CPU="intel"
    echo "  ✓ Detected Intel CPU"
  elif grep -q "AuthenticAMD" /proc/cpuinfo 2>/dev/null; then
    DETECTED_CPU="amd"
    echo "  ✓ Detected AMD CPU"
  fi
  
  # Detect GPU vendor
  if lspci 2>/dev/null | grep -i vga | grep -qi nvidia; then
    DETECTED_GPU="nvidia"
    echo "  ✓ Detected NVIDIA GPU"
  elif lspci 2>/dev/null | grep -i vga | grep -qi amd; then
    DETECTED_GPU="amd"
    echo "  ✓ Detected AMD GPU"
  elif lspci 2>/dev/null | grep -i vga | grep -qi intel; then
    DETECTED_GPU="intel"
    echo "  ✓ Detected Intel GPU"
  fi
  
  # Detect if laptop (check for battery)
  if [ -d /sys/class/power_supply/BAT* ] 2>/dev/null || [ -d /sys/class/power_supply/battery ] 2>/dev/null; then
    DETECTED_LAPTOP="true"
    echo "  ✓ Detected laptop (battery found)"
  else
    DETECTED_LAPTOP="false"
    echo "  ✓ Detected desktop (no battery)"
  fi
  
  # Detect SSD (check if any disk has rotation rate of 0)
  if lsblk -d -o name,rota 2>/dev/null | grep -q "0$"; then
    DETECTED_SSD="true"
    echo "  ✓ Detected SSD"
  else
    DETECTED_SSD="false"
    echo "  ✓ Detected HDD (no SSD)"
  fi
  
  echo ""
fi

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

# Form factor - only ask if not detected
if [ -n "$DETECTED_LAPTOP" ]; then
  if [ "$DETECTED_LAPTOP" = "true" ]; then
    FORMFACTOR="laptop"
    echo -e "${GREEN}✓ Form factor: laptop (detected)${NC}"
  else
    FORMFACTOR="desktop"
    echo -e "${GREEN}✓ Form factor: desktop (detected)${NC}"
  fi
else
  FORMFACTOR=$(prompt_choice "Form factor?" "desktop" "desktop" "laptop")
fi

# CPU - only ask if not detected
if [ -n "$DETECTED_CPU" ]; then
  CPU="$DETECTED_CPU"
  echo -e "${GREEN}✓ CPU: $CPU (detected)${NC}"
else
  CPU=$(prompt_choice "CPU vendor?" "amd" "amd" "intel")
fi

# GPU - only ask if not detected
if [ -n "$DETECTED_GPU" ]; then
  GPU="$DETECTED_GPU"
  echo -e "${GREEN}✓ GPU: $GPU (detected)${NC}"
else
  GPU=$(prompt_choice "GPU vendor?" "amd" "amd" "nvidia" "intel")
fi

echo ""
echo -e "${BOLD}Optional Features:${NC}"

# SSD - only ask if not detected
if [ -n "$DETECTED_SSD" ]; then
  HAS_SSD="$DETECTED_SSD"
  echo -e "${GREEN}✓ SSD: $HAS_SSD (detected)${NC}"
else
  HAS_SSD=$(prompt_bool "Do you have an SSD?" "y")
fi

ENABLE_GAMING=$(prompt_bool "Enable gaming support (Steam, GameMode)?" "n")
ENABLE_AI=$(prompt_bool "Enable AI services (Ollama, OpenWebUI, Claude CLI)?" "n")
ENABLE_SECRETS=$(prompt_bool "Enable secrets management (age-encrypted secrets)?" "n")
ENABLE_VIRT=$(prompt_bool "Enable virtualization (QEMU, virt-manager)?" "n")

# Virtualization sub-options
if [ "$ENABLE_VIRT" = "true" ]; then
  echo -e "${BLUE}  Which virtualization features?${NC}"
  ENABLE_LIBVIRT=$(prompt_bool "  Enable libvirt/KVM (virt-manager)?" "y")
  ENABLE_CONTAINERS=$(prompt_bool "  Enable containers (Podman)?" "y")
else
  ENABLE_LIBVIRT="false"
  ENABLE_CONTAINERS="false"
fi

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

DESCRIPTION="NixOS configuration for ${HOSTNAME}"
DATE=$(date +"%Y-%m-%d")

# Detect available disks for disk configuration
DETECTED_DISKS=()
DISK_DEVICE="/dev/sda"  # Default fallback

if [ -f /etc/NIXOS ]; then
  echo ""
  echo -e "${BLUE}Detecting available disks...${NC}"
  
  # Get list of block devices (exclude loop, cd, etc)
  while IFS= read -r disk; do
    DETECTED_DISKS+=("$disk")
    size=$(lsblk -dno SIZE "/dev/$disk" 2>/dev/null || echo "unknown")
    echo "  • /dev/$disk ($size)"
  done < <(lsblk -dno NAME -e 7,11 | grep -v '^loop\|^sr')
  
  if [ ${#DETECTED_DISKS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Which disk should be used for installation?${NC}"
    echo -e "${RED}WARNING: This disk will be completely erased!${NC}"
    
    # Build options array with full paths
    DISK_OPTIONS=()
    for disk in "${DETECTED_DISKS[@]}"; do
      size=$(lsblk -dno SIZE "/dev/$disk" 2>/dev/null || echo "unknown")
      DISK_OPTIONS+=("/dev/$disk ($size)")
    done
    
    # Let user choose
    selected=$(prompt_choice "Select installation disk:" "${DISK_OPTIONS[0]}" "${DISK_OPTIONS[@]}")
    # Extract just the device path (before the space/paren)
    DISK_DEVICE=$(echo "$selected" | cut -d' ' -f1)
    
    echo -e "${GREEN}Selected: $DISK_DEVICE${NC}"
  fi
fi

# Conditional secrets config for host template (single line for sed)
if [ "$ENABLE_SECRETS" = "true" ]; then
  SECRETS_CONFIG="      # Configure secrets directory for automatic discovery\\n      secrets.secretsDir = ../secrets;"
else
  SECRETS_CONFIG=""
fi

echo ""
echo -e "${GREEN}Configuration summary:${NC}"
echo "  Hostname: $HOSTNAME"
echo "  User: $USERNAME ($FULLNAME)"
echo "  Email: $EMAIL"
echo "  Form factor: $FORMFACTOR"
echo "  CPU: $CPU, GPU: $GPU"
echo "  SSD: $HAS_SSD"
echo "  Gaming: $ENABLE_GAMING"
echo "  AI Services: $ENABLE_AI"
echo "  Secrets: $ENABLE_SECRETS"
echo "  Virtualization: $ENABLE_VIRT"
if [ "$ENABLE_VIRT" = "true" ]; then
  echo "    - libvirt: $ENABLE_LIBVIRT"
  echo "    - containers: $ENABLE_CONTAINERS"
fi
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

# Create directory structure
mkdir -p "hosts/${HOSTNAME}"
echo "  ✓ hosts/${HOSTNAME}/"

# Create secrets directory if secrets module is enabled
if [ "$ENABLE_SECRETS" = "true" ]; then
  mkdir -p "secrets"
  echo "  ✓ secrets/"
  
  # Create a README in secrets directory
  cat > "secrets/README.md" << 'EOF'
# Secrets Directory

This directory is for age-encrypted secrets.

## Quick Start

1. Get your host's public SSH key:
   ```bash
   sudo cat /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Create your first secret:
   ```bash
   echo "my-secret-value" | age -r "ssh-ed25519 AAAA... root@hostname" -o secrets/my-secret.age
   ```

3. Enable in your host config:
   Edit `hosts/hostname.nix` and add:
   ```nix
   extraConfig = {
     secrets.secretsDir = ../secrets;
   };
   ```

4. Rebuild and the secret will be available at `/run/agenix/my-secret`

See https://github.com/kcalvelli/axios/blob/master/docs/SECRETS_MODULE.md for details.
EOF
  echo "  ✓ secrets/README.md"
fi

# Generate files from templates
for template in flake.nix user.nix README.md; do
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
        -e "s|{{ENABLE_AI}}|${ENABLE_AI}|g" \
        -e "s|{{ENABLE_SECRETS}}|${ENABLE_SECRETS}|g" \
        -e "s|{{ENABLE_VIRT}}|${ENABLE_VIRT}|g" \
        -e "s|{{ENABLE_LIBVIRT}}|${ENABLE_LIBVIRT}|g" \
        -e "s|{{ENABLE_CONTAINERS}}|${ENABLE_CONTAINERS}|g" \
        -e "s|{{DESCRIPTION}}|${DESCRIPTION}|g" \
        -e "s|{{DATE}}|${DATE}|g" \
        -e "s|{{HAS_SSD_TEXT}}|${HAS_SSD_TEXT}|g" \
        "${TEMPLATE_DIR}/${template}.template" > "${template}"
    echo "  ✓ ${template}"
  fi
done

# Generate host config file
if [ -f "${TEMPLATE_DIR}/host.nix.template" ]; then
  sed -e "s|{{HOSTNAME}}|${HOSTNAME}|g" \
      -e "s|{{USERNAME}}|${USERNAME}|g" \
      -e "s|{{FORMFACTOR}}|${FORMFACTOR}|g" \
      -e "s|{{CPU}}|${CPU}|g" \
      -e "s|{{GPU}}|${GPU}|g" \
      -e "s|{{HAS_SSD}}|${HAS_SSD}|g" \
      -e "s|{{IS_LAPTOP}}|${IS_LAPTOP}|g" \
      -e "s|{{HOME_PROFILE}}|${HOME_PROFILE}|g" \
      -e "s|{{ENABLE_GAMING}}|${ENABLE_GAMING}|g" \
      -e "s|{{ENABLE_AI}}|${ENABLE_AI}|g" \
      -e "s|{{ENABLE_SECRETS}}|${ENABLE_SECRETS}|g" \
      -e "s|{{ENABLE_VIRT}}|${ENABLE_VIRT}|g" \
      -e "s|{{ENABLE_LIBVIRT}}|${ENABLE_LIBVIRT}|g" \
      -e "s|{{ENABLE_CONTAINERS}}|${ENABLE_CONTAINERS}|g" \
      "${TEMPLATE_DIR}/host.nix.template" | \
      sed "s|{{SECRETS_CONFIG}}|${SECRETS_CONFIG}|g" > "hosts/${HOSTNAME}.nix"
  echo "  ✓ hosts/${HOSTNAME}.nix"
fi

# Generate disks.nix in host subdirectory
if [ -f "${TEMPLATE_DIR}/disks.nix.template" ]; then
  sed -e "s|{{HOSTNAME}}|${HOSTNAME}|g" \
      -e "s|{{DATE}}|${DATE}|g" \
      -e "s|{{DISK_DEVICE}}|${DISK_DEVICE}|g" \
      "${TEMPLATE_DIR}/disks.nix.template" > "hosts/${HOSTNAME}/disks.nix"
  echo "  ✓ hosts/${HOSTNAME}/disks.nix"
fi

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
if [ -f /etc/NIXOS ]; then
  echo -e "  ${YELLOW}1. Review configuration:${NC}"
  echo "     Check hosts/${HOSTNAME}.nix for any customizations"
  echo "     Disk: ${DISK_DEVICE} (auto-detected)"
else
  echo -e "  ${YELLOW}1. Review disk configuration:${NC}"
  echo "     Edit hosts/${HOSTNAME}/disks.nix and change ${DISK_DEVICE} to your disk device"
  echo "     Use 'lsblk' to find your disk"
fi
echo ""
echo -e "  ${YELLOW}2. Review host configuration:${NC}"
echo "     Edit hosts/${HOSTNAME}.nix to customize settings"
echo "     See extraConfig section for additional options"
echo ""
echo -e "  ${YELLOW}3. Initialize git repository:${NC}"
echo "     git init"
echo "     git add ."
echo "     git commit -m 'Initial axiOS configuration'"
echo ""
echo -e "  ${YELLOW}4. Install or rebuild:${NC}"
echo "     # For fresh installation:"
echo "     sudo nixos-install --flake .#${HOSTNAME}"
echo ""
echo "     # For existing system:"
echo "     sudo nixos-rebuild switch --flake .#${HOSTNAME}"
echo ""
echo -e "See ${BOLD}README.md${NC} for complete documentation."
echo ""
echo -e "${BLUE}Welcome to axiOS! 🚀${NC}"
