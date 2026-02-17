## Context

When NixOS enables PipeWire (via `services.pipewire.enable`), systemd user sockets (`pipewire.socket`, `pipewire-pulse.socket`) are installed for all non-root users. When greetd spawns the greeter session, the greeter user (uid 991, HOME=/var/empty) gets a PipeWire instance via socket-activation. This instance opens ALSA devices (including HDMI outputs) and holds them until the greeter's user session fully terminates — which happens ~10 seconds after login. The real user's WirePlumber hits "Device or resource busy" during this overlap and doesn't retry, leaving HDMI audio broken.

The desktop module already configures both greetd (via `programs.dank-material-shell.greeter`) and PipeWire (implicitly, as a dependency of the desktop stack). This makes it the correct place to address the interaction.

## Goals / Non-Goals

**Goals:**
- Prevent PipeWire from socket-activating for the greeter user
- Eliminate ALSA device contention at login time
- Eliminate spurious WirePlumber errors in greeter's journal (`/var/empty/.local/state/wireplumber`)

**Non-Goals:**
- Fixing WirePlumber's lack of retry on busy devices (upstream concern)
- Changing user lingering behavior for the primary user
- Adding audio support to the greeter (it doesn't need it)

## Decisions

### Decision 1: Use `ConditionUser` on PipeWire sockets

**Choice**: Add `ConditionUser = [ "!root" "!greeter" ]` to `pipewire.socket` and `pipewire-pulse.socket` via `systemd.user.sockets.*.unitConfig`.

**Rationale**: This is the most surgical fix — it prevents PipeWire from ever starting for the greeter user, eliminating the problem at the source. No PipeWire process means no device contention and no permission errors.

**Alternatives considered**:
- **WirePlumber ALSA monitor rule**: Add a rule to disable ALSA monitoring when `$HOME=/var/empty`. More fragile, still spawns PipeWire unnecessarily, and relies on environment variable detection.
- **Delay login session start**: Add a sleep or dependency to wait for greeter cleanup. Adds latency to every login and is a workaround, not a fix.
- **WirePlumber retry logic**: Would require upstream patches to WirePlumber. Not feasible for a downstream fix.

### Decision 2: Place in desktop module, not a separate module

**Choice**: Add the socket overrides directly in `modules/desktop/default.nix` within the existing `config = lib.mkIf config.desktop.enable` block.

**Rationale**: The desktop module already owns both greetd configuration and the desktop audio stack. The fix only makes sense when both are active. Creating a separate module for two lines of configuration would be over-engineering.

## Risks / Trade-offs

- **[Risk] Greeter user name assumption**: The `ConditionUser` uses the literal string `"greeter"`. If a downstream user configures a different greeter username, PipeWire would still activate for it. → **Mitigation**: The greeter username is controlled by greetd's NixOS module and defaults to `greeter`. DMS uses this default. This is the standard across NixOS greeter configurations.

- **[Risk] Future greeter needing audio**: If a greeter ever needs to play login sounds or accessibility audio. → **Mitigation**: This is extremely unlikely for a tiling WM greeter. If needed, the `ConditionUser` can be removed or the greeter user excluded from the exclusion list.
