# Delta: mcp-cli passwordCommand Support

## Problem

mcp-cli (v0.3.0) ignores the `passwordCommand` configuration field. Servers that
rely on `passwordCommand` for secrets (e.g., GitHub MCP using `gh auth token`)
fail when accessed via mcp-cli or gemini-cli. Claude Code handles
`passwordCommand` natively, but mcp-cli does not.

## Approach

Nix patch file applied during `patchPhase`. No source hash changes needed since
patches are applied to the already-fetched source.

## Tasks

- [x] Create `pkgs/mcp-cli/passwordCommand-support.patch`
  - `config.ts`: Add `spawnSync` import, `passwordCommand` to `StdioServerConfig`,
    and `resolvePasswordCommands()` function
  - `client.ts`: Import `resolvePasswordCommands`, call it in `createStdioTransport()`
    to merge resolved secrets into `mergedEnv`
- [x] Update `pkgs/mcp-cli/default.nix` to apply the patch
- [x] Create this OpenSpec delta (`openspec/changes/mcp-cli-password-command/tasks.md`)
- [ ] Build verification: `nix build .#mcp-cli`
- [ ] Functional verification: `mcp-cli info github` resolves token

## Spec Impact

- `openspec/specs/ai/spec.md` — Note that mcp-cli now supports `passwordCommand`
  for secret resolution, matching mcp-gateway behavior.

## Files Changed

| File | Change |
|------|--------|
| `pkgs/mcp-cli/passwordCommand-support.patch` | New — patch adding passwordCommand support |
| `pkgs/mcp-cli/default.nix` | Added `patches` attribute |
| `openspec/changes/mcp-cli-password-command/tasks.md` | New — this delta |
