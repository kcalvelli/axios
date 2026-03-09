# Advanced Tool Use in axiOS

This document describes how to leverage advanced tool use capabilities with Claude in axiOS.

## Overview

Anthropic released three beta features for advanced tool use:

1. **Tool Search Tool** - On-demand tool discovery (85% token reduction)
2. **Programmatic Tool Calling** - Python code orchestration in sandbox
3. **Tool Use Examples** - Concrete usage patterns for complex parameters

**Status**: These features are currently available via the Anthropic API with beta header `betas=["advanced-tool-use-2025-11-20"]` and model `claude-sonnet-4-5-20250929`.

## Feature 1: Tool Search Tool

### What It Does
Claude searches for tools on-demand rather than loading all definitions upfront.

**Benefits**:
- Context reduction: ~77K → ~8.7K tokens (85% reduction)
- Improved accuracy on MCP evaluations (Opus 4: 49%→74%, Opus 4.5: 79.5%→88.1%)
- Better for 10+ tools with >10K tokens of definitions

### How axiOS Already Implements This

**axiOS uses mcp-gateway for dynamic tool discovery!** The gateway provides on-demand tool access via REST API and `mcp-gw` CLI, achieving the same benefits:

```bash
# Dynamic discovery workflow (already available in axiOS)
curl -s http://localhost:8085/api/tools | jq          # List all tools
curl -s -X POST http://localhost:8085/api/tools/github/search_repositories \
  -H "Content-Type: application/json" \
  -d '{"query": "axios"}'                              # Execute a tool
```

**Token savings**: ~47,000 → ~400 tokens (99% reduction!)

### Enabling in API Calls

If you're using the Anthropic API directly (not Claude Code CLI), configure tools with `defer_loading`:

```python
from anthropic import Anthropic

client = Anthropic()

tools = [
    {
        "name": "search_files",
        "description": "Search for files matching a pattern",
        "defer_loading": True,  # ← Enable on-demand loading
        "input_schema": {
            "type": "object",
            "properties": {
                "pattern": {"type": "string"},
                "path": {"type": "string"}
            }
        }
    }
]

response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    extra_headers={"anthropic-beta": "advanced-tool-use-2025-11-20"},
    messages=[{"role": "user", "content": "Find all Nix files"}],
    tools=tools
)
```

## Feature 2: Programmatic Tool Calling

### What It Does
Claude writes Python code to orchestrate tools in a sandboxed environment, processing results without loading them into context.

**Benefits**:
- Token savings: 43,588 → 27,297 tokens (37% reduction)
- No inference passes for intermediate steps
- Improved accuracy on knowledge retrieval (25.6% → 28.5%)
- Parallel tool execution
- Local data processing

**Best for**: Multi-step workflows, large datasets, batch operations

### Example Use Cases

```python
# Scenario: Analyze all Nix files for security issues
# Traditional: Load each file into context → run analysis
# Programmatic: Claude writes code to iterate files, extract patterns, return summary

# Scenario: Compare multiple API responses
# Traditional: Load all responses → analyze → compare
# Programmatic: Claude processes responses in code, returns diff only
```

### Enabling in API Calls

Tools opt-in with `allowed_callers`:

```python
tools = [
    {
        "name": "read_file",
        "description": "Read file contents",
        "allowed_callers": ["code_execution_20250825"],  # ← Enable programmatic access
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string"}
            },
            "required": ["path"]
        }
    }
]

response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    extra_headers={"anthropic-beta": "advanced-tool-use-2025-11-20"},
    messages=[{"role": "user", "content": "Summarize all error logs"}],
    tools=tools
)
```

## Feature 3: Tool Use Examples

### What It Does
Provides concrete usage patterns showing parameter conventions, nested structures, and optional field combinations.

**Benefits**:
- Accuracy improvement: 72% → 90% on complex parameters
- Clarifies ambiguities in nested structures
- Shows minimal, partial, and full specification examples

**Best for**: Complex nested structures, domain-specific conventions

### Example Configuration

