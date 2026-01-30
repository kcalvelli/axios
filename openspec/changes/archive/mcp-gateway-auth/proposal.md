# Proposal: OAuth2 Authentication for mcp-gateway

## Summary

Add OAuth2 authentication to mcp-gateway, enabling secure remote access from:
- Claude.ai Integrations (remote MCP connectors)
- Claude Desktop (remote MCP servers)
- axios-ai-chat (future Claude PWA)
- Any OAuth2-capable client

## Motivation

Currently mcp-gateway has no authentication. To expose it securely via Tailscale Funnel (or any public endpoint), we need proper auth. The MCP specification (2025-06-18) includes OAuth2 support, and Claude.ai natively handles OAuth flows for remote MCP servers.

## Architecture

```
┌─────────────────┐     ┌──────────────────────────────────────┐     ┌─────────────┐
│   Claude.ai     │     │           mcp-gateway                │     │ MCP Servers │
│   axios-ai-chat │────▶│  ┌─────────────────────────────┐    │────▶│  (86 tools) │
│   (clients)     │     │  │     OAuth2 Middleware       │    │     └─────────────┘
└─────────────────┘     │  │  - Token validation         │    │
        │               │  │  - Session management       │    │
        │               │  └─────────────────────────────┘    │
        │               └──────────────────────────────────────┘
        │                              │
        │    OAuth2 Authorization      │
        │    Code Flow                 │
        ▼                              ▼
┌──────────────────────────────────────────────┐
│              GitHub OAuth                     │
│  - Authorization endpoint                     │
│  - Token endpoint                             │
│  - User info endpoint                         │
└──────────────────────────────────────────────┘
```

## MCP OAuth Specification

The MCP spec defines OAuth discovery via RFC 8414:

**Discovery endpoint:** `GET /.well-known/oauth-authorization-server`

```json
{
  "issuer": "https://edge.taile0fb4.ts.net:8448",
  "authorization_endpoint": "https://edge.taile0fb4.ts.net:8448/oauth/authorize",
  "token_endpoint": "https://edge.taile0fb4.ts.net:8448/oauth/token",
  "registration_endpoint": "https://edge.taile0fb4.ts.net:8448/oauth/register",
  "response_types_supported": ["code"],
  "grant_types_supported": ["authorization_code", "refresh_token"],
  "code_challenge_methods_supported": ["S256"],
  "token_endpoint_auth_methods_supported": ["client_secret_post", "none"]
}
```

**Flow:**
1. Client discovers OAuth metadata
2. Client redirects user to `/oauth/authorize`
3. mcp-gateway redirects to GitHub OAuth
4. User authenticates with GitHub
5. GitHub redirects back to mcp-gateway with code
6. mcp-gateway exchanges code for GitHub token
7. mcp-gateway issues its own access token to client
8. Client uses token for MCP requests

## Implementation Details

### New Dependencies

```toml
# pyproject.toml additions
dependencies = [
    # ... existing
    "authlib>=1.3.0",      # OAuth2 library
    "itsdangerous>=2.0.0", # Secure token signing
    "python-jose>=3.3.0",  # JWT handling
]
```

### New Modules

```
src/mcp_gateway/
├── auth/
│   ├── __init__.py
│   ├── config.py          # OAuth configuration
│   ├── middleware.py      # FastAPI auth middleware
│   ├── oauth.py           # OAuth2 endpoints
│   ├── tokens.py          # Token generation/validation
│   └── providers/
│       ├── __init__.py
│       ├── base.py        # Provider interface
│       └── github.py      # GitHub OAuth provider
```

### Configuration

```python
# Environment variables or config file
MCP_GATEWAY_OAUTH_ENABLED=true
MCP_GATEWAY_OAUTH_PROVIDER=github
MCP_GATEWAY_GITHUB_CLIENT_ID=xxx
MCP_GATEWAY_GITHUB_CLIENT_SECRET=xxx  # or via agenix secret
MCP_GATEWAY_JWT_SECRET=xxx            # or via agenix secret
MCP_GATEWAY_ALLOWED_USERS=kcalvelli   # GitHub usernames (optional)
```

### Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/.well-known/oauth-authorization-server` | GET | No | OAuth metadata |
| `/oauth/authorize` | GET | No | Start OAuth flow |
| `/oauth/callback` | GET | No | GitHub callback |
| `/oauth/token` | POST | No | Exchange code for token |
| `/oauth/register` | POST | No | Dynamic client registration |
| `/mcp` | POST | Yes | MCP protocol (requires token) |
| `/api/*` | * | Yes | REST API (requires token) |
| `/tools/*` | * | Yes | Tool endpoints (requires token) |
| `/health` | GET | No | Health check |
| `/` | GET | No | Web UI (session-based auth) |

### Token Format

```python
# JWT payload
{
    "sub": "github:kcalvelli",      # Subject (provider:username)
    "iss": "mcp-gateway",           # Issuer
    "aud": "mcp-client",            # Audience
    "exp": 1706300000,              # Expiration
    "iat": 1706213600,              # Issued at
    "scope": "tools:read tools:execute"  # Permissions
}
```

### Middleware Implementation

```python
# auth/middleware.py
from fastapi import Request, HTTPException
from fastapi.security import HTTPBearer

security = HTTPBearer(auto_error=False)

async def require_auth(request: Request):
    """Validate OAuth token for protected endpoints."""
    # Skip auth for discovery/health endpoints
    if request.url.path in PUBLIC_PATHS:
        return None

    # Check Authorization header
    auth = request.headers.get("Authorization")
    if not auth or not auth.startswith("Bearer "):
        raise HTTPException(401, "Missing or invalid authorization")

    token = auth.split(" ", 1)[1]
    try:
        payload = verify_jwt(token)
        request.state.user = payload["sub"]
        return payload
    except JWTError as e:
        raise HTTPException(401, f"Invalid token: {e}")
```

## Security Considerations

1. **HTTPS Required** - OAuth only works over HTTPS (Tailscale Funnel provides this)
2. **User Allowlist** - Optional GitHub username allowlist for access control
3. **Token Expiration** - Short-lived access tokens (1 hour), refresh tokens (7 days)
4. **PKCE Required** - Proof Key for Code Exchange for public clients
5. **Secrets Management** - Client secret and JWT key via agenix

## Claude.ai Integration

With OAuth implemented:

1. User adds connector URL: `https://edge.taile0fb4.ts.net:8448/mcp`
2. Claude.ai fetches `/.well-known/oauth-authorization-server`
3. Claude.ai opens OAuth popup → redirects to GitHub
4. User logs in with GitHub
5. Claude.ai receives access token
6. All MCP requests include `Authorization: Bearer <token>`

## Future Enhancements

1. **Additional Providers** - Google, Microsoft, etc.
2. **API Keys** - Simple bearer tokens for programmatic access
3. **Scopes/Permissions** - Fine-grained tool access control
4. **Rate Limiting** - Per-user request limits
5. **Audit Logging** - Track who accessed what tools

## Dependencies

- **Prerequisite**: `mcp-gateway-repo-split` (new repo structure)
- **Prerequisite**: `mcp-gateway-http-transport` (MCP protocol support)

## GitHub OAuth App Setup

1. Go to GitHub → Settings → Developer settings → OAuth Apps
2. Click "New OAuth App"
3. Fill in:
   - **Application name**: `mcp-gateway`
   - **Homepage URL**: `https://edge.taile0fb4.ts.net:8448`
   - **Authorization callback URL**: `https://edge.taile0fb4.ts.net:8448/oauth/callback`
4. Save Client ID and Client Secret
5. Store secret via agenix

## Open Questions

1. Should we support multiple OAuth providers from the start?
   - **Recommendation**: Start with GitHub only, design for extensibility

2. How to handle CLI/programmatic access (no browser)?
   - **Recommendation**: Add API key support as alternative auth method

3. Should Web UI use same OAuth or separate session auth?
   - **Recommendation**: Same OAuth, with session cookies for browser convenience
