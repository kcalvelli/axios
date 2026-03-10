## Context

axiOS modules install packages at two levels: NixOS system packages (`environment.systemPackages`) and home-manager packages (`home.packages` / `programs.*`). Several CLI tools are installed at both levels — the system-level install provides a bare binary while home-manager provides the same binary plus shell integration, aliases, and configuration. This results in redundant store paths and a larger system closure.

Additionally, some system packages are installed outside `lib.mkIf` blocks, violating the framework's conditional evaluation pattern.

## Goals / Non-Goals

**Goals:**
- Remove duplicate package declarations where home-manager already provides the tool
- Consolidate overlapping system monitors (gtop/htop/btop)
- Wrap unconditionally-installed packages in appropriate guards
- Deduplicate identical package lists across AI module role blocks

**Non-Goals:**
- Restructuring the desktop module's application choices (separate change)
- Adding new `enable` options for printing or cachix (just wrap in existing guards)
- Changing any user-facing behavior or options

## Decisions

### 1. Remove CLI tools from development module, keep in home-manager

**Decision**: Remove eza, fzf, gh, fish, starship, neovim, bat from `modules/development/default.nix`. Home-manager `programs.*` declarations in `home/terminal/` are the canonical source.

**Rationale**: home-manager `programs.X.enable` installs the package AND configures shell integration (aliases, completions, config files). The system-level package is strictly redundant and the home-manager version is superior.

**Alternative considered**: Remove from home-manager, keep in system. Rejected because home-manager provides config management that system packages don't.

### 2. Replace gtop with btop in system module

**Decision**: Remove gtop from `modules/system/default.nix`, add btop there instead. Remove btop from `modules/development/default.nix`.

**Rationale**: btop is a superset of gtop (GPU monitoring, mouse support, more metrics). Having a system monitor available without the development module is useful for all systems. Three separate monitors is unnecessary.

**Note**: htop is kept in the system module as it's the standard lightweight fallback that works everywhere (SSH, minimal terminals, recovery).

### 3. Remove mtr from development module

**Decision**: Remove the `mtr` package from `modules/development/default.nix`. The networking module's `programs.mtr.enable = true` already provides mtr with proper capabilities (setcap/suid for raw socket access).

### 4. Lift python3+uv to shared AI local block

**Decision**: Move `python3` and `uv` from both server and client role blocks into a `lib.mkIf (cfg.enable && cfg.local.enable)` block.

**Rationale**: Both roles install identical packages. A shared conditional block eliminates the duplication.

### 5. Wrap cachix in system enable guard

**Decision**: Move cachix inside the existing `lib.mkIf config.axios.system.enable` block in `modules/system/default.nix` rather than leaving it unconditional in `nix.nix`.

**Rationale**: The cache substituters are configured separately in nix settings and work without the CLI. The CLI is only needed for manual `cachix push` operations. Wrapping it in the system enable guard is sufficient.

## Risks / Trade-offs

- **[Risk] Users relying on system-level fish/starship outside home-manager** → Mitigation: These tools are only useful with their configurations; bare installs without config are rarely intentional. The development module's bash→fish launcher still references fish via `${pkgs.fish}/bin/fish`, which pulls it in as a runtime dependency regardless.
- **[Risk] Removing gtop breaks someone's workflow** → Mitigation: btop provides a superset of functionality. Users who specifically want gtop can add it to `extraConfig`.
- **[Risk] bat removal from development** → Mitigation: bat is not provided by home-manager `programs.*` in the current codebase. Need to verify — if no home-manager declaration exists, keep it in development.
