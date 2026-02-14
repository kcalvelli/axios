## Context

axiOS has a singular user model (`axios.user`) that creates one user account per host, wired via a stringly-typed `userModulePath`. Multi-user hosts bypass the framework entirely — the "mini" host has a 196-line manual user module with copy-pasted home-manager configs and hand-rolled group filtering. The downstream config structure is freeform: each host evolved its own wiring pattern, and there's no prescribed way to organize user definitions, host configs, or secrets.

The fresh install experience exposed systemic fragility: 5 of 8 DMS placeholder files missing, NVIDIA kernel module compilation failure, AMD VA-API not configured, deprecated xorg references. These are all symptoms of assumptions that work on existing systems but break on first boot.

This change makes axiOS opinionated about downstream structure and replaces the singular user model with a multi-user framework.

## Goals / Non-Goals

**Goals:**
- Prescribe a canonical downstream config structure that axiOS enforces
- Multi-user support via `axios.users.<name>` attrset with admin/non-admin roles
- Host configs declare users by name; `mkSystem` resolves user files from the canonical structure
- Per-user home-manager profile selection (workstation/laptop/minimal)
- Init script generates the canonical structure with multi-user support
- Systematic DMS placeholder generation for first-boot robustness
- Hardware pre-flight checks in init script

**Non-Goals:**
- Backward compatibility with `axios.user` or `userModulePath` — this is a clean break
- Per-user module selection (all users on a host share system modules)
- User password management — remains a downstream concern
- Auto-discovery of hosts from directory (users explicitly list hosts in flake.nix)
- LDAP/AD integration or remote user provisioning

## Decisions

### D1: Canonical downstream config structure

**Decision**: axiOS prescribes this structure:
```
<config-dir>/
├── flake.nix
├── users/
│   └── <username>.nix       # One per user
├── hosts/
│   ├── <hostname>.nix        # Host config
│   └── <hostname>/
│       └── hardware.nix      # hardware-configuration.nix copy
├── secrets/                   # Optional
└── .gitignore
```

**Why**: Without a prescribed structure, each multi-host config drifts into its own pattern. The "mini" host needed a custom `userModulePath` pointing to a monolith file. A canonical structure means `mkSystem` can resolve users by convention, the init script generates a consistent layout, and documentation always matches reality.

**Alternative considered**: Auto-discover hosts from `hosts/` directory — rejected because explicit host listing in flake.nix is clearer, doesn't require directory scanning (which is impure in Nix), and keeps the flake as the single entry point.

### D2: `axios.users.<name>` as attrset of submodules (replacing `axios.user`)

**Decision**: Remove `axios.user` entirely. Replace with `axios.users` using `lib.types.attrsOf (lib.types.submodule { ... })`. Each user gets: `fullName` (str), `email` (str, default ""), `isAdmin` (bool, default false), `homeProfile` (enum or null, default null), `extraGroups` (list of str).

**Why**: The singular `axios.user` was the root cause of the multi-user workaround pattern. An attrset of submodules is idiomatic NixOS (same pattern as `users.users.<name>`) and naturally supports any number of users.

**Alternative considered**: Keep `axios.user` with a backward compat shim — rejected per user decision to make this a breaking change and force downstream conformance.

### D3: Host configs declare users by name; mkSystem resolves via configDir

**Decision**: Host configs specify `users = [ "keith" "traci" ]`. The downstream flake passes `configDir = self.outPath` when calling `mkSystem`. `mkSystem` constructs module paths as `configDir + "/users/${name}.nix"` for each listed user.

**Why**: This eliminates all stringly-typed path wiring from host configs. Users are referenced by name (the same name as their filename and their `axios.users` key). The resolution logic lives in one place (`lib/default.nix`).

**Implementation**: In `buildModules`:
```nix
userModules =
  let
    configDir = hostCfg.configDir or null;
    userNames = hostCfg.users or [];
  in
  if configDir != null then
    map (name: configDir + "/users/${name}.nix") userNames
  else
    [];
```

