# Operational Runbook

## Development Environment Setup

### Prerequisites
**System Requirements**:
- OS: NixOS (for full system testing) or Linux/macOS with Nix (for module development)
- Nix: Version 2.4+ with flakes enabled
- Git: Version 2.0+

**Installation**:
```bash
# Install Nix with flakes (if not on NixOS)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Installation Steps

1. **Clone Repository**:
```bash
git clone https://github.com/kcalvelli/axios.git
cd axios
```

2. **No Dependency Installation Needed**:
   - Nix handles all dependencies automatically via flake.lock
   - First run will download and build dependencies

3. **Configuration Setup**: N/A (library project - no runtime configuration)

4. **Verify Installation**:
```bash
# Validate flake structure
nix flake check

# Show available outputs
nix flake show
```

## Build & Run

### Development Mode

**Validate Flake**:
```bash
nix flake check
```

**Format Code**:
```bash
nix fmt .
# OR: ./scripts/fmt.sh
```

**Test Init Script**:
```bash
nix run .#init
```

**Enter DevShell**:
```bash
# Rust development
nix develop .#rust

# Zig development
nix develop .#zig

# QML development
nix develop .#qml

# .NET development
nix develop .#dotnet

# Default devshell
nix develop
```

### Production Mode
**N/A** - This is a library project. Users build their own systems:

```bash
# In user's downstream configuration
sudo nixos-rebuild switch --flake .#<hostname>
```

### Testing Modules
**Dry-run Build** (example configuration):
```bash
# Build minimal example without activating
nix build .#nixosConfigurations.minimal-example.config.system.build.toplevel --dry-run

# Build multi-host example
nix build .#nixosConfigurations.server-example.config.system.build.toplevel --dry-run
```

## Testing

### Unit Tests
**N/A** - Nix evaluation is deterministic, no traditional unit tests

### Integration Tests
**Flake Check** (runs in CI):
```bash
nix flake check --all-systems
```
- Validates flake structure
- Checks all outputs are evaluable
- Verifies no evaluation errors

### Code Formatting Tests
```bash
# Check formatting
nix fmt -- --fail-on-change .
# OR: ./scripts/fmt.sh --check

# Fix formatting
nix fmt .
# OR: ./scripts/fmt.sh
```
- Location: All .nix files
- Framework: nixfmt-rfc-style via treefmt-nix
- Helper script: scripts/fmt.sh (AI-safe wrapper)

### Module Evaluation Tests
```bash
# Test specific example configuration
nix eval .#nixosConfigurations.minimal-example.config.system.build.toplevel

# Test that all modules can be imported
nix eval .#nixosModules --apply builtins.attrNames
```

### Test Coverage
**N/A** - Nix evaluation either succeeds or fails deterministically

### Manual Testing
**Test in VM**:
```bash
# Build and run NixOS VM (from downstream config using axios)
nixos-rebuild build-vm --flake .#<hostname>
./result/bin/run-*-vm
```

## Module Development

### Creating a New Module

1. **Create Module Directory**:
```bash
mkdir -p modules/my-module
touch modules/my-module/default.nix
```

2. **Module Template**:
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.myModule;
in
{
  options.myModule = {
    enable = lib.mkEnableOption "My Module Description";
  };

  config = lib.mkIf cfg.enable {
    # Configuration here
    environment.systemPackages = with pkgs; [
      # Packages inline, inside mkIf block
    ];
  };
}
```

3. **Register Module**:
Edit `modules/default.nix`:
```nix
flake.nixosModules = {
  # ... existing modules ...
  myModule = ./my-module;
};
```

4. **Test Module**:
```bash
# Validate flake
nix flake check

# Test in example configuration
# (add to examples/minimal-flake/flake.nix)
```

### Creating a Home Manager Module

1. **Create Module Directory**:
```bash
mkdir -p home/my-module
touch home/my-module/default.nix
```

