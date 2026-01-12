# Advanced Tool Use in axiOS - Quick Start Guide

This document provides a quick overview of advanced tool use capabilities and next steps.

## TL;DR

**axiOS already implements dynamic tool discovery** via `mcp-cli`, achieving 99% token reduction similar to Anthropic's Tool Search Tool feature. The other advanced features (Programmatic Tool Calling, Tool Use Examples) are available via the Anthropic API but not yet in Claude Code CLI.

## What You Get Today

### ✅ Available Now in axiOS

1. **Dynamic Tool Discovery (mcp-cli)**
   - 99% token reduction (47K → 400 tokens)
   - Already configured and working
   - Used automatically via axios system prompt

2. **10 Pre-configured MCP Servers**
   - Core tools: git, github, filesystem, time, journal
   - AI enhancement: sequential-thinking, context7
   - Search: brave-search
   - Development: nix-devshell-mcp
   - Hardware: ultimate64 (optional)

3. **Automatic System Prompt Injection**
   - Teaches Claude about mcp-cli usage
   - Documents available MCP servers
   - NixOS-specific guidance
   - Custom instructions support

### 🔮 Coming Soon (API-only for now)

1. **Tool Search Tool** - On-demand loading with `defer_loading: true`
2. **Programmatic Tool Calling** - Python code orchestration in sandbox
3. **Tool Use Examples** - Concrete usage patterns in tool definitions

**Status**: Requires API usage with `betas=["advanced-tool-use-2025-11-20"]`

## Quick Actions

### 1. Verify Your Current Setup

```bash
# Check installed MCP servers
mcp-cli

# Test dynamic discovery
mcp-cli grep "file"

# View axios system prompt
cat ~/.config/ai/prompts/axios.md

# Verify Claude Code config
cat ~/.mcp.json | jq '.mcpServers | keys'
```

### 2. Add New MCP Servers

See **100+ examples** in `/home/keith/Projects/axios/home/ai/mcp-examples.nix`

**Quick example - Add SQLite and Docker:**

```nix
# Edit home/ai/mcp.nix
settings.servers = {
  # ... existing servers ...

  sqlite = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-sqlite"
      "--db-path"
      "${config.home.homeDirectory}/.local/share/myapp/db.sqlite"
    ];
  };

  docker = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "@modelcontextprotocol/server-docker"
    ];
  };
};
```

Then rebuild:
```bash
home-manager switch
mcp-cli  # Verify new servers appear
```

### 3. Use Advanced Features via API (Optional)

If you need the beta features now, create an API wrapper:

```python
# ~/bin/claude-advanced.py
import anthropic
import subprocess
import json

client = anthropic.Anthropic()

# Tool with defer_loading
tools = [{
    "name": "search_files",
    "description": "Search for files",
    "defer_loading": True,  # ← On-demand loading
    "input_schema": { "type": "object", "properties": {...} }
}]

# Tool with programmatic calling
tools.append({
    "name": "read_file",
    "description": "Read file contents",
    "allowed_callers": ["code_execution_20250825"],  # ← Python orchestration
    "input_schema": { "type": "object", "properties": {...} }
})

response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    extra_headers={"anthropic-beta": "advanced-tool-use-2025-11-20"},
    messages=[{"role": "user", "content": "Your task"}],
    tools=tools
)
```

### 4. Enhance System Prompt

Add custom instructions for advanced tool use patterns:

```nix
# In your NixOS config
services.ai.systemPrompt.extraInstructions = ''
  ## Advanced Tool Use Strategy

  For complex multi-step tasks:
  1. Use mcp-cli grep to dynamically discover relevant tools
  2. Only inspect full schemas when necessary (saves context)
  3. Process large datasets locally, return summaries only
  4. Leverage sequential-thinking for complex reasoning

  Example workflow:
  - Task: "Analyze GitHub issues and create Jira tickets"
  - Use mcp-cli grep "github" and mcp-cli grep "jira"
  - Execute tools and process results
  - Return summary of actions taken
'';
```

## Documentation

### 📚 Full Guides

1. **[advanced-tool-use.md](./advanced-tool-use.md)** (4KB)
   - Complete explanation of all 3 beta features
   - Implementation examples
   - Current vs future capabilities

2. **[adding-mcp-servers.md](./adding-mcp-servers.md)** (12KB)
   - Step-by-step guide for adding new servers
   - Secrets management with agenix
   - Troubleshooting common issues

3. **[mcp-examples.nix](../home/ai/mcp-examples.nix)** (8KB)
   - 50+ ready-to-use server configurations
   - Organized by category (cloud, databases, productivity, etc.)
   - Copy-paste examples with setup instructions

