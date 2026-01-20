# Improve System Stability - Tasks

## Summary

Address system instability caused by Ghostty singleton zombies and consolidate the existing Ollama memory management fix.

## Tasks

### Phase 1: Ghostty Singleton Zombie Fix

- [x] Add pre-startup cleanup command in `home/desktop/niri.nix` to kill stale ghostty processes
- [ ] Test logout/login cycle to verify ghostty starts correctly
- [ ] Test system freeze recovery (optional - difficult to reproduce)
- [ ] Update `openspec/specs/desktop/spec.md` with Ghostty lifecycle documentation

### Phase 2: Consolidate Ollama Memory Management

- [x] ~~Create OpenSpec delta directory structure~~ (completed in `ollama-memory-management`)
- [x] ~~Stage updated AI spec with new memory management documentation~~ (completed)
- [x] ~~Implement `services.ai.local.keepAlive` option~~ (completed)
- [x] ~~Set `OLLAMA_KEEP_ALIVE` environment variable~~ (completed)
- [x] ~~Format code with `nix fmt .`~~ (completed)
- [x] ~~Test configuration builds successfully~~ (completed)
- [ ] Merge ollama-memory-management specs into main `openspec/specs/ai/spec.md`
- [ ] Move `ollama-memory-management` change to archive

### Phase 3: Validation & Documentation

- [x] Format code with `nix fmt .`
- [x] Run `nix flake check --no-build` to validate configuration
- [ ] Document known stability issues and workarounds in spec
- [ ] Update desktop spec with session lifecycle notes

## Implementation Details

### Ghostty Pre-startup Cleanup

**File**: `home/desktop/niri.nix`

**Implementation** (COMPLETE):

```nix
spawn-at-startup = [
  # ... existing commands ...

  # Kill any zombie ghostty singleton processes from previous sessions
  # This prevents stale processes (from crashes/freezes) blocking new instances
  # pkill returns non-zero if no match, but Niri ignores spawn exit codes
  {
    command = [
      "${pkgs.procps}/bin/pkill"
      "-9"
      "-f"
      "ghostty.*--gtk-single-instance"
    ];
  }
  {
    command = [
      "$ghostty"
      "--gtk-single-instance=true"
      "--initial-window=false"
      "--quit-after-last-window-closed=false"
    ];
  }
];
```

### Root Cause Summary

| Component | Issue | Root Cause | Fix |
|-----------|-------|------------|-----|
| Ghostty | Fails to start after logout | Zombie singleton process | Pre-startup pkill cleanup (DONE) |
| Ollama | GPU memory exhaustion | Models stay loaded indefinitely | OLLAMA_KEEP_ALIVE=5m (done) |
| DMS/Quickshell | SIGSEGV crashes | Unknown (upstream?) | Out of scope |
| kded6 | SIGABRT at startup | Unknown (KDE upstream?) | Out of scope |
| AMDGPU | Queue evictions | High VRAM usage | Monitoring (future work) |

## Acceptance Criteria

1. [x] Ghostty cleanup command added to niri.nix
2. [ ] Ghostty starts reliably after logout/login cycle (needs manual test)
3. [ ] Ollama memory management change is archived
4. [ ] Desktop spec documents known lifecycle behavior
5. [x] Configuration passes `nix flake check`