2. **Home Module Template**:
```nix
{ config, lib, pkgs, osConfig, ... }:
let
  cfg = config.myModule;
in
{
  options.myModule = {
    enable = lib.mkEnableOption "My Home Module";
  };

  config = lib.mkIf cfg.enable {
    # Home configuration
    home.packages = with pkgs; [
      # Packages here
    ];
  };
}
```

3. **Register Module**:
Edit `home/default.nix`:
```nix
flake.homeModules = {
  # ... existing modules ...
  myModule = ./my-module;
};
```

### Adding a Service with Caddy Reverse Proxy

**IMPORTANT**: Use the route registry pattern (ADR-007) for all services requiring reverse proxy.

1. **Create Service Module** (following ADR-001):
```bash
mkdir -p modules/services/my-service
touch modules/services/my-service/default.nix
```

2. **Service Module with Route Registration**:
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.selfHosted.myService;
  tailscaleDomain = config.networking.tailscale.domain;
in
{
  options.selfHosted.myService = {
    enable = lib.mkEnableOption "My Service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Service port";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable the service
    services.myService = {
      enable = true;
      port = cfg.port;
    };

    # Register Caddy route (route registry pattern - ADR-007)
    selfHosted.caddy.routes.myService = {
      domain = "${config.networking.hostName}.${tailscaleDomain}";

      # Path-specific route (priority 100 = before catch-all)
      path = "/myapp/*";  # Or null for catch-all
      priority = 100;     # 100 = path-specific, 1000 = catch-all

      target = "http://127.0.0.1:${toString cfg.port}";

      # Optional: Additional Caddy configuration
      extraConfig = ''
        # Custom Caddy directives here
        timeout 30s
      '';
    };
  };
}
```

3. **Register Module**:
Edit `modules/services/default.nix`:
```nix
flake.nixosModules = {
  # ... existing modules ...
  myService = ./my-service;
};
```

4. **Example: Catch-All Service** (like Immich):
```nix
selfHosted.caddy.routes.myService = {
  domain = "${config.networking.hostName}.${tailscaleDomain}";
  path = null;        # Catch-all - matches all paths
  priority = 1000;    # Evaluated AFTER path-specific routes
  target = "http://127.0.0.1:${toString cfg.port}";
};
```

5. **Example: Path-Specific Service** (like Ollama):
```nix
selfHosted.caddy.routes.myService = {
  domain = "${config.networking.hostName}.${tailscaleDomain}";
  path = "/api/*";    # Path-specific
  priority = 100;     # Evaluated BEFORE catch-all routes
  target = "http://127.0.0.1:${toString cfg.port}";
};
```

**Key Points**:
- **DO NOT** use `selfHosted.caddy.extraConfig` for routes (deprecated pattern)
- **DO NOT** hardcode path exclusions or reference other services' paths
- Priority 100 = path-specific routes (evaluated first)
- Priority 1000 = catch-all routes (evaluated last)
- The Caddy module automatically handles route ordering by domain and priority

### Adding a DevShell

1. **Create DevShell File**:
```bash
touch devshells/my-shell.nix
```

2. **DevShell Template**:
```nix
{ inputs, pkgs, ... }:
{
  name = "my-shell";
  packages = with pkgs; [
    # Development tools here
  ];
}
```

3. **Register DevShell**:
Edit `devshells.nix`:
```nix
perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
  devShells = {
    # ... existing shells ...
    my-shell = inputs.devshell.lib.mkShell {
      imports = [ ./devshells/my-shell.nix ];
      inherit pkgs;
    };
  };
};
```

## Desktop Environment Configuration

### Hardware & Graphics Configuration

#### Nvidia Driver Selection

axios supports multiple nvidia driver versions to accommodate different GPU generations:

```nix
# For most users (default, no configuration needed)
axios.hardware.nvidiaDriver = "stable";  # Conservative, tested

# For RTX 50-series (Blackwell) or newest features
axios.hardware.nvidiaDriver = "beta";

