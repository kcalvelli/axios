# axiOS Scripts

Utility scripts for axiOS framework.

## Directory Structure

```
scripts/
├── init-config.sh          # Interactive configuration generator
├── init-claude-mcp.sh      # Claude MCP project setup
├── wallpaper-blur.sh       # Wallpaper blur for Niri overview
├── templates/              # Config templates for init-config.sh
└── README.md              # This file
```

## User Scripts

### 🚀 init-config.sh

**Interactive configuration generator for axiOS.**

This is the main entry point for creating a new axiOS configuration:

```bash
mkdir ~/my-nixos-config && cd ~/my-nixos-config
nix run github:kcalvelli/axios#init
```

**What it does:**
- Asks questions about your system (hostname, hardware, preferences)
- Generates a complete configuration tailored to your needs
- Creates flake.nix, user.nix, disks.nix, and README.md
- Provides next steps for installation

**Recommended for all new users.**

---

### 🤖 init-claude-mcp.sh

**Initialize Claude CLI MCP configuration for a project.**

```bash
# Automatically installed to ~/scripts/ when AI module is enabled
~/scripts/init-claude-mcp.sh [project-directory]
```

**What it does:**
- Copies MCP server configuration template to project
- Sets up Claude CLI for the project
- Enables MCP servers (filesystem, nixos, journal, etc.)

**Requirements:**
- AI module enabled in your configuration
- Claude CLI installed

---

### 🎨 wallpaper-blur.sh

**Generates blurred wallpaper for Niri overview mode.**

```bash
# Automatically installed to ~/scripts/ when desktop module is enabled
~/scripts/wallpaper-blur.sh
```

**What it does:**
- Takes current wallpaper
- Creates blurred version for overview mode
- Saves to `~/.cache/niri/overview-blur.jpg`
- Called automatically by DankMaterialShell hooks

**Requirements:**
- Desktop module enabled
- Niri compositor
- ImageMagick (auto-installed)

This script runs automatically when your wallpaper changes.

---

## For axiOS Library Users

If you're using axiOS as a library (recommended), scripts are automatically available:

```nix
# In your flake that uses axios
axios.lib.mkSystem {
  modules.desktop = true;  # Installs wallpaper-blur.sh to ~/scripts/
  modules.ai = true;       # Installs init-claude-mcp.sh to ~/scripts/
}
```

Scripts work automatically with no manual setup needed.
