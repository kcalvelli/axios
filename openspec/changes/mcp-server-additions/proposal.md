# Proposal: MCP Server Additions Tracker

## Summary

Blanket proposal for tracking the addition of new MCP servers to axios's AI configuration. This is a living document that tracks individual MCP server integrations without requiring separate proposals for each.

## Motivation

Adding MCP servers to `home/ai/mcp.nix` is a recurring task that doesn't warrant individual proposals. Each server addition is typically:
- Adding a server configuration block to `claude-code-servers`
- Optionally adding flake input or package dependency
- Updating documentation if needed

This proposal serves as a single tracking location for all such additions.

## Scope

This proposal covers **adding existing MCP servers** to axios configuration. It does NOT cover:
- Building new MCP servers (use separate proposals like `mcp-calendar`, `mcp-screenshot`)
- Major MCP infrastructure changes
- Changes to the mcp-servers-nix library

## Server Addition Checklist

When adding a new MCP server:

1. [ ] Add flake input if needed (external package)
2. [ ] Add server configuration to `home/ai/mcp.nix`
3. [ ] Add package to `home.packages` if needed
4. [ ] Update requirements comment block if setup is needed
5. [ ] Update `openspec/specs/ai/spec.md` if appropriate
6. [ ] Test with `mcp-cli` to verify server loads

## Tracked Additions

| Server | Status | Date | Notes |
|--------|--------|------|-------|
| axios-ai-mail | Complete | 2025-01-24 | Email management via axios-ai-mail MCP mode |

## References

- MCP configuration: `home/ai/mcp.nix`
- AI spec: `openspec/specs/ai/spec.md`
- mcp-servers-nix: https://github.com/nix-community/mcp-servers-nix