# For latest stable release
axios.hardware.nvidiaDriver = "production";
```

**When to use beta drivers**:
- RTX 50-series GPUs (Blackwell architecture) require beta drivers
- You need cutting-edge features not yet in stable
- You're willing to accept potential stability issues

#### Dual-GPU Desktop Configuration (PRIME Sync)

For desktops with both integrated and discrete GPUs (e.g., AMD iGPU + Nvidia dGPU), use PRIME sync mode to eliminate lag:

**1. Detect GPU Bus IDs**:
```bash
lspci | grep -E 'VGA|3D'
# Example output:
# 03:00.0 VGA compatible controller: NVIDIA Corporation ...
# 0e:00.0 VGA compatible controller: AMD/ATI ...
```

**2. Convert to PCI Bus ID format**:
- Hex `03:00.0` → `PCI:3:0:0` (Nvidia)
- Hex `0e:00.0` → `PCI:14:0:0` (AMD, 0xe = 14 in decimal)

**3. Configure in extraConfig**:
```nix
extraConfig = {
  hardware.nvidia.prime = {
    sync.enable = true;              # Force Nvidia as primary (zero-lag)
    nvidiaBusId = "PCI:3:0:0";       # YOUR Nvidia GPU bus ID
    amdgpuBusId = "PCI:14:0:0";      # YOUR AMD iGPU bus ID
  };
};
```

**Note**: axios automatically disables PRIME on single-GPU desktops. Only configure this for dual-GPU setups.

#### VR Gaming Configuration

Enable VR gaming support with wireless streaming:

```nix
# Basic VR support
gaming.vr.enable = true;  # Enables Steam hardware support and OpenXR

# Wireless VR for Meta Quest
gaming.vr.wireless = {
  enable = true;
  backend = "wivrn";  # or "alvr" or "both"

  # WiVRn-specific options
  wivrn = {
    openFirewall = true;   # Required for wireless streaming
    defaultRuntime = true; # Set as default OpenXR runtime
    autoStart = false;     # Start service on boot (optional)
  };
};

# VR overlays (optional)
gaming.vr.overlays = true;  # wlx-overlay-s, wayvr-dashboard
```

**Features**:
- WiVRn automatically uses CUDA encoding on Nvidia GPUs for better performance
- ALVR available as alternative wireless VR backend
- Steam hardware support for VR controllers and headsets

#### Docker Alternative to Podman

axios uses podman by default (rootless, more secure). To use Docker instead:

```nix
extraConfig = {
  virtualisation.docker.enable = true;
};
```

**Note**: Podman is recommended for security and modern best practices. Only use Docker if you have specific compatibility requirements.

## User Operations

### Installing Additional Applications

axiOS provides two methods for installing additional applications, with different target audiences:

#### Method 1: Flathub via GNOME Software (Recommended for Most Users)

**Target Audience**: Non-technical users, desktop application users

**Advantages**:
- ✅ Graphical interface (GNOME Software)
- ✅ No system rebuilds required
- ✅ Instant installation/removal
- ✅ Sandboxed applications (better security)
- ✅ Latest versions (updates independently of NixOS)
- ✅ Automatic theme integration
- ✅ Thousands of desktop applications available

**How to Install Apps**:
1. Open **GNOME Software** from applications menu
2. Browse or search for applications
3. Click **Install**
4. Application launches immediately after installation

**Example Apps Available on Flathub**:
- **Browsers**: Firefox, Chrome, Edge, Opera, Brave
- **Communication**: Slack, Discord, Telegram, Signal, Teams
- **Media**: Spotify, VLC, Audacity, GIMP, Kdenlive, Blender
- **Productivity**: LibreOffice, OnlyOffice, Thunderbird
- **Development**: Postman, MongoDB Compass, Beekeeper Studio, DBeaver

**Flathub Configuration**:
- Remote automatically configured via `systemd.services.flatpak-add-flathub`
- GNOME Software configured to use Flathub exclusively
- GTK theme access via flatpak overrides

**Troubleshooting**:
```bash
# Check Flathub remote is configured
flatpak remotes

