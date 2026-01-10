# MCP Servers via mcp-cli

You have access to MCP (Model Context Protocol) servers via the `mcp-cli` CLI.
MCP provides tools for interacting with external systems like GitHub, databases, and APIs.

## Available Commands

```bash
mcp-cli                              # List all servers and tool names
mcp-cli <server>                     # Show server tools and parameters
mcp-cli <server>/<tool>              # Get tool JSON schema and descriptions
mcp-cli <server>/<tool> '<json>'     # Call tool with JSON arguments
mcp-cli grep "<pattern>"             # Search tools by name (glob pattern)
```

**Add `-d` to include tool descriptions** (e.g., `mcp-cli <server> -d`)

## Workflow

1. **Discover**: Run `mcp-cli` to see available servers and tools or `mcp-cli grep "<pattern>"` to search for tools by name (glob pattern)
2. **Inspect**: Run `mcp-cli <server> -d` or `mcp-cli <server>/<tool>` to get the full JSON input schema if required context is missing. If there are more than 5 mcp servers defined don't use `-d` as it will print all tool descriptions and might exceed the context window.
3. **Execute**: Run `mcp-cli <server>/<tool> '<json>'` with correct arguments

## Rules

1. **Always check schema first**: Run `mcp-cli <server> -d` or `mcp-cli <server>/<tool>` before calling any tool
2. **Quote JSON arguments**: Wrap JSON in single quotes to prevent shell interpretation

## Examples

```bash
# Discover available tools
mcp-cli

# Search for file-related tools
mcp-cli grep "file"

# Get filesystem server tool list
mcp-cli filesystem -d

# Get specific tool schema
mcp-cli filesystem/read_file

# Execute tool
mcp-cli filesystem/read_file '{"path": "/tmp/test.txt"}'

# GitHub example
mcp-cli github/search_repositories '{"query": "axios", "language": "nix"}'
```

## Benefits

- **Reduced Context**: Using mcp-cli reduces token usage by ~99% compared to loading all tool schemas upfront
- **Dynamic Discovery**: Only load schemas for tools you actually need
- **Many Servers**: Support 20+ MCP servers without context window limits
