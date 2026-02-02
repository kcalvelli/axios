# Tasks: Fix askpass KWallet dependency

- [x] **1** Replace `kdePackages.ksshaskpass` with `lxqt.lxqt-openssh-askpass`
      in `modules/desktop/default.nix` systemPackages.
- [x] **2** Update `SUDO_ASKPASS` in `home/desktop/default.nix` to point at
      `lxqt.lxqt-openssh-askpass`.
- [x] **3** Update desktop spec comment about ksshaskpass.
- [x] **4** Run `nix fmt .` and `nix flake check --all-systems`.
- [x] **5** Archive delta.