# Manually add if missing (shouldn't be needed)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Search for apps
flatpak search <app-name>

# Install via CLI
flatpak install flathub org.mozilla.firefox
```

#### Method 2: NixOS Packages (For Technical Users)

**Target Audience**: Technical users, reproducible builds, system administrators

**Advantages**:
- ✅ Declarative configuration (reproducible)
- ✅ Version pinning and rollbacks
- ✅ Deep system integration
- ✅ Shareable configurations
- ✅ Works for CLI tools and system services

**How to Add Packages**:
Edit your host configuration (`hosts/<hostname>.nix`):

```nix
{
  hostConfig = {
    # ... existing config ...

    extraConfig = {
      # Add packages here
      environment.systemPackages = with pkgs; [
        firefox
        slack
        htop
        ripgrep
        # ... your packages ...
      ];
    };
  };
}
```

Rebuild system:
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

**When to Use NixOS Packages**:
- System services and daemons
- Command-line utilities and development tools
- Packages that need deep system integration
- Building shareable/reproducible configurations
- Multi-machine deployments

**When to Use Flathub Instead**:
- Desktop GUI applications
- Apps that benefit from sandboxing
- Apps that need frequent updates (browsers, chat apps)
- User doesn't want to rebuild the system

**Best Practice**: Use Flathub for desktop apps, NixOS packages for system tools and CLI utilities.

### DankMaterialShell Customization

axiOS configures DankMaterialShell with all features explicitly enabled by default. Users can customize this configuration in their downstream host configs.

**Default Configuration** (home/desktop/default.nix):
```nix
programs.dankMaterialShell = {
  enable = true;

  # Systemd integration
  systemd = {
    enable = true;
    restartIfChanged = true;
  };

  # Feature toggles (all enabled by default)
  enableSystemMonitoring = true;
  enableClipboard = true;
  enableVPN = true;
  enableBrightnessControl = true;
  enableColorPicker = true;
  enableDynamicTheming = true;
  enableAudioWavelength = true;
  enableCalendarEvents = true;
  enableSystemSound = true;
};
```

**Disabling Features**:
Users can override feature toggles in their home-manager configuration:

```nix
programs.dankMaterialShell = {
  # Disable specific features
  enableAudioWavelength = false;  # Disable cava visualizer
  enableSystemSound = false;       # Disable sound effects
  enableVPN = false;               # Disable VPN widget
};
```

**Niri Integration**:
With systemd integration enabled, DMS should not be spawned via niri:
```nix
# In home/desktop/niri.nix
programs.dankMaterialShell = {
  niri = {
    enableKeybinds = true;
    enableSpawn = false;  # IMPORTANT: false when using systemd service
  };
};
```

**Why enableSpawn = false?**
- With `systemd.enable = true`, DMS runs as a systemd service (dms.service)
- Setting `enableSpawn = true` would spawn a second DMS instance via niri
- This causes duplicate DMS bars and duplicate clipboard managers
- Keybindings still work with enableSpawn = false

**Clipboard Management with enableSpawn = false**:
DMS's `enableClipboard` feature requires `enableSpawn = true` to work. When using the systemd service approach, clipboard must be spawned manually in niri:

```nix
# In home/desktop/niri.nix spawn-at-startup
{
  command = [
    "wl-paste"
    "--watch"
    "cliphist"
    "store"
  ];
}
```

This ensures clipboard history works while preventing duplicate DMS instances.

**Polkit Authentication**:
- axiOS uses DankMaterialShell's built-in polkit agent (no external mate-polkit)
- Authentication prompts handled automatically by DMS
- No additional configuration needed

**Important Note**: If using niri-flake's NixOS module that includes a polkit service, disable it to avoid conflicts:
```nix
systemd.user.services.niri-flake-polkit.enable = false;
```
(Currently not needed - niri-flake doesn't provide a polkit service)

### GNOME Online Accounts Setup (PIM Module)

axiOS provides a dedicated PIM (Personal Information Management) module with lightweight GNOME apps, without requiring a full GNOME desktop. This includes email (Geary or Evolution), GNOME Calendar, and GNOME Contacts, all integrated via GNOME Online Accounts.

**Prerequisites**:
Enable the PIM module in your host configuration:
```nix
modules = {
  pim = true;
};

