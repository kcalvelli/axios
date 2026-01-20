# Improve System Stability

## Summary

This proposal addresses frequent causes of system instability identified through log analysis on the primary development machine (edge). The focus is on four components: Ghostty, DMS/Quickshell, Niri session management, and Ollama GPU memory management.

## Problem Statement

System logs from the past 7 days reveal multiple stability issues:

1. **Ghostty Singleton Zombie Issue** - Terminal fails to start after logout/login
2. **DMS/Quickshell SIGSEGV Crashes** - Shell crashes during session initialization
3. **AMDGPU Queue Evictions** - Ongoing GPU memory pressure despite recent fixes
4. **Ollama Memory Exhaustion** - Already addressed in `ollama-memory-management` change

## Root Cause Analysis

### 1. Ghostty Singleton Zombie (User-Provided RCA)

**Root Cause Identified:**

The problem is clear:

1. Stale Ghostty process (e.g., PID 4157) from before logout is still running but is now a "zombie" - it has no valid Wayland connection (empty WAYLAND environment)
2. The new service startup fails with `signal=HUP` and `Result: protocol` because:
   - Ghostty runs with `--gtk-single-instance=true` (singleton mode)
   - The old process is blocking new instances from starting
   - The old process can't respond properly because it lost its Wayland connection when user logged out
3. The freeze before logout likely corrupted the process state, preventing clean shutdown

**Current Configuration** (from `home/desktop/niri.nix`):
```nix
spawn-at-startup = [
  {
    command = [
      "$ghostty"
      "--gtk-single-instance=true"   # reuse one resident process
      "--initial-window=false"       # start with no window
      "--quit-after-last-window-closed=false" # keep the process alive
    ];
  }
];
```

**Issue**: When niri exits (logout, crash, or system freeze), there's no guaranteed cleanup of the ghostty singleton process. On re-login:
- Niri spawns a new ghostty with `--gtk-single-instance=true`
- The zombie process blocks the new instance
- New process receives SIGHUP and fails

### 2. DMS/Quickshell SIGSEGV Crashes

**Evidence from logs:**
```
Jan 20 05:41:45 - Process .quickshell-wra of user 991 terminated abnormally with signal 11/SEGV
Jan 20 05:41:37 - Process .quickshell-wra of user 991 terminated abnormally with signal 11/SEGV
```

User 991 is the greeter (likely `greetd`), indicating crashes occur during:
- Initial greeter session setup
- Login screen display before user authentication

**Current Mitigation**: DMS systemd integration is disabled to avoid race conditions (per `openspec/specs/desktop/spec.md`), but spawn-at-startup doesn't provide crash recovery.

### 3. AMDGPU Queue Evictions (Ongoing)

**Evidence from logs (today):**
```
amdgpu: Runlist is getting oversubscribed due to too many queues. Expect reduced ROCm performance.
amdgpu: Freeing queue vital buffer 0x..., queue evicted
```

Multiple evictions occurring even after ollama KEEP_ALIVE fix. Root causes:
- Multiple AI inference sessions running concurrently
- Large context windows (32K tokens) consuming significant VRAM
- Long-running API sessions keeping models loaded

### 4. Ollama Memory Management (Complete)

Already addressed in `ollama-memory-management` change:
- Added `services.ai.local.keepAlive` option (default: 5m)
- Sets `OLLAMA_KEEP_ALIVE` environment variable
- **Status**: 7/8 tasks complete, pending archive

## Proposed Solutions

### Solution 1: Ghostty Lifecycle Management

**Option A (Recommended): Pre-startup Cleanup Script**
Add a cleanup command before ghostty spawns to kill any stale instances:

```nix
spawn-at-startup = [
  # Kill any zombie ghostty processes before starting fresh
  {
    command = [ "pkill" "-9" "-f" "ghostty.*--gtk-single-instance" ];
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

**Option B: Systemd User Service**
Convert ghostty to a systemd user service with proper `ExecStop` and restart policies. More robust but more complex.

**Option C: Disable Singleton Mode**
Remove `--gtk-single-instance=true`. Simpler but loses the performance benefits of resident process.

### Solution 2: DMS Crash Recovery

Add restart wrapper or health monitoring for quickshell/DMS. Options:
- Niri IPC health check script
- Systemd path-based restart trigger
- Simple watchdog in spawn-at-startup

### Solution 3: GPU Memory Monitoring

Add optional GPU memory watchdog that:
- Monitors VRAM usage via `amd_smi` or `/sys/class/drm`
- Warns when approaching limits
- Can trigger ollama model unloading preemptively

## Scope

This proposal focuses on:
1. **Ghostty zombie fix** - Immediate stability improvement
2. **Consolidating ollama fix** - Mark existing change as complete
3. **Documentation** - Add stability troubleshooting guide

Out of scope (future work):
- DMS crash recovery (depends on upstream quickshell stability)
- GPU memory watchdog (complex, needs dedicated proposal)
- kded6 crashes (KDE upstream issue)

## References

- User RCA for Ghostty singleton issue (provided in request)
- Journal logs: `/home/keith/.claude/projects/.../tool-results/mcp-journal-logs_query-*.txt`
- Existing change: `openspec/changes/ollama-memory-management/`
- Desktop spec: `openspec/specs/desktop/spec.md`