The downstream flake template uses a `mkHost` helper:
```nix
mkHost = hostname: axios.lib.mkSystem (
  (import ./hosts/${hostname}.nix { lib = nixpkgs.lib; }).hostConfig // {
    configDir = self.outPath;
  }
);
```

### D4: Group logic with isAdmin flag

**Decision**: The existing auto-group computation stays. `isAdmin` controls `wheel` membership. Non-admin users get all desktop/virt/hardware groups but without `wheel`. `nix.settings.trusted-users` is set to admin usernames only.

**Why**: The current `users/mini.nix` already manually implements `lib.filter (g: g != "wheel") adminGroups`. This promotes that pattern to a first-class feature.

### D5: Per-user home-manager profile

**Decision**: Each user's `homeProfile` can be `"workstation"`, `"laptop"`, `"minimal"`, or `null`. When `null`, inherits the host's `homeProfile`. Profile-specific modules are imported per-user in `home-manager.users.<name>.imports`, not via global `sharedModules`.

**Why**: Family members on "mini" don't need dev tools. The primary user gets workstation profile, family gets minimal. Currently `sharedModules` applies the same profile to everyone.

**Implementation**: Universal modules (secrets, AI, PIM) stay in `sharedModules`. Profile-specific modules move to per-user imports based on each user's resolved profile.

### D6: Systematic DMS placeholder generation

**Decision**: Define a single authoritative list of all DMS KDL config filenames. Generate empty `xdg.configFile` placeholders for all of them. Use `mkDefault` or `force = false` so DMS-generated content takes precedence.

**Why**: Hand-maintaining which DMS files need placeholders is fragile — 5 of 8 were missing on the fresh install. A single list ensures first-boot works.

### D7: Init script generates canonical structure

**Decision**: The init script creates the prescribed directory layout: `users/` with per-user files, `hosts/` with per-host config + hardware subdirectory, `secrets/` if enabled. Multi-user prompting: primary admin, then optional additional users in a loop.

**Why**: The init script is the primary onboarding path. It must generate the canonical structure so new users start with the correct layout from day one.

### D8: Host config simplification

**Decision**: Host config files no longer accept `userModulePath` as a parameter. They are simpler:
```nix
{ lib, ... }:
{
  hostConfig = {
    hostname = "mini";
    users = [ "keith" "traci" "henry" ];
    hardware = { cpu = "amd"; gpu = "nvidia"; };
    modules = { desktop = true; gaming = true; };
    # ...
  };
}
```

**Why**: Removing the `userModulePath` parameter eliminates the need for the flake to thread paths through to host configs. Host configs become pure data declarations.

## Risks / Trade-offs

**[Breaking change for all downstream configs]** → Every downstream config must restructure. Mitigated by: init script can generate the new layout, migration steps documented clearly, and there are currently very few downstream configs.

**[configDir path resolution at eval time]** → `configDir + "/users/${name}.nix"` must resolve at Nix evaluation time. This works because `self.outPath` in a flake is a store path containing all tracked files. Risk: if user files aren't committed to git, they won't be in the flake's store path. Mitigated by: init script generates `.gitignore` that doesn't exclude `users/` or `hosts/`, and documentation warns about this.

**[DMS placeholder list goes stale]** → If DMS adds new KDL files. Mitigated by: comment referencing DMS repo, and the fresh-install failure mode is immediately visible (niri won't start).

**[Per-user profile increases eval complexity]** → Each user with a different profile gets different HM imports. Mitigated by: most users use null (inherit host), so this only affects intentional customization.

## Open Questions

1. **Should `homeProfile` for non-admin users default to "minimal" instead of null?** — Family members probably don't need dev tools, but defaulting to minimal means extra config for power users who want workstation for everyone.

2. **Should there be a "common" user config file** (e.g., `users/common.nix`) for shared home-manager config that applies to all users on all hosts? — Would eliminate the PWA copy-paste problem but adds another convention to learn.