# Optional: Choose email client (default is "geary")
extraConfig = {
  pim.emailClient = "geary";  # or "evolution" or "both"
};
```

**Architecture**:
- D-Bus backend services (accounts-daemon, gnome-keyring)
- No GNOME Shell or gdm required
- Works with any desktop environment (Niri, Sway, Hyprland, etc.)
- Enabled via `modules.pim = true`

**First-Time Setup**:

1. **Launch GNOME Online Accounts**:
   ```bash
   gnome-online-accounts-gtk
   ```
   Or search for "Online Accounts" in your application launcher.

2. **Add Your Accounts**:
   - Click **+** button to add an account
   - Select account type:
     - **Google**: Gmail, Calendar, Contacts (OAuth2)
     - **Microsoft**: Outlook.com, Office 365 (OAuth2)
     - **IMAP/SMTP**: Any email provider (manual configuration)
     - **CalDAV**: Calendar sync (e.g., iCloud, Nextcloud)
     - **CardDAV**: Contact sync (e.g., iCloud, Nextcloud)
   - Follow authentication flow
   - Select which services to enable (Mail, Calendar, Contacts)

3. **Credentials Storage**:
   - Credentials are stored in GNOME Keyring (encrypted)
   - PAM integration unlocks keyring automatically at login
   - No manual keyring unlock needed

**Using the Applications**:

**Email Client**:

*Geary (default)*:
```bash
geary
```
- Modern, lightweight email client
- Accounts from GNOME Online Accounts appear automatically
- Simple, clean interface

*Evolution (optional)*:
```bash
evolution
```
- Full-featured email client with better Exchange/EWS support
- Accounts from GNOME Online Accounts appear automatically
- Supports conversation view, search, labels
- Better integration with corporate email systems

**GNOME Calendar**:
```bash
gnome-calendar
```
- Syncs calendars from all configured accounts
- Supports CalDAV for self-hosted calendars
- Event notifications integrated with desktop

**GNOME Contacts**:
```bash
gnome-contacts
```
- Syncs contacts from all configured accounts
- Supports CardDAV for self-hosted contacts
- Integrated with email client

**Troubleshooting**:

**"Cannot connect to org.gnome.evolution.dataserver.Sources5" error**:
This means Evolution Data Server is not running. The PIM module enables it automatically, but if you see this error:
1. **Verify PIM module is enabled** in your configuration:
   ```nix
   modules.pim = true;  # Automatically enables required services
   ```
   The PIM module enables these services automatically:
   - `services.gnome.evolution-data-server.enable`
   - `services.gnome.gnome-online-accounts.enable`
   - `services.geoclue2.enable`
2. **Check system service status**:
   ```bash
   systemctl --user status evolution-source-registry
   systemctl --user status evolution-addressbook-factory
   systemctl --user status evolution-calendar-factory
   ```
3. **Restart services**:
   ```bash
   systemctl --user restart evolution-source-registry
   ```

**"org.freedesktop.GeoClue2 was not provided" error**:
This prevents weather features in GNOME Calendar. To enable:
```nix
services.geoclue2.enable = true;  # Location services for weather
```

**If accounts don't appear in applications**:
1. **Check D-Bus services**:
   ```bash
   systemctl --user status goa-daemon
   ```
2. **Verify account is active**:
   ```bash
   gnome-online-accounts-gtk
   ```
   Ensure account has checkmark and is not in error state.

3. **Check GNOME Keyring**:
   ```bash
   ps aux | grep gnome-keyring
   ```
   Should show keyring daemon running.

4. **Re-add account**:
   If an account shows errors, delete and re-add it in GNOME Online Accounts.

**Manual IMAP/SMTP Configuration**:
For providers not offering OAuth2:
1. In GNOME Online Accounts, select "IMAP/SMTP"
2. Enter email address
3. Configure IMAP:
   - Server: imap.example.com
   - Port: 993 (SSL/TLS) or 143 (STARTTLS)
   - Username: your-username
   - Password: your-password
4. Configure SMTP:
   - Server: smtp.example.com
   - Port: 465 (SSL/TLS) or 587 (STARTTLS)
   - Username: your-username
   - Password: your-password

**Integration with DMS**:
- DMS Calendar Events feature can sync with GNOME Calendar (via khal)
- This provides calendar widgets in the DMS shell

## Deployment

### Pre-Deployment Checklist
- [ ] All tests passing (`nix flake check`)
- [ ] Code formatted (`nix fmt -- --fail-on-change .`)
- [ ] CHANGELOG.md updated
- [ ] Version tag created (v<YEAR>.<MONTH>.<DAY>)
- [ ] flake.lock updated if needed

### Release Process

**1. Update CHANGELOG**:
```bash
# Edit CHANGELOG.md
# Add new version section with changes
```

**2. Create Git Tag**:
```bash
# Tag format: v<YEAR>.<MONTH>.<DAY>
git tag v2025.11.22
git push origin v2025.11.22
```

**3. Create GitHub Release**:
```bash
# Via GitHub web interface or gh CLI
gh release create v2025.11.22 --generate-notes
```

**4. Users Update**:
Users update their flake.lock:
```bash
# In downstream configuration
nix flake lock --update-input axios
sudo nixos-rebuild switch --flake .#<hostname>
```

### Rollback Procedure
**Library Level**: Users can pin to specific tag:
```nix
# In downstream flake.nix
inputs.axios.url = "github:kcalvelli/axios/v2025.11.19";
```

**System Level** (user's system):
```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot to specific generation
sudo nixos-rebuild switch --switch-generation <number>
```

## CI/CD Operations

### Triggering CI Workflows

**Automatic Triggers**:
- Push to master: flake-check, formatting (if .nix changed)
- Pull requests: flake-check, formatting
- Weekly: flake-lock-updater (Mondays 6 AM UTC)

**Manual Triggers**:
```bash
# Via GitHub web interface: Actions tab → Select workflow → Run workflow

