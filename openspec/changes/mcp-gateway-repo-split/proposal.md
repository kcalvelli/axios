# Proposal: Split mcp-gateway into Separate Repository

## Summary

Migrate `mcp-gateway` from `axios/pkgs/mcp-gateway` to its own repository at `github.com/kcalvelli/mcp-gateway`. This follows the established pattern of axios-ai-mail and mcp-dav as standalone services.

## Motivation

mcp-gateway has evolved beyond a simple helper utility into a substantial standalone product:

1. **REST API** - Tool management and execution endpoints
2. **MCP HTTP Transport** - Native MCP protocol for Claude.ai/Desktop
3. **Dynamic OpenAPI** - Per-tool endpoints for Open WebUI integration
4. **Web UI Orchestrator** - Visual management interface
5. **OAuth2 Authentication** (planned) - Secure remote access

This scope warrants independent versioning, releases, and documentation.

## Benefits

- **Independent evolution** - Version and release separately from axios
- **Reusability** - Others can use without pulling all of axios
- **Cleaner architecture** - Clear dependency boundaries
- **Follows established pattern** - Matches axios-ai-mail, mcp-dav structure
- **Prepares for OAuth** - Auth design not tied to axios assumptions

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
│   └── home-manager/            # Home-manager module
│       └── default.nix
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
| `modules/services/mcp-gateway.nix` | `modules/nixos/default.nix` |

### axios Changes After Migration

1. **Remove** `pkgs/mcp-gateway/` directory
2. **Remove** `modules/services/mcp-gateway.nix`
3. **Add** mcp-gateway flake input:
   ```nix
   inputs.mcp-gateway.url = "github:kcalvelli/mcp-gateway";
   ```
4. **Apply** overlay in lib/default.nix
5. **Update** home/ai/mcp.nix to use new module path

## Dependencies

The new repo will have minimal dependencies:

**Flake inputs:**
- `nixpkgs` (only required input)

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
