# Proposal: AI CLI Tools Additions Tracker

## Summary

Blanket proposal for tracking the addition of new AI CLI tools and coding agents to axios's AI module. This is a living document that tracks individual tool integrations without requiring separate proposals for each.

## Motivation

Adding AI CLI tools to `modules/ai/default.nix` is a recurring task that doesn't warrant individual proposals. Each tool addition is typically:
- Adding a package to `environment.systemPackages`
- Optionally adding home-manager configuration
- Updating the AI spec documentation

This proposal serves as a single tracking location for all such additions.

## Scope

This proposal covers **adding existing AI CLI tools** to axios configuration. It does NOT cover:
- Building new custom tools (use separate proposals)
- MCP server additions (use `mcp-server-additions` proposal)
- Major AI infrastructure changes (Ollama, Open WebUI, etc.)
- Tools requiring significant integration work

## Tool Addition Checklist

When adding a new AI CLI tool:

1. [ ] Add package to `modules/ai/default.nix` (inside `mkIf` block)
2. [ ] Add home-manager config if needed (`home/ai/`)
3. [ ] Update `openspec/specs/ai/spec.md` CLI Coding Agents section
4. [ ] Test tool runs correctly after rebuild
5. [ ] Document any required setup (API keys, auth, etc.)

## Tracked Additions

| Tool | Status | Date | Notes |
|------|--------|------|-------|
| goose-cli | Implemented | 2025-01-24 | Block's AI agent via llm-agents.nix, MCP configured |

## Tool Categories

### CLI Coding Agents
General-purpose AI assistants for coding tasks:
- claude-code, gemini-cli-bin, antigravity (existing)
- goose-cli (pending)

### Workflow Tools
Specialized tools for specific AI workflows:
- whisper-cpp, claude-monitor (existing)

### Local Inference Clients
CLI tools for interacting with local LLMs:
- ollama CLI (existing, bundled with service)

## References

- AI module: `modules/ai/default.nix`
- Home AI config: `home/ai/`
- AI spec: `openspec/specs/ai/spec.md`