# Or via gh CLI
gh workflow run flake-check.yml
gh workflow run formatting.yml
gh workflow run test-init-script.yml
```

### Monitoring CI

**Check Workflow Status**:
```bash
gh run list --workflow=flake-check.yml
gh run view <run-id>
```

**View Logs**:
```bash
gh run view <run-id> --log
```

### Handling CI Failures

**Flake Check Failure**:
1. Check error message in CI logs
2. Reproduce locally: `nix flake check`
3. Fix evaluation errors
4. Push fix

**Formatting Failure**:
1. Run `nix fmt .` or `./scripts/fmt.sh` locally
2. Commit formatted code
3. Push fix

**Dependency Update Failure**:
1. Review flake-lock-updater PR
2. Check for breaking changes in dependencies
3. Update code if needed or pin dependency version

## Debugging

### Local Debugging

**Verbose Evaluation**:
```bash
# Show detailed evaluation trace
nix eval --show-trace .#nixosConfigurations.example.config.system.build.toplevel
```

**Check Module Options**:
```bash
# List all options provided by a module
nix eval .#nixosModules.desktop.options --apply 'opts: builtins.attrNames opts'
```

**Inspect Flake**:
```bash
# Show all flake outputs
nix flake show

# Show flake metadata
nix flake metadata

