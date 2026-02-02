# Fix: ksshaskpass spams kwalletd6 D-Bus errors

## Type
Defect fix

## Problem

`ksshaskpass` unconditionally tries to contact `org.kde.kwalletd6` for
password caching. axiOS uses GNOME Keyring (not KWallet), so kwalletd6
doesn't exist, producing repeated D-Bus errors:

```
Couldn't start kwalletd: QDBusError("org.freedesktop.DBus.Error.ServiceUnknown",
"The name org.kde.kwalletd6 was not provided by any .service files")
```

There is no configuration flag to disable KWallet integration in
ksshaskpass — it's hardcoded.

## Solution

Replace `kdePackages.ksshaskpass` with `lxqt.lxqt-openssh-askpass`:
- Simple Qt6 password dialog, no wallet dependency
- Fits axiOS's Qt-heavy desktop (Dolphin, Okular, Haruna, etc.)
- No D-Bus errors, no KWallet coupling

### Changes

1. `modules/desktop/default.nix` — Replace `ksshaskpass` with
   `lxqt.lxqt-openssh-askpass` in systemPackages.
2. `home/desktop/default.nix` — Update `SUDO_ASKPASS` env var to point
   at the new binary.
