# Proposal: Split mcp-gateway into Separate Repository

## Summary

Migrate `mcp-gateway` from `axios/pkgs/mcp-gateway` to its own repository at `github.com/kcalvelli/mcp-gateway`. This follows the established pattern of axios-ai-mail and mcp-dav as standalone services.

**Key architectural change**: mcp-gateway will own the declarative MCP server configuration, becoming the single source of truth for MCP setup. axios will import mcp-gateway's module rather than defining MCP config itself.

## Motivation

mcp-gateway has evolved beyond a simple helper utility into a substantial standalone product:

1. **REST API** - Tool management and execution endpoints
2. **MCP HTTP Transport** - Native MCP protocol for Claude.ai/Desktop
3. **Dynamic OpenAPI** - Per-tool endpoints for Open WebUI integration
4. **Web UI Orchestrator** - Visual management interface
5. **OAuth2 Authentication** (planned) - Secure remote access
6. **Declarative MCP Config** - Single source of truth for all MCP server definitions

This scope warrants independent versioning, releases, and documentation.

## Benefits

- **Independent evolution** - Version and release separately from axios
- **Reusability** - Others can use mcp-gateway without axios
- **Self-contained** - Owns its own declarative configuration module
- **Cleaner architecture** - Clear dependency boundaries
- **Follows established pattern** - Matches axios-ai-mail, mcp-dav structure
- **Prepares for OAuth** - Auth design not tied to axios assumptions

## Declarative MCP Configuration

mcp-gateway will own the declarative MCP server configuration module. Users configure servers through mcp-gateway's home-manager module:

```nix
# User config (via axios or standalone)
{
  services.mcp-gateway = {
    enable = true;
    port = 8085;

    # Declarative server configuration
    servers = {
      # Built-in servers (from mcp-servers-nix)
      git.enable = true;

      github = {
        enable = true;
        env.GITHUB_PERSONAL_ACCESS_TOKEN.command = "gh auth token";
      };

      filesystem = {
        enable = true;
        args = [ "/tmp" "~/Projects" ];
      };

      time.enable = true;
      context7.enable = true;
      sequential-thinking.enable = true;
      brave-search = {
        enable = true;
        env.BRAVE_API_KEY.secret = "brave-api-key";  # agenix integration
      };

      # External MCP servers (from other flakes)
      axios-ai-mail.enable = true;   # From axios-ai-mail flake
      mcp-dav.enable = true;         # From mcp-dav flake
      mcp-journal.enable = true;     # From mcp-journal flake
    };

    # Optional: preset groups for common configurations
    presets = {
      core = true;        # git, filesystem, time
      ai = true;          # context7, sequential-thinking
      development = true; # github, brave-search
    };
  };
}
```

**What this generates:**
- `~/.config/mcp/mcp_servers.json` - Gateway config (runtime)
- `~/.mcp.json` - Claude Code native MCP config
- `~/.config/ai/prompts/axios.md` - System prompt with available tools

**Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                      User's NixOS Config                        │
│  imports = [ mcp-gateway.homeManagerModules.default ];          │
│  services.mcp-gateway.servers.git.enable = true;                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    mcp-gateway module                           │
│  - Evaluates server declarations                                │
│  - Pulls packages from mcp-servers-nix overlay                  │
│  - Pulls packages from external flakes (axios-ai-mail, etc.)    │
│  - Generates config files                                       │
│  - Configures systemd service                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ~/.mcp.json    mcp_servers.json   axios.md
        (Claude Code)  (mcp-gateway)      (prompt)
