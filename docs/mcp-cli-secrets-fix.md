# MCP Secrets Management via Shell Environment

## Problem

MCP tools like `mcp-cli` and `gemini-cli` don't support Claude Code's `passwordCommand` feature for loading secrets. When MCP servers are configured with API keys via agenix (like Brave Search and GitHub), these tools would fail with:

```
Error [MISSING_ENV_VAR]: Missing environment variable: ${BRAVE_API_KEY}
```

## Solution

Load secrets from agenix into the shell environment during initialization. This is simpler than creating wrapper scripts for each tool and provides universal access to all MCP tools.

**Benefits:**
- ✅ All MCP tools can access secrets (mcp-cli, gemini-cli, claude, etc.)
- ✅ No wrapper scripts needed
- ✅ One place to maintain secret loading logic
- ✅ Secrets loaded on shell startup automatically

## Implementation

**File**: `home/ai/mcp.nix` (lines 191-211)

Secrets are loaded into bash and zsh via `initExtra`:

```nix
# Load MCP secrets into shell environment
# These environment variables are used by mcp-cli, Gemini CLI, Claude Code, and other MCP tools
programs.bash.initExtra = lib.mkAfter ''
  # Load MCP secrets from agenix
  ${lib.optionalString (osConfig.services.ai.secrets.githubTokenPath != null) ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${osConfig.services.ai.secrets.githubTokenPath} 2>/dev/null | tr -d '\n')
  ''}
  ${lib.optionalString (osConfig.services.ai.secrets.braveApiKeyPath != null) ''
    export BRAVE_API_KEY=$(cat ${osConfig.services.ai.secrets.braveApiKeyPath} 2>/dev/null | tr -d '\n')
  ''}
'';

programs.zsh.initExtra = lib.mkAfter ''
  # Load MCP secrets from agenix
  ${lib.optionalString (osConfig.services.ai.secrets.githubTokenPath != null) ''
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${osConfig.services.ai.secrets.githubTokenPath} 2>/dev/null | tr -d '\n')
  ''}
  ${lib.optionalString (osConfig.services.ai.secrets.braveApiKeyPath != null) ''
    export BRAVE_API_KEY=$(cat ${osConfig.services.ai.secrets.braveApiKeyPath} 2>/dev/null | tr -d '\n')
  ''}
'';
```

## Usage

After rebuilding:

```bash
# Rebuild your system
cd ~/.config/nixos_config
sudo nixos-rebuild switch

# Open a new shell to load environment variables
exec $SHELL

# Test that secrets are loaded
echo $BRAVE_API_KEY     # Should show your API key
echo $GITHUB_PERSONAL_ACCESS_TOKEN  # Should show your token

# Test mcp-cli (secrets automatically available)
mcp-cli

# Expected output: List of all MCP servers and their tools (no errors)
```

## Compatibility

This approach works when:
- `services.ai.enable = true`
- `services.ai.mcp.enable = true` (default when AI is enabled)
- Secrets are configured via `services.ai.secrets.braveApiKeyPath` and `services.ai.secrets.githubTokenPath`

**Graceful degradation**: If secrets aren't configured, the environment variables simply won't be set (but other MCP servers without secrets will still work).

## Security Considerations

**Why shell environment is acceptable:**

1. **User-level secrets**: These secrets are already readable by your user account at `/run/user/$UID/agenix/*`
2. **Interactive tools**: These are interactive CLI tools you run in your shell, not system daemons
3. **Process isolation**: Any malicious process you run could already read the secret files directly
4. **Standard practice**: Many development tools expect API keys as environment variables (AWS CLI, gcloud, etc.)

**If you prefer tighter control**, Claude Code's `passwordCommand` still works for its native MCP integration (it doesn't need the environment variables).

## Tools Affected

**Tools that now work without wrappers:**
- ✅ `mcp-cli` - Dynamic MCP tool discovery
- ✅ `gemini` (gemini-cli) - Google Gemini CLI
- ✅ `claude` (claude-code) - Anthropic Claude Code CLI (also uses passwordCommand)
- ✅ Any other MCP-compatible tools

## Previous Approach (Rejected)

**v1: Wrapper scripts** (abandoned)
- Created `axios-gemini` wrapper to load secrets
- Created `mcp-cli` wrapper to load secrets
- ❌ Complex - needed wrapper for each tool
- ❌ Duplicated secret-loading logic
- ❌ Hard to maintain

**v2: Shell environment** (current)
- Load secrets once during shell initialization
- ✅ Simple - works for all tools
- ✅ One place to maintain
- ✅ Standard approach

## Maintenance Notes

**When adding new MCP servers with secrets:**

1. Add secret to `keith.nix` (downstream config):
   ```nix
   age.secrets.new-api-key.file = ./secrets/new-api-key.age;
   services.ai.secrets.newApiKeyPath = config.home-manager.users.keith.age.secrets.new-api-key.path;
   ```

2. Update shell initialization in `home/ai/mcp.nix`:
   ```nix
   programs.bash.initExtra = lib.mkAfter ''
     ${lib.optionalString (osConfig.services.ai.secrets.newApiKeyPath != null) ''
       export NEW_API_KEY=$(cat ${osConfig.services.ai.secrets.newApiKeyPath} 2>/dev/null | tr -d '\n')
     ''}
   '';

   programs.zsh.initExtra = lib.mkAfter ''
     ${lib.optionalString (osConfig.services.ai.secrets.newApiKeyPath != null) ''
       export NEW_API_KEY=$(cat ${osConfig.services.ai.secrets.newApiKeyPath} 2>/dev/null | tr -d '\n')
     ''}
   '';
   ```

3. Update MCP server configuration to reference the environment variable

## Testing

1. **Verify secrets are configured:**
   ```bash
   ls -la /run/user/$(id -u)/agenix/
   # Should show: brave-api-key, github-token
   ```

2. **Reload shell and test environment:**
   ```bash
   exec $SHELL
   echo $BRAVE_API_KEY
   echo $GITHUB_PERSONAL_ACCESS_TOKEN
   # Should display your secrets
   ```

3. **Test mcp-cli:**
   ```bash
   mcp-cli
   # Should list all servers without MISSING_ENV_VAR errors
   ```

4. **Test specific MCP server:**
   ```bash
   mcp-cli brave-search/brave_web_search '{"query": "NixOS"}'
   # Should return search results (not auth error)
   ```

5. **Test Gemini CLI:**
   ```bash
   gemini "Hello"
   # Should work without secret errors
   ```

## See Also

- [MCP Configuration](../home/ai/mcp.nix) - Main MCP server configuration
- [AI Module](../modules/ai/default.nix) - AI tools installation
- [Project Documentation](./.claude/project.md) - axios project overview
