{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Flatpak install handler script for .flatpakref files
  axios-flatpak-install = pkgs.writeShellScriptBin "axios-flatpak-install" ''
    set -euo pipefail

    REF_FILE="''${1:-}"

    if [ -z "$REF_FILE" ]; then
      echo "Usage: axios-flatpak-install <file.flatpakref>"
      echo ""
      echo "Press Enter to close..."
      read -r
      exit 1
    fi

    APP_NAME=$(${pkgs.gnugrep}/bin/grep -oP '^Name=\K.*' "$REF_FILE" 2>/dev/null || ${pkgs.coreutils}/bin/basename "$REF_FILE" .flatpakref)

    echo ""
    echo "  axiOS Flatpak Installer"
    echo ""
    echo "  Installing: $APP_NAME"
    echo ""

    ${pkgs.flatpak}/bin/flatpak install --user "$REF_FILE"
    EXIT_CODE=$?

    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
      echo "  Installation complete!"
    else
      echo "  Installation failed (exit code: $EXIT_CODE)"
    fi
    echo ""
    echo "  Press Enter to close..."
    read -r
  '';
in
{
  config = lib.mkIf config.desktop.enable {

    # === Core Flatpak Services ===
    services.flatpak.enable = true;

    # === Flatpak Utilities & Store ===
    environment.systemPackages = with pkgs; [
      # The Janitor (Manage remotes and delete leftover user data)
      warehouse
      # Flatpak install handler for .flatpakref files (used by MIME handler)
      axios-flatpak-install
    ];

    # === Flathub Remote Setup ===
    # Adds Flathub automatically on first boot/rebuild
    system.activationScripts.setupFlathubSystem = {
      text = ''
        ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      '';
      deps = [ "etc" ];
    };
  };
}
