# Tasks: Custom axiOS Branding

## Goal
Replace the default NixOS logo with axiOS branding in the system, allowing DMS launcher to display the axiOS logo instead of the default NixOS snowflake.

## Background
- DMS (DankMaterialShell) has a launcher setting to "use OS logo"
- This setting reads from `/etc/os-release` `LOGO` field
- The LOGO field references an icon name that's looked up in standard icon directories
- Currently shows "nix-snowflake" (default NixOS logo)

## Tasks

- [x] Create OpenSpec delta directory (`openspec/changes/custom-branding/`)
- [x] Write implementation tasks
- [ ] Move `axios_clean.png` from project root to `modules/system/resources/branding/axios.png`
- [ ] Create new module file `modules/system/branding.nix`
  - Install axiOS logo to system pixmaps directory (`/run/current-system/sw/share/pixmaps/`)
  - Configure `system.nixos.distroId = "axios"`
  - Configure `system.nixos.distroName = "axiOS"`
  - Configure `system.nixos.variant = ""` (or appropriate variant)
  - Add logo reference to os-release via environment.etc
- [ ] Import `branding.nix` in `modules/system/default.nix`
- [ ] Test that `/etc/os-release` contains `LOGO="axios"` after rebuild
- [ ] Test that DMS launcher shows axiOS logo when configured
- [ ] Format code with `nix fmt .`
- [ ] Update `openspec/specs/system/spec.md` with branding configuration details
- [ ] Archive this delta to `openspec/changes/archive/custom-branding/`

## Implementation Notes

### os-release Configuration
NixOS provides `system.nixos` options to customize `/etc/os-release`:
- `distroId` - Sets the `ID` field (default: "nixos")
- `distroName` - Sets the `NAME` and `PRETTY_NAME` fields (default: "NixOS")
- `variant` - Sets the `VARIANT` and `VARIANT_ID` fields

The `LOGO` field must be set via `environment.etc."os-release"` to override the default.

### Icon Installation
The logo PNG should be installed to `/run/current-system/sw/share/pixmaps/` so it's available system-wide. The LOGO field references the basename without extension (e.g., "axios" for "axios.png").

### DMS Integration
Once the logo is installed and os-release is updated, DMS will automatically detect and use the axiOS logo when the "use OS logo" setting is enabled in its launcher configuration.

## Files Modified
- `modules/system/branding.nix` (new)
- `modules/system/default.nix` (imports)
- `axios_clean.png` → `modules/system/resources/branding/axios.png` (moved)

## Files Created
- `modules/system/resources/branding/axios.png`
- `modules/system/branding.nix`