```

**axios's simplified role:**
```nix
# axios home/ai/default.nix (after migration)
{ config, lib, pkgs, ... }:
{
  imports = [
    inputs.mcp-gateway.homeManagerModules.default
  ];

  # axios just provides opinionated defaults
  services.mcp-gateway = {
    enable = lib.mkDefault config.services.ai.enable;
    presets.core = lib.mkDefault true;
    presets.ai = lib.mkDefault true;
  };
}
```

## Repository Structure

```
mcp-gateway/
├── flake.nix                    # Nix flake with outputs
├── flake.lock
├── pyproject.toml               # Python package definition
├── CLAUDE.md                    # AI assistant instructions
├── README.md                    # User documentation
├── LICENSE                      # MIT
├── CONTRIBUTING.md
├── .gitignore
│
├── src/mcp_gateway/             # Python source
│   ├── __init__.py
│   ├── main.py                  # FastAPI application
│   ├── server_manager.py        # MCP server lifecycle
│   ├── models.py                # Pydantic models
│   ├── mcp_transport.py         # MCP HTTP transport
│   ├── auth/                    # OAuth2 (future)
│   │   ├── __init__.py
│   │   ├── oauth.py
│   │   └── providers/
│   └── templates/               # Web UI templates
│       ├── base.html
│       ├── index.html
│       ├── servers.html
│       └── tools.html
│
├── modules/                     # Nix modules
│   ├── nixos/                   # NixOS service module
│   │   └── default.nix
│   └── home-manager/            # Home-manager module (MCP config lives here)
│       ├── default.nix
│       ├── servers.nix          # Server option definitions
│       └── presets.nix          # Preset configurations
│
├── openspec/                    # Spec documentation
│   ├── project.md
│   ├── AGENTS.md
│   └── specs/
│       └── gateway/
│           └── spec.md
│
└── tests/                       # Test suite
    ├── conftest.py
    ├── test_api.py
    └── test_mcp_transport.py
```

## Flake Outputs

```nix
{
  # Package
  packages.${system}.default = mcp-gateway;

  # Overlay for pkgs.mcp-gateway
  overlays.default = final: prev: {
    mcp-gateway = self.packages.${final.system}.default;
  };

  # NixOS module (systemd service)
  nixosModules.default = ./modules/nixos;

  # Home-manager module (user config)
  homeManagerModules.default = ./modules/home-manager;

  # Dev shell
  devShells.${system}.default = ...;
}
```

## Migration from axios

### Files to Migrate

| Source (axios) | Destination (mcp-gateway) |
|----------------|---------------------------|
| `pkgs/mcp-gateway/src/` | `src/` |
| `pkgs/mcp-gateway/pyproject.toml` | `pyproject.toml` |
| `pkgs/mcp-gateway/default.nix` | Integrated into `flake.nix` |
| `home/ai/mcp.nix` (MCP config logic) | `modules/home-manager/` |
| `home/ai/prompts/` | `modules/home-manager/prompts/` |

### axios Changes After Migration

1. **Add** mcp-gateway flake input:
   ```nix
   inputs.mcp-gateway.url = "github:kcalvelli/mcp-gateway";
   ```

2. **Apply** overlay in lib/default.nix:
   ```nix
   overlays = [
     inputs.mcp-gateway.overlays.default
     # ... other overlays
   ];
   ```

3. **Simplify** home/ai/default.nix:
   ```nix
   { config, lib, inputs, ... }:
   {
     imports = [
       inputs.mcp-gateway.homeManagerModules.default
     ];

     # axios just sets defaults, users can override
     services.mcp-gateway = lib.mkIf config.services.ai.enable {
       enable = true;
       presets.core = lib.mkDefault true;
       presets.ai = lib.mkDefault true;
     };
   }
   ```

4. **Remove** from axios:
   - `pkgs/mcp-gateway/` directory
   - `home/ai/mcp.nix` (moved to mcp-gateway)
   - `home/ai/prompts/axios-system-prompt.md` (moved to mcp-gateway)
   - MCP server definitions from home/ai/

5. **Keep** in axios:
   - `services.ai.enable` option (controls whether mcp-gateway is enabled)
   - Integration with agenix secrets
   - User-level customizations in downstream configs

## Dependencies

**Flake inputs:**
- `nixpkgs` - Base packages
- `mcp-servers-nix` - MCP server packages and definitions (git, github, filesystem, etc.)

**Optional flake inputs** (for external MCP servers):
- `axios-ai-mail` - Email MCP server
- `mcp-dav` - Calendar/contacts MCP server
- `mcp-journal` - Journal MCP server

**Python dependencies:** (unchanged)
- fastapi, uvicorn, jinja2, pydantic, httpx, mcp, sse-starlette
- authlib (new, for OAuth2)

## Timeline

1. **Phase 1**: Create new repo with current code
2. **Phase 2**: Add OAuth2 authentication (separate proposal)
3. **Phase 3**: Remove from axios, add as flake input
4. **Phase 4**: Update axios documentation

## Open Questions

1. Should the NixOS service module stay in axios or move to mcp-gateway?
   - **Recommendation**: Move to mcp-gateway for self-contained deployment

2. Config file location: `~/.config/mcp/mcp_servers.json` or new path?
   - **Recommendation**: Keep current path for backward compatibility

## Related Proposals

- `mcp-gateway-http-transport` - MCP protocol support (in progress)
- `mcp-gateway-auth` - OAuth2 authentication (next)
