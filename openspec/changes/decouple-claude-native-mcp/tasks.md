# Tasks: Decouple Claude Code from Native MCP Servers

## mcp-gateway changes

- [x] Change `generateClaudeConfig` default from `true` to `false`
- [x] Add `generateClaudeSkill` option (default: `true`)
- [x] Add `mcp-cli` to module's `home.packages`
- [x] Create `commands/mcp-cli.md` skill file
- [x] Update module header comments

## axios changes

- [x] Remove `mcp-cli` from `environment.systemPackages` in `modules/ai/default.nix`
- [x] Remove mcp-cli prompt deployment from `home/ai/mcp.nix`
- [x] Delete `home/ai/prompts/mcp-cli-system-prompt.md`
- [x] Remove "MCP Tools via mcp-cli" section from `home/ai/prompts/axios-system-prompt.md`
- [x] Create OpenSpec delta with proposal, tasks, and spec update

## Finalization

- [ ] Format both repos with `nix fmt .`
- [ ] Commit and push mcp-gateway
- [ ] Commit and push axios
- [ ] Verify: `~/.mcp.json` not generated, skill installed, mcp-cli works