# Show flake lock file dependencies
nix flake lock --dry-run
```

**Build with Debug Output**:
```bash
# Verbose build output
nix build --print-build-logs --verbose .#packages.x86_64-linux.immich
```

### Evaluation Errors

**Infinite Recursion**:
```bash
# Use show-trace to identify recursion point
nix eval --show-trace <expression>
```

**Type Errors**:
```bash
# Nix will show expected vs actual type
# Fix option definitions to match expected types
```

**Undefined Variables**:
```bash
# Check let bindings and function parameters
# Ensure all variables are in scope
```

### Common Issues

#### Issue: Screen blanks and doesn't recover with niri/DMS
**Symptoms**: Screen goes black after idle timeout and doesn't wake up on keyboard/mouse input

**Root Cause**: DMS idle management uses `wlr-output-power-management` protocol which niri doesn't support

**Diagnosis**:
```bash
# Check if DMS DPMS commands fail
dms dpms list
# Should show: "wlr-output-power-management protocol not supported by compositor"

# Check DMS idle settings
cat ~/.config/DankMaterialShell/settings.json | grep -E "(ac|battery)(Monitor|Lock|Suspend)Timeout"
```

**Solution**:
Configure idle management via DankMaterialShell settings in `~/.config/DankMaterialShell/settings.json`:

```json
{
  "acMonitorTimeout": 30,  // Minutes until monitor turns off (AC power)
  "acLockTimeout": 0,       // Set to 0 to disable, or minutes to lock
  "acSuspendTimeout": 0,    // Set to 0 to disable, or minutes to suspend
  "batteryMonitorTimeout": 15,
  "batteryLockTimeout": 0,
  "batterySuspendTimeout": 0
}
```

After changing settings:
```bash
dms restart
```

**Manual Lock**: Use Super+Alt+L (DMS lock screen keybind)

**Technical Details**:
- Idle management is user-configured via DankMaterialShell settings
- No default idle configuration is provided by axiOS
- Users control monitor timeout, lock timeout, and suspend timeout independently

#### Issue: "experimental feature 'nix-command' not enabled"
**Symptoms**: Nix commands fail with experimental feature error

**Diagnosis**:
```bash
nix --version
cat ~/.config/nix/nix.conf
```

**Solution**:
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
# Or set in /etc/nix/nix.conf for system-wide
```

#### Issue: "unable to download 'https://github.com/...': HTTP error 404"
**Symptoms**: Flake input fetch fails

**Diagnosis**:
```bash
# Check if input URL is correct
nix flake metadata
```

**Solution**:
```bash
# Update flake.lock
nix flake lock --update-input <input-name>
```

#### Issue: Module option conflict
**Symptoms**: "The option 'X' has conflicting definitions"

**Diagnosis**:
```bash
# Check which modules are setting the conflicting option
nix eval --show-trace <config-path>
```

**Solution**:
- Use `lib.mkForce` to override
- Use `lib.mkDefault` for default values
- Restructure module imports to avoid conflicts

#### Issue: Cache download fails
**Symptoms**: Slow builds, cache timeouts

**Diagnosis**:
```bash
# Check cache availability
nix store ping --store https://niri.cachix.org
```

**Solution**:
```bash
# Fall back to building from source (automatic)
# Or add --no-substitutes to skip cache
nix build --no-substitutes
```

## Dependency Management

### Updating Dependencies

**Update All Inputs**:
```bash
nix flake update
```

**Update Specific Input**:
```bash
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager
```

**Pin Input to Specific Commit**:
```nix
# In flake.nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs/abc123def456";
```

**Check for Updates**:
```bash
# Show outdated inputs
nix flake metadata --json | jq '.locks.nodes'
```

### Handling Breaking Changes

1. **Review Changelog**: Check input project's changelog for breaking changes
2. **Test Locally**: `nix flake check` after update
3. **Update Code**: Adapt to API changes
4. **Test in VM**: Build and test VM before deploying
5. **Commit**: Update flake.lock and code together

## Monitoring & Alerts

**N/A** - Library project has no production monitoring

**User Systems**: Users should monitor their own systems using:
- systemd journal: `journalctl -f`
- systemd status: `systemctl status`
- System metrics: `htop`, `nmon`, etc.

