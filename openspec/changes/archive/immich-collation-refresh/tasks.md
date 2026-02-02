# Delta: PostgreSQL Collation Auto-Refresh for Immich

## Problem

When glibc is updated during a NixOS rebuild, PostgreSQL databases retain the old collation version, producing repeated warnings every minute in the journal. This requires manual `ALTER DATABASE ... REFRESH COLLATION VERSION` after every glibc bump.

## Tasks

- [x] Add `systemd.services.postgresql-collation-refresh` oneshot service to `modules/services/immich.nix` inside the `isServer` mkIf block
- [x] Update services spec to document the auto-refresh feature
- [x] Merge delta spec into `openspec/specs/services/spec.md`
- [x] Archive this change directory
- [x] Format and validate (`nix fmt .`, `nix flake check`)

## Design Decisions

- **Placement in immich.nix**: PostgreSQL is only used by the Immich server role; this is the natural home for the fix.
- **Idempotent**: `ALTER DATABASE ... REFRESH COLLATION VERSION` is a no-op when collation is already current.
- **Uses `config.services.postgresql.package`**: Ensures the psql binary matches the active PostgreSQL version.
- **Runs as `postgres` user**: Required for ALTER DATABASE superuser privileges.
- **`|| true` on each ALTER**: Prevents service failure if any individual database ALTER fails.
- **Handles template1 separately**: It's a template but needs refreshing; template0 has NULL collation and is skipped.
