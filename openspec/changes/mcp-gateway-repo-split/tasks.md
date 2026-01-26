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
  - Add `mcp-servers-nix` as flake input

- [ ] **1.3 Migrate source code**
  - Copy `src/mcp_gateway/` from axios
  - Copy `pyproject.toml`
  - Verify build: `nix build`

- [ ] **1.4 Create NixOS module**
  - Systemd service definition
  - Configuration options (port, host, config path)

- [ ] **1.5 Create home-manager module with declarative MCP config**
  - Define `services.mcp-gateway.servers` options
  - Define `services.mcp-gateway.presets` options
  - Generate `~/.config/mcp/mcp_servers.json`
  - Generate `~/.mcp.json` (Claude Code config)
  - Generate system prompt file

## Phase 2: Declarative Configuration Module

- [ ] **2.1 Define server option schema**
  ```nix
  # modules/home-manager/servers.nix
  servers.<name> = {
    enable = mkEnableOption "server";
    package = mkOption { type = package; };
    args = mkOption { type = listOf str; default = []; };
    env = mkOption { type = attrsOf (submodule { ... }); };
  };
  ```

- [ ] **2.2 Define preset options**
  ```nix
  presets = {
    core = mkEnableOption "core servers (git, filesystem, time)";
    ai = mkEnableOption "AI servers (context7, sequential-thinking)";
    development = mkEnableOption "dev servers (github, brave-search)";
  };
  ```

- [ ] **2.3 Implement config generation**
  - Evaluate enabled servers
  - Build mcp_servers.json structure
  - Build Claude Code .mcp.json structure
  - Support env vars, commands, and agenix secrets

- [ ] **2.4 Migrate prompts from axios**
  - Move `home/ai/prompts/axios-system-prompt.md`
  - Make prompt generation dynamic based on enabled servers
  - Include available tools list in prompt

- [ ] **2.5 Support external MCP servers**
  - Allow servers from other flakes (axios-ai-mail, mcp-dav)
  - Define interface for external server packages
  ```nix
  servers.axios-ai-mail = {
    enable = true;
    package = inputs.axios-ai-mail.packages.${system}.default;
  };
  ```

## Phase 3: Documentation

- [ ] **3.1 Create CLAUDE.md**
  - Project context
  - Architecture overview
  - Development guidelines

- [ ] **3.2 Create README.md**
  - Installation instructions
  - Usage examples
  - Configuration reference (servers, presets)

- [ ] **3.3 Initialize openspec/**
  - project.md with goals
  - AGENTS.md for AI assistants
  - specs/gateway/spec.md

- [ ] **3.4 Add CONTRIBUTING.md**
  - Development setup
  - PR guidelines

## Phase 4: Update axios

- [ ] **4.1 Add mcp-gateway as flake input**
  ```nix
  inputs.mcp-gateway.url = "github:kcalvelli/mcp-gateway";
  ```

- [ ] **4.2 Apply overlay**
  - Add `inputs.mcp-gateway.overlays.default` to lib/default.nix

- [ ] **4.3 Simplify home/ai/default.nix**
  ```nix
  imports = [ inputs.mcp-gateway.homeManagerModules.default ];

  services.mcp-gateway = lib.mkIf config.services.ai.enable {
    enable = true;
    presets.core = lib.mkDefault true;
    presets.ai = lib.mkDefault true;
  };
  ```

- [ ] **4.4 Remove migrated code from axios**
  - Delete `pkgs/mcp-gateway/`
  - Delete `home/ai/mcp.nix`
  - Delete `home/ai/prompts/axios-system-prompt.md`
  - Delete `home/ai/prompts/mcp-cli-system-prompt.md`
  - Update `modules/default.nix` registry
  - Update `pkgs/default.nix` registry

- [ ] **4.5 Test full rebuild**
  - Verify mcp-gateway service works
  - Verify all MCP servers start
  - Verify Claude Code MCP config generated
  - Verify web UI works
  - Verify tools accessible via curl

## Phase 5: Finalization

- [ ] **5.1 Tag initial release**
  - v0.1.0 with current functionality + declarative config

- [ ] **5.2 Update axios CLAUDE.md**
  - Document new mcp-gateway integration
  - Remove outdated MCP config references

- [ ] **5.3 Archive this proposal**
  - Move to `openspec/changes/archive/`

## Implementation Notes

**Flake structure reference:**
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mcp-servers-nix.url = "github:nix-community/mcp-servers-nix";
  };

  outputs = { self, nixpkgs, mcp-servers-nix }: let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    overlays.default = final: prev: {
      mcp-gateway = self.packages.${final.system}.default;
    } // mcp-servers-nix.overlays.default final prev;

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

**NixOS service module:**
```nix
# modules/nixos/default.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.mcp-gateway;
in {
  options.services.mcp-gateway = {
    enable = lib.mkEnableOption "MCP Gateway";
    port = lib.mkOption { type = lib.types.port; default = 8085; };
    configFile = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mcp-gateway = { ... };
  };
}
```

**Home-manager declarative config module:**
```nix
# modules/home-manager/default.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.mcp-gateway;

  # Build server config from enabled servers
  enabledServers = lib.filterAttrs (n: v: v.enable) cfg.servers;

  serverConfig = lib.mapAttrs (name: server: {
    command = server.command or "${server.package}/bin/${name}";
    args = server.args;
    env = lib.mapAttrs (k: v:
      if v.command != null then "$(${v.command})"
      else if v.secret != null then { _secret = v.secret; }
      else v.value
    ) server.env;
  }) enabledServers;

  configFile = pkgs.writeText "mcp_servers.json" (builtins.toJSON {
    mcpServers = serverConfig;
  });
in {
  options.services.mcp-gateway = {
    enable = lib.mkEnableOption "MCP Gateway";

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "this server";
          package = lib.mkOption { type = lib.types.package; };
          command = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
          args = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
          env = lib.mkOption { type = lib.types.attrsOf (lib.types.submodule { ... }); default = {}; };
        };
      });
      default = {};
    };

    presets = {
      core = lib.mkEnableOption "core servers";
      ai = lib.mkEnableOption "AI servers";
      development = lib.mkEnableOption "development servers";
    };
  };

  config = lib.mkIf cfg.enable {
    # Generate config files
    home.file.".config/mcp/mcp_servers.json".source = configFile;
    home.file.".mcp.json".source = claudeCodeConfig;

    # Enable systemd service
    systemd.user.services.mcp-gateway = { ... };
  };
}
```

**Server definition with secrets:**
```nix
servers.brave-search = {
  enable = true;
  package = pkgs.mcp-server-brave-search;
  env.BRAVE_API_KEY = {
    secret = "brave-api-key";  # References agenix secret
  };
};

servers.github = {
  enable = true;
  package = pkgs.mcp-server-github;
  env.GITHUB_PERSONAL_ACCESS_TOKEN = {
    command = "gh auth token";  # Dynamic command
  };
};
```