## Maintenance

### Routine Maintenance
- **Weekly Dependency Updates**: Automated via flake-lock-updater (Mondays 6 AM UTC)
- **Code Formatting**: Checked on every PR
- **Flake Validation**: Checked on every push

### Security Updates
- **nixpkgs**: Updated weekly via automated PR
- **Critical CVEs**: Manual emergency update
  ```bash
  nix flake lock --update-input nixpkgs
  git commit -m "security: Update nixpkgs for CVE-XXXX-XXXX"
  git push
  ```

### Deprecation Handling
1. **Identify Deprecated Features**: Check nixpkgs release notes
2. **Update Code**: Migrate to new APIs
3. **Update CHANGELOG**: Document breaking changes
4. **Communicate**: Tag release with migration guide

## Getting Help

### Resources
- **Documentation**: [docs/README.md](../docs/README.md)
- **Project Documentation**: [.claude/project.md](../.claude/project.md)
- **Issue Tracker**: https://github.com/kcalvelli/axios/issues
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes

### Community
- [TBD] Discord/Matrix/Forum links
- [TBD] Contribution guidelines

### Reporting Issues
1. Check existing issues: `gh issue list`
2. Create new issue: `gh issue create`
3. Include:
   - Nix version: `nix --version`
   - Flake metadata: `nix flake metadata`
   - Error messages with `--show-trace`
   - Minimal reproduction

## Common Issues

### irqbalance Permission Denied Warnings

**Symptom**: System logs show repeated irqbalance warnings:
```
irqbalance: IRQ XX affinity is now unmanaged
irqbalance: Cannot change IRQ XX affinity: Permission denied
```

**Analysis**:
- **NOT a problem** - These are cosmetic informational warnings
- Certain IRQs are managed by other kernel mechanisms and locked from userspace changes
- Some hardware doesn't support affinity changes for specific IRQs
- The kernel may have already set optimal affinity

**Impact**: None - System performance is unaffected

**Solutions** (optional):
1. **Do nothing** (recommended) - Warnings are harmless
2. **Disable irqbalance** if you don't need dynamic IRQ balancing:
   ```nix
   services.irqbalance.enable = false;
   ```
3. **Reduce logging verbosity**:
   ```nix
   systemd.services.irqbalance.serviceConfig.StandardOutput = "null";
   ```

### System Freezes (Desktop)

**Symptom**: Complete system freeze requiring hard reboot

**Common Causes**:
1. **GPU Driver Hang** (most common on AMD/NVIDIA)
2. **Kernel bug** or memory issue
3. **Disk I/O hang** (NVMe driver issue)

**Diagnostics**:
```bash
# Check for unclean shutdown after reboot
journalctl -b 0 | grep -i "uncleanly shut down"

# Check previous boot logs for errors
journalctl -b -1 --priority=0..3

# Check kernel logs from previous boot
journalctl -b -1 -k
```

**Prevention**:
1. **Enable crash diagnostics module**:
   ```nix
   hardware.crashDiagnostics.enable = true;
   ```
   This enables:
   - Automatic reboot on kernel panic (30s default)
   - Kernel oops treated as panic for recovery
   - Optional crash dumps for analysis

2. **GPU recovery** (AMD, already enabled in graphics module):
   - `amdgpu.gpu_recovery=1` allows GPU reset on hang

**Post-Freeze Analysis**:
```bash
# Check for crash dumps
ls -la /sys/fs/pstore/

# Review journal for clues
journalctl -b -1 --since "HH:MM:SS" | tail -100
```

## Unknowns
- [TBD] VM testing procedures with axios modules
- [TBD] Integration testing strategy for module interactions
- [TBD] Performance profiling for Nix evaluation
- [TBD] Complete troubleshooting guide for each module
- [TBD] Contribution workflow and guidelines
- [TBD] Issue triage process
- [TBD] Release management responsibilities
