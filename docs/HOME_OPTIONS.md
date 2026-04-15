# Home-Manager Options Reference

This document lists all Cairn home-manager options available for user configuration.

## Quick Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cairn.terminal.neovim.enable` | bool | `false` | Enable neovim IDE preset |
| `cairn.pwa.enable` | bool | `false` | Enable PWA app generation |
| `cairn.wallpapers.enable` | bool | `false` | Enable curated wallpaper collection |
| `cairn.secrets.enable` | bool | auto | Enable age-encrypted secrets |
| `cairn.home.enableDefaults` | bool | `true` | Enable default home configuration |

---

## Terminal

### cairn.terminal.neovim

Full-featured neovim IDE with LSP, treesitter, telescope, git integration, and more.

```nix
cairn.terminal.neovim.enable = true;
```

**What you get:**
- lazy.nvim plugin management
- LSP for Nix and Lua (always), plus devshell languages
- Treesitter syntax highlighting
- Telescope fuzzy finder
- Neo-tree file explorer
- Git integration (gitsigns, lazygit, diffview)
- Which-key for keybind discovery
- Auto-session workspace persistence

**First launch:** Requires internet to download plugins. Subsequent launches are instant.

**Customization:** Edit `~/.config/nvim/init.lua` (user-owned, not managed by Nix)

**See:** [neovim-ide.md](neovim-ide.md) for full guide

---

## Desktop

### cairn.pwa

Generate Progressive Web App (PWA) desktop entries for web applications.

```nix
cairn.pwa = {
  enable = true;
  browser = "chromium";  # or "firefox"
  includeDefaults = true;

  # Add custom PWAs
  apps.myApp = {
    name = "My App";
    url = "https://example.com";
    icon = "web-browser";
    categories = [ "Network" ];
  };
};
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable PWA generation |
| `browser` | enum | `"chromium"` | Browser backend (`"chromium"` or `"firefox"`) |
| `includeDefaults` | bool | `true` | Include default Cairn PWAs |
| `iconPath` | path | `null` | Custom icon directory |
| `apps` | attrset | `{}` | Custom PWA definitions |

**Per-app options:**

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | string | yes | Display name |
| `url` | string | yes | App URL |
| `icon` | string | yes | Icon name or path |
| `categories` | list | no | XDG categories |
| `mimeTypes` | list | no | MIME types to handle |
| `isolated` | bool | no | Run in isolated profile |
| `description` | string | no | App description |
| `browser` | enum | no | Override global browser |

---

### cairn.wallpapers

Curated wallpaper collection with automatic updates.

```nix
cairn.wallpapers = {
  enable = true;
  autoUpdate = true;
};
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable wallpaper collection |
| `autoUpdate` | bool | `true` | Auto-update wallpapers |

---

## Secrets

### cairn.secrets

Age-encrypted secrets management for home-manager (powered by agenix).

```nix
cairn.secrets = {
  enable = true;
  identityPaths = [ "/home/user/.ssh/id_ed25519" ];
  secretsDir = ./secrets;
};

# Define secrets (agenix options, not cairn)
age.secrets.my-api-key = {
  file = ./secrets/my-api-key.age;
};
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cairn.secrets.enable` | bool | auto | Enable secrets (auto-enabled if system secrets enabled) |
| `cairn.secrets.identityPaths` | list | `[]` | SSH keys for decryption |
| `cairn.secrets.secretsDir` | path | `null` | Directory containing .age files |

**See:** [SECRETS_MODULE.md](SECRETS_MODULE.md) for complete guide

---

## Profile Defaults

### cairn.home

Core home-manager defaults set by Cairn profiles.

```nix
cairn.home = {
  enableDefaults = true;
  stateVersion = "24.05";
  flakePath = "/home/user/.config/nixos";
  email = "user@example.com";
};
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableDefaults` | bool | `true` | Enable Cairn default home configuration |
| `stateVersion` | string | required | Home-manager state version |
| `flakePath` | string | `null` | Path to your config flake |
| `email` | string | required | User email (for git, etc.) |

---

## Example Configuration

Complete example showing all home-manager options:

```nix
# In your user module (e.g., home/users/myuser.nix)
{ config, lib, pkgs, ... }:
{
  # Core settings
  cairn.home = {
    enableDefaults = true;
    stateVersion = "24.05";
    email = "me@example.com";
  };

  # Neovim IDE
  cairn.terminal.neovim.enable = true;

  # PWA apps
  cairn.pwa = {
    enable = true;
    browser = "chromium";
  };

  # Wallpapers
  cairn.wallpapers.enable = true;

  # Secrets (if you have API keys)
  cairn.secrets.enable = true;
  age.secrets.brave-api-key.file = ./secrets/brave-api-key.age;
}
```

---

## See Also

- [MODULE_REFERENCE.md](MODULE_REFERENCE.md) - NixOS system options and module reference
- [neovim-ide.md](neovim-ide.md) - Neovim IDE guide
- [SECRETS_MODULE.md](SECRETS_MODULE.md) - Secrets management
- [PWA_GUIDE.md](PWA_GUIDE.md) - PWA configuration
