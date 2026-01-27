# Tasks: mcp-gateway OAuth2 Authentication

**Prerequisites:**
- [x] `mcp-gateway-repo-split` completed (new repo exists)
- [x] `mcp-gateway-http-transport` completed (MCP protocol works)

## Phase 1: GitHub OAuth App Setup

- [x] **1.1 Create GitHub OAuth App**
  - Go to GitHub → Settings → Developer settings → OAuth Apps
  - Application name: `mcp-gateway`
  - Homepage URL: `https://axios-mcp-gateway.taile0fb4.ts.net`
  - Callback URL: `https://axios-mcp-gateway.taile0fb4.ts.net/oauth/callback`
  - Save Client ID

- [x] **1.2 Store secrets with agenix**
  - Create `secrets/mcp-gateway-github-client-secret.age`
  - Create `secrets/mcp-gateway-jwt-secret.age` (generate random)
  - Update secrets.nix with age identities

## Phase 2: Core Auth Implementation

- [x] **2.1 Add dependencies**
  ```toml
  # pyproject.toml
  "authlib>=1.3.0"
  "itsdangerous>=2.0.0"
  "python-jose[cryptography]>=3.3.0"
  ```

- [x] **2.2 Create auth module structure**
  ```
  src/mcp_gateway/auth/
  ├── __init__.py
  ├── config.py
  ├── middleware.py
  ├── oauth.py
  ├── tokens.py
  └── providers/
      ├── __init__.py
      ├── base.py
      └── github.py
  ```

- [x] **2.3 Implement configuration**
  - Environment variable parsing
  - Secret loading (env or file)
  - Optional user allowlist

- [x] **2.4 Implement JWT tokens**
  - Token generation with claims
  - Token validation
  - Refresh token support

- [x] **2.5 Implement GitHub provider**
  - OAuth2 authorization URL
  - Token exchange
  - User info fetching

## Phase 3: OAuth Endpoints

- [x] **3.1 Implement OAuth metadata endpoint**
  ```
  GET /.well-known/oauth-authorization-server
  ```
  - Return RFC 8414 compliant metadata
  - Include all supported endpoints

- [x] **3.2 Implement authorization endpoint**
  ```
  GET /oauth/authorize
  ```
  - Validate client_id, redirect_uri
  - Support PKCE (code_challenge)
  - Redirect to GitHub OAuth

- [x] **3.3 Implement callback endpoint**
  ```
  GET /oauth/callback
  ```
  - Receive GitHub auth code
  - Exchange for GitHub token
  - Get user info from GitHub
  - Check user allowlist (if configured)
  - Generate authorization code

- [x] **3.4 Implement token endpoint**
  ```
  POST /oauth/token
  ```
  - Exchange auth code for access token
  - Support refresh_token grant
  - Return JWT access token

- [x] **3.5 Implement client registration (optional)**
  ```
  POST /oauth/register
  ```
  - Dynamic Client Registration (DCR)
  - For MCP clients that support it

## Phase 4: Auth Middleware

- [x] **4.1 Create auth middleware**
  - Extract Bearer token from Authorization header
  - Validate JWT signature and claims
  - Attach user to request state

- [x] **4.2 Define public vs protected routes**
  - Public: `/.well-known/*`, `/oauth/*`, `/health`
  - Protected: `/mcp`, `/api/*`, `/tools/*`
  - Web UI: Session-based (cookie)

- [x] **4.3 Apply middleware to FastAPI app**
  - Add dependency to protected routes
  - Handle 401/403 responses

- [x] **4.4 Update MCP transport**
  - Validate auth before processing messages
  - Include user in session info

## Phase 5: Web UI Auth

- [x] **5.1 Add login flow**
  - Login button redirects to GitHub
  - Callback sets session cookie
  - Session stored server-side

- [x] **5.2 Update templates**
  - Show login/logout button
  - Display current user
  - Protect tool execution

## Phase 6: Testing

- [x] **6.1 Local testing**
  - Test OAuth flow manually
  - Test token validation
  - Test protected endpoints return 401 without token

- [ ] **6.2 Claude.ai integration testing**
  - Enable Tailscale Funnel (or use Tailscale Services)
  - Add connector in Claude.ai
  - Verify OAuth popup works
  - Verify tool execution with token

- [ ] **6.3 Edge cases**
  - Expired tokens
  - Invalid tokens
  - Revoked GitHub access
  - User not in allowlist

## Phase 7: Documentation

- [ ] **7.1 Update README**
  - OAuth setup instructions
  - GitHub App creation guide
  - Configuration reference

- [ ] **7.2 Update CLAUDE.md**
  - Auth architecture overview
  - Development with auth disabled

- [ ] **7.3 Update openspec**
  - Add auth spec to specs/gateway/

## Phase 8: NixOS Integration & Finalization

- [x] **8.1 Standalone NixOS module**
  - Move module to mcp-gateway repo
  - Add OAuth config options
  - Add Tailscale Services integration
  - Add PWA options

- [x] **8.2 Tailscale Services (replaces Funnel)**
  - Use `networking.tailscale.services` from axios
  - Unique DNS: `axios-mcp-gateway.<tailnet>.ts.net`
  - No port suffix needed (uses 443)

- [x] **8.3 PWA desktop entry**
  - Follow axios-ai-mail pattern
  - Local URL for server (hairpinning workaround)
  - Icon created

- [x] **8.4 Test end-to-end**
  - OAuth flow works via Tailscale URL
  - Web UI login/logout works

- [ ] **8.5 Archive proposal**
  - Move to `openspec/changes/archive/`

## Known Issues

- **Local PWA + OAuth**: OAuth flow requires Tailscale URL for callback.
  When accessing via `.local` URL, user must complete OAuth on Tailscale
  URL first, then session cookie is set on that domain. Consider:
  - Always use Tailscale URL for PWA on server
  - Or skip OAuth for localhost access

## Implementation Notes

**OAuth metadata (RFC 8414):**
```json
{
  "issuer": "https://axios-mcp-gateway.taile0fb4.ts.net",
  "authorization_endpoint": "https://axios-mcp-gateway.taile0fb4.ts.net/oauth/authorize",
  "token_endpoint": "https://axios-mcp-gateway.taile0fb4.ts.net/oauth/token",
  "response_types_supported": ["code"],
  "grant_types_supported": ["authorization_code", "refresh_token"],
  "code_challenge_methods_supported": ["S256"],
  "token_endpoint_auth_methods_supported": ["none"]
}
```

**Tailscale Services pattern (replaces Funnel):**
```nix
# In mcp-gateway NixOS module
networking.tailscale.services.${cfg.tailscaleServe.serviceName} = mkIf cfg.tailscaleServe.enable {
  enable = true;
  backend = "http://127.0.0.1:${toString cfg.port}";
  port = cfg.tailscaleServe.httpsPort;  # default 443
};
```

**GitHub OAuth URLs:**
- Authorize: `https://github.com/login/oauth/authorize`
- Token: `https://github.com/login/oauth/access_token`
- User API: `https://api.github.com/user`