### 🎯 Quick Reference

| Need | See |
|------|-----|
| How to add server | `adding-mcp-servers.md` |
| Ready-to-use configs | `mcp-examples.nix` |
| Beta feature details | `advanced-tool-use.md` |
| Current capabilities | This file |

## Comparison: axiOS vs Beta Features

| Feature | axiOS (Today) | API Beta | Status |
|---------|---------------|----------|--------|
| Dynamic tool discovery | ✅ mcp-cli (99% reduction) | ✅ Tool Search Tool (85% reduction) | **axiOS better!** |
| On-demand schema loading | ✅ Via bash tool + mcp-cli | ✅ Via defer_loading | **Equivalent** |
| Programmatic orchestration | ⚠️ Manual (bash scripting) | ✅ Automatic (Python sandbox) | API advantage |
| Tool use examples | ⚠️ Via system prompt | ✅ In tool definitions | API advantage |
| Claude Code CLI support | ✅ Full support | ❌ API only | **axiOS better!** |

## Best Practices

### Do This ✅

1. **Use mcp-cli for discovery** - Already 99% token reduction
2. **Add servers declaratively** - Use `home/ai/mcp.nix`
3. **Test with mcp-cli first** - Verify before using in Claude
4. **Leverage sequential-thinking** - For complex reasoning tasks
5. **Use context7** - For up-to-date library documentation

### Don't Do This ❌

1. **Don't load all tool schemas** - Use dynamic discovery
2. **Don't hardcode secrets** - Use agenix + passwordCommand
3. **Don't skip testing** - Always test servers before deploying
4. **Don't load large datasets into context** - Process locally when possible

## Real-World Examples

### Example 1: Add Database Access

```nix
# home/ai/mcp.nix
settings.servers.postgres = {
  command = "${pkgs.nodejs}/bin/npx";
  args = [
    "-y"
    "@modelcontextprotocol/server-postgres"
    "postgresql://localhost/mydb"
  ];
};
```

```bash
# Rebuild and test
home-manager switch
mcp-cli postgres
mcp-cli postgres/query '{"sql": "SELECT * FROM users LIMIT 5"}'
```

### Example 2: Add Issue Tracker

```nix
# home/ai/mcp.nix
settings.servers.linear = {
  command = "${pkgs.python3}/bin/uvx";
  args = ["mcp-server-linear"];
  env = {
    LINEAR_API_KEY = "\${LINEAR_API_KEY}";
  };
  passwordCommand = {
    LINEAR_API_KEY = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "cat /run/user/$(id -u)/agenix/linear-key"
    ];
  };
};
```

### Example 3: Add Cloud Provider

```nix
# home/ai/mcp.nix
settings.servers.aws = {
  command = "${pkgs.python3}/bin/uvx";
  args = ["mcp-server-aws"];
  # Uses ~/.aws/credentials automatically
};
```

## Next Steps

### Immediate (5 minutes)

1. ✅ Read this summary
2. ✅ Test mcp-cli: `mcp-cli` and `mcp-cli grep "file"`
3. ✅ Review axios system prompt: `cat ~/.config/ai/prompts/axios.md`

### Short-term (30 minutes)

1. Browse `mcp-examples.nix` for servers you want
2. Add 2-3 new servers to `home/ai/mcp.nix`
3. Test with `mcp-cli <server-name>`
4. Use in Claude Code session

### Long-term (As needed)

1. Monitor for Claude Code CLI beta feature support
2. Add custom tool use examples to system prompt
3. Build API wrapper for beta features if needed
4. Contribute new MCP servers back to axiOS

## Resources

### Internal Documentation
- `docs/advanced-tool-use.md` - Beta feature details
- `docs/adding-mcp-servers.md` - Server configuration guide
- `home/ai/mcp-examples.nix` - 50+ ready-to-use examples
- `home/ai/mcp.nix` - Current MCP configuration

### External Resources
- **Anthropic Blog**: https://www.anthropic.com/engineering/advanced-tool-use
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **Claude Code Docs**: https://docs.claude.com/en/docs/claude-code/mcp
- **Awesome MCP Servers**: https://github.com/punkpeye/awesome-mcp-servers
- **Official MCP Servers**: https://github.com/modelcontextprotocol/servers

## Questions?

Check the documentation first:
- "How do I add a server?" → `adding-mcp-servers.md`
- "What servers are available?" → `mcp-examples.nix`
- "What are the beta features?" → `advanced-tool-use.md`
- "How does this work?" → This file

## Contributing

Found a useful MCP server configuration? Add it to `mcp-examples.nix` and submit a PR!
