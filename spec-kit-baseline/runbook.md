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
