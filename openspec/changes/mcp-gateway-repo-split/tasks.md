# Tasks: mcp-gateway Repository Split

## Phase 1: Create New Repository

- [ ] **1.1 Initialize GitHub repository**
  - Create `github.com/kcalvelli/mcp-gateway`
  - Add MIT LICENSE
  - Add .gitignore (Python + Nix)

- [ ] **1.2 Create flake.nix**
  - Package definition (from current default.nix)
  - Overlay output
  - Dev shell
  - NixOS module output
  - Home-manager module output

- [ ] **1.3 Migrate source code**
  - Copy `src/mcp_gateway/` from axios
  - Copy `pyproject.toml`
  - Verify build: `nix build`

- [ ] **1.4 Create NixOS module**
  - Migrate from `axios/modules/services/mcp-gateway.nix`
  - Systemd service definition
  - Configuration options

- [ ] **1.5 Create home-manager module**
  - User-level configuration
  - MCP server definitions

## Phase 2: Documentation

- [ ] **2.1 Create CLAUDE.md**
  - Project context
  - Architecture overview
  - Development guidelines

- [ ] **2.2 Create README.md**
  - Installation instructions
  - Usage examples
  - Configuration reference

- [ ] **2.3 Initialize openspec/**
  - project.md with goals
  - AGENTS.md for AI assistants
  - specs/gateway/spec.md

- [ ] **2.4 Add CONTRIBUTING.md**
  - Development setup
  - PR guidelines

## Phase 3: Update axios

- [ ] **3.1 Add mcp-gateway as flake input**
  ```nix
  inputs.mcp-gateway.url = "github:kcalvelli/mcp-gateway";
  ```

- [ ] **3.2 Apply overlay**
  - Add to lib/default.nix overlays

- [ ] **3.3 Update module imports**
  - Update home/ai/mcp.nix to use new module

- [ ] **3.4 Remove old code**
  - Delete `pkgs/mcp-gateway/`
  - Delete `modules/services/mcp-gateway.nix` (if exists)
  - Update modules/default.nix registry

- [ ] **3.5 Test full rebuild**
  - Verify mcp-gateway service works
  - Verify MCP tools accessible
  - Verify web UI works

## Phase 4: Finalization

- [ ] **4.1 Tag initial release**
  - v0.1.0 with current functionality

- [ ] **4.2 Archive this proposal**
  - Move to `openspec/changes/archive/`

## Implementation Notes

**Flake structure reference** (from axios-ai-mail):
```nix
{
  outputs = { self, nixpkgs }: let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    overlays.default = final: prev: {
      mcp-gateway = self.packages.${final.system}.default;
    };

    nixosModules.default = import ./modules/nixos;
    homeManagerModules.default = import ./modules/home-manager;

    packages = forAllSystems (system: {
      default = /* python package */;
    });

    devShells = forAllSystems (system: {
      default = /* dev environment */;
    });
  };
}
```

**Service module pattern:**
```nix
# modules/nixos/default.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.mcp-gateway;
in {
  options.services.mcp-gateway = {
    enable = lib.mkEnableOption "MCP Gateway";
    port = lib.mkOption { type = lib.types.port; default = 8085; };
    # ... more options
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mcp-gateway = { ... };
  };
}
```
