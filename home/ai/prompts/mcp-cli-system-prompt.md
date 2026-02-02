# MCP Servers via mcp-cli

You have access to MCP (Model Context Protocol) servers via the `mcp-cli` CLI.
MCP provides tools for interacting with external systems like GitHub, databases, and APIs.

## Available Commands

```bash
mcp-cli                                   # List all servers and tool names
mcp-cli info <server>                     # Show server tools and parameters
mcp-cli info <server>/<tool>              # Get tool JSON schema and descriptions
mcp-cli call <server>/<tool> '<json>'     # Call tool with JSON arguments
mcp-cli grep "<pattern>"                  # Search tools by name (glob pattern)
```

**Add `-d` to include tool descriptions** (e.g., `mcp-cli info <server> -d`)

## Workflow

1. **Discover**: Run `mcp-cli` to see available servers and tools or `mcp-cli grep "<pattern>"` to search for tools by name (glob pattern)
2. **Inspect**: Run `mcp-cli info <server> -d` or `mcp-cli info <server>/<tool>` to get the full JSON input schema if required context is missing. If there are more than 5 mcp servers defined don't use `-d` as it will print all tool descriptions and might exceed the context window.
3. **Execute**: Run `mcp-cli call <server>/<tool> '<json>'` with correct arguments

## Rules

1. **Always check schema first**: Run `mcp-cli info <server> -d` or `mcp-cli info <server>/<tool>` before calling any tool
2. **Quote JSON arguments**: Wrap JSON in single quotes to prevent shell interpretation
3. **Always use explicit subcommands**: Use `info` to inspect and `call` to execute — never omit the subcommand

## Examples

```bash
# Discover available tools
mcp-cli

# Search for file-related tools
mcp-cli grep "file"

# Get filesystem server tool list
mcp-cli info filesystem -d

# Get specific tool schema
mcp-cli info filesystem/read_file

# Execute tool
mcp-cli call filesystem/read_file '{"path": "/tmp/test.txt"}'

# GitHub example
mcp-cli call github/search_repositories '{"query": "axios", "language": "nix"}'
```

## Benefits

- **Reduced Context**: Using mcp-cli reduces token usage by ~99% compared to loading all tool schemas upfront
- **Dynamic Discovery**: Only load schemas for tools you actually need
- **Many Servers**: Support 20+ MCP servers without context window limits
