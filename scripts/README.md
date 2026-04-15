# Cairn Scripts

Utility scripts for Cairn framework.

## Directory Structure

```
scripts/
├── init-config.sh          # Interactive configuration generator
├── install.sh              # Bootstrap installer (enables flakes, launches init)
├── wallpaper-changed.sh    # Wallpaper change handler
├── fmt.sh                  # Code formatting helper
├── templates/              # Config templates for init-config.sh
└── README.md              # This file
```

## User Scripts

### init-config.sh

**Interactive configuration generator for Cairn.**

**Fresh NixOS install:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/kcalvelli/cairn/master/scripts/install.sh)
```

**Flakes already enabled:**
```bash
nix run --refresh github:kcalvelli/cairn#init
```

Offers three modes: scripted setup, add host to existing config, or AI-assisted with Claude Code. Detects hardware, collects preferences, generates all config files, and offers to rebuild.

---

### 🎨 wallpaper-changed.sh

**Handles wallpaper changes for Niri overview mode.**

```bash
# Called automatically by DankMaterialShell when wallpaper changes
~/scripts/wallpaper-changed.sh
```

**What it does:**
- Triggers when wallpaper changes
- Creates blurred version for overview mode
- Saves to `~/.cache/niri/overview-blur.jpg`
- Integrates with DankMaterialShell hooks

**Requirements:**
- Desktop module enabled
- Niri compositor
- ImageMagick (auto-installed)

This script runs automatically when your wallpaper changes via DankMaterialShell.

---

## For Cairn Library Users

If you're using Cairn as a library (recommended), scripts work automatically:

```nix
# In your flake that uses cairn
cairn.lib.mkSystem {
  modules.desktop = true;  # Enables wallpaper-changed.sh integration
  modules.ai = true;       # MCP configured declaratively (no script needed)
}
```

**MCP Configuration:**
MCP servers are now configured declaratively via home-manager (`home/ai/mcp.nix`). No manual setup script needed - everything is automatic when `services.ai.enable = true`.