```python
tools = [
    {
        "name": "deploy_application",
        "description": "Deploy application with configuration",
        "input_schema": {
            "type": "object",
            "properties": {
                "config": {
                    "type": "object",
                    "properties": {
                        "replicas": {"type": "integer"},
                        "resources": {
                            "type": "object",
                            "properties": {
                                "cpu": {"type": "string"},
                                "memory": {"type": "string"}
                            }
                        }
                    }
                }
            }
        },
        "examples": [  # ← Add concrete examples
            {
                "description": "Minimal deployment",
                "arguments": {
                    "config": {"replicas": 1}
                }
            },
            {
                "description": "Production deployment with resources",
                "arguments": {
                    "config": {
                        "replicas": 3,
                        "resources": {
                            "cpu": "2000m",
                            "memory": "4Gi"
                        }
                    }
                }
            }
        ]
    }
]
```

## Implementing in axiOS

### Option 1: API Wrapper (Recommended for Now)

Create a Python wrapper for advanced tool use with MCP servers:

```python
# ~/bin/claude-advanced.py
import anthropic
import subprocess
import json

def get_mcp_tools():
    """Extract tools from MCP servers with defer_loading"""
    import requests
    resp = requests.get('http://localhost:8085/api/tools')
    # Parse and format as tools with defer_loading=True
    return resp.json()

def call_mcp_tool(server, tool, args):
    """Execute MCP tool via mcp-gateway API"""
    import requests
    resp = requests.post(f'http://localhost:8085/api/tools/{server}/{tool}', json=args)
    return resp.json()

client = anthropic.Anthropic()
tools = get_mcp_tools()

response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=4096,
    extra_headers={"anthropic-beta": "advanced-tool-use-2025-11-20"},
    messages=[{"role": "user", "content": "Your task here"}],
    tools=tools
)
```

### Option 2: Wait for Claude Code CLI Support

The Claude Code CLI doesn't yet support the beta features. Monitor for updates:
- Check `claude --version` for feature announcements
- Follow Anthropic's changelog: https://docs.anthropic.com/en/release-notes

### Option 3: Enhance System Prompt

axiOS already auto-injects `~/.config/ai/prompts/axios.md`. Add guidance for dynamic tool discovery:

```nix
# In your NixOS config
services.ai.systemPrompt.extraInstructions = ''
  ## Tool Discovery Strategy

  For tasks requiring multiple tools:
  1. Use mcp-gateway API to find relevant tools dynamically
  2. Only inspect full schemas when necessary
  3. Execute tools and process results in code when possible
'';
```

## Current Best Practices in axiOS

### 1. Use mcp-gateway for Dynamic Discovery

Already configured! The axios system prompt teaches Claude to use mcp-gateway's on-demand tool discovery:
```bash
# List all tools via gateway API
curl -s http://localhost:8085/api/tools | jq

# Execute a tool
curl -s -X POST http://localhost:8085/api/tools/filesystem/read_file \
  -H "Content-Type: application/json" \
  -d '{"path": "/tmp/test.txt"}'
```

### 2. Leverage Sequential Thinking

The `sequential-thinking` MCP server is already enabled and accessible via mcp-gateway.

### 3. Use Context7 for Documentation

Instead of loading docs into context, query dynamically via the gateway API.

## Future Enhancements

When Claude Code CLI supports advanced tool use:

1. **Add defer_loading to MCP config**:
   ```nix
   # home/ai/mcp.nix (future)
   settings.servers.github = {
     command = "...";
     defer_loading = true;  # Enable on-demand loading
   };
   ```

2. **Add allowed_callers for programmatic access**:
   ```nix
   settings.servers.filesystem = {
     command = "...";
     allowed_callers = ["code_execution_20250825"];
   };
   ```

3. **Provide tool examples**:
   ```nix
   settings.servers.github.examples = [
     {
       description = "Search repositories by language";
       arguments = {
         query = "language:nix stars:>100";
       };
     }
   ];
   ```

## References

- **Anthropic Blog**: https://www.anthropic.com/engineering/advanced-tool-use
- **MCP Documentation**: https://docs.claude.com/en/docs/claude-code/mcp
- **axiOS MCP Config**: `home/ai/mcp.nix`
- **axiOS System Prompt**: `~/.config/ai/prompts/axios.md`
