## Delta: PWA Browser Flags (additions to desktop/spec.md)

Adds a new requirement after "Requirement: PWA Launcher Scripts" and a new
scenario to the existing requirement.

---

### Addition to: Requirement: PWA Launcher Scripts

#### Scenario: PWA inherits browser hardware acceleration flags

- **Given**: `axios.hardware.gpuType` is set to `"amd"` or `"nvidia"`
- **And**: `desktop.browserArgs` exposes computed acceleration flags per browser
- **When**: A PWA launcher script is generated
- **Then**: The launcher exec line includes all flags from `desktop.browserArgs` for the effective browser
- **And**: Flags appear before `--app=` in the command line
- **And**: The PWA has identical GPU acceleration behavior to launching the URL in the browser directly

#### Scenario: PWA launch without GPU configuration

- **Given**: `axios.hardware.gpuType` is not set (null)
- **When**: A PWA launcher script is generated
- **Then**: Only base args (`--password-store=detect`) are included
- **And**: No GPU-specific flags are added

---

### New Requirement: Browser Args Exposure

The desktop module SHALL expose computed browser command-line arguments as a
read-only NixOS option (`desktop.browserArgs`) so that downstream modules
(including home-manager PWA generation) can consume GPU-aware flags without
duplicating detection logic.

#### Scenario: Home-manager module reads browser args

- **Given**: `desktop.enable = true`
- **And**: `axios.hardware.gpuType = "amd"`
- **When**: `pwa-apps.nix` evaluates
- **Then**: `osConfig.desktop.browserArgs.brave` contains AMD acceleration flags
- **And**: `osConfig.desktop.browserArgs.chromium` contains the same flags
- **And**: `osConfig.desktop.browserArgs.google-chrome` contains the same flags

#### Scenario: Chromium receives acceleration flags

- **Given**: `desktop.enable = true` (previously Chromium had no flags)
- **When**: System builds
- **Then**: `programs.chromium.commandLineArgs` includes GPU acceleration flags
- **And**: Chromium (the default PWA browser) has hardware acceleration parity with Brave and Chrome
