#!/usr/bin/env bash
# Download GGUF models for llama-cpp server
# This script helps users download recommended GGUF models from HuggingFace

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default download directory
DEFAULT_DIR="/var/lib/llama-models"

# Model database: name, HuggingFace URL, size, description, use case
declare -A MODELS=(
  # General purpose models
  ["mistral-7b-instruct-q4"]="TheBloke/Mistral-7B-Instruct-v0.2-GGUF|mistral-7b-instruct-v0.2.Q4_K_M.gguf|4.4GB|General purpose, good balance|general"
  ["mistral-7b-instruct-q5"]="TheBloke/Mistral-7B-Instruct-v0.2-GGUF|mistral-7b-instruct-v0.2.Q5_K_M.gguf|5.3GB|Higher quality, more VRAM|general"

  # Coding models
  ["codestral-22b-q4"]="bartowski/Codestral-22B-v0.1-GGUF|Codestral-22B-v0.1-Q4_K_M.gguf|13GB|Mistral's coding model|coding"
  ["deepseek-coder-6.7b-q4"]="TheBloke/deepseek-coder-6.7B-instruct-GGUF|deepseek-coder-6.7b-instruct.Q4_K_M.gguf|4.1GB|Lightweight coding model|coding"

  # Small/fast models
  ["phi-3-mini-q4"]="bartowski/Phi-3-mini-128k-instruct-GGUF|Phi-3-mini-128k-instruct-Q4_K_M.gguf|2.4GB|Fast, 128k context|small"
  ["gemma-2-9b-q4"]="bartowski/gemma-2-9b-it-GGUF|gemma-2-9b-it-Q4_K_M.gguf|5.4GB|Google's Gemma 2|small"

  # Large/powerful models
  ["llama-3-70b-q4"]="bartowski/Meta-Llama-3-70B-Instruct-GGUF|Meta-Llama-3-70B-Instruct-Q4_K_M.gguf|40GB|Powerful, needs 48GB+ VRAM|large"
  ["qwen2.5-32b-q4"]="bartowski/Qwen2.5-32B-Instruct-GGUF|Qwen2.5-32B-Instruct-Q4_K_M.gguf|19GB|Strong reasoning|large"
)

print_header() {
  echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  llama-cpp GGUF Model Downloader${NC}"
  echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
  echo ""
}

print_models() {
  local category=$1
  local title=$2

  echo -e "${GREEN}${title}${NC}"
  echo ""

  for model_key in "${!MODELS[@]}"; do
    IFS='|' read -r repo file size desc use_case <<< "${MODELS[$model_key]}"

    if [[ "$use_case" == "$category" ]]; then
      printf "  ${YELLOW}%-25s${NC} %s (${size})\n" "$model_key" "$desc"
    fi
  done
  echo ""
}

show_menu() {
  print_header

  echo "Recommended models by use case:"
  echo ""

  print_models "general" "📋 General Purpose (recommended for most users)"
  print_models "coding" "💻 Coding Specialized"
  print_models "small" "⚡ Small/Fast (lower VRAM)"
  print_models "large" "🚀 Large/Powerful (high VRAM required)"

  echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
  echo ""
}

download_model() {
  local model_key=$1
  local dest_dir=$2

  if [[ ! -v MODELS[$model_key] ]]; then
    echo -e "${RED}Error: Unknown model '$model_key'${NC}"
    return 1
  fi

  IFS='|' read -r repo file size desc use_case <<< "${MODELS[$model_key]}"

  local url="https://huggingface.co/${repo}/resolve/main/${file}"
  local dest_path="${dest_dir}/${file}"

  echo -e "${GREEN}Downloading: ${file}${NC}"
  echo -e "  Source: ${repo}"
  echo -e "  Size: ${size}"
  echo -e "  Destination: ${dest_path}"
  echo ""

  # Create directory if it doesn't exist
  if [[ ! -d "$dest_dir" ]]; then
    echo -e "${YELLOW}Creating directory: ${dest_dir}${NC}"
    if ! mkdir -p "$dest_dir" 2>/dev/null; then
      echo -e "${YELLOW}Need sudo to create ${dest_dir}${NC}"
      sudo mkdir -p "$dest_dir"
    fi
  fi

  # Check if file already exists
  if [[ -f "$dest_path" ]]; then
    echo -e "${YELLOW}File already exists: ${dest_path}${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Skipping download."
      return 0
    fi
  fi

  # Download with curl (shows progress)
  echo -e "${BLUE}Starting download...${NC}"
  if curl -L -o "$dest_path.tmp" --progress-bar "$url"; then
    mv "$dest_path.tmp" "$dest_path"
    echo -e "${GREEN}✓ Download complete!${NC}"
    echo ""
    echo -e "Add to your NixOS configuration:"
    echo -e "${YELLOW}  services.ai.local.llamaServer.model = \"${dest_path}\";${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}✗ Download failed${NC}"
    rm -f "$dest_path.tmp"
    return 1
  fi
}

# Interactive mode
interactive_mode() {
  local dest_dir="${1:-$DEFAULT_DIR}"

  show_menu

  echo "Enter model name to download (or 'q' to quit):"
  read -p "> " model_key

  if [[ "$model_key" == "q" || "$model_key" == "quit" ]]; then
    echo "Exiting."
    exit 0
  fi

  if [[ -n "$model_key" ]]; then
    download_model "$model_key" "$dest_dir"
  else
    echo -e "${RED}No model specified${NC}"
    exit 1
  fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
  # No arguments, run interactive mode
  interactive_mode
elif [[ "$1" == "--list" ]]; then
  show_menu
  exit 0
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
  print_header
  echo "Usage: $0 [MODEL_NAME] [DESTINATION_DIR]"
  echo ""
  echo "Options:"
  echo "  --list              List all available models"
  echo "  --help, -h          Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Interactive mode"
  echo "  $0 mistral-7b-instruct-q4            # Download to $DEFAULT_DIR"
  echo "  $0 phi-3-mini-q4 /home/user/models   # Download to custom directory"
  echo ""
  exit 0
else
  # Download specific model
  model_key=$1
  dest_dir="${2:-$DEFAULT_DIR}"
  download_model "$model_key" "$dest_dir"
fi
