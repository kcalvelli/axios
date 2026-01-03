{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.desktop.enable {

    # === Core Flatpak Services ===
    services.flatpak.enable = true;

    # Force "Flatpak Only" mode for any installed software centers (like Discover/Bauh)
    # by disabling the PackageKit service that manages native Nix packages.
    services.packagekit.enable = false;

    # === Flatpak Utilities & Scripts ===
    environment.systemPackages = with pkgs; [
      # Essential maintenance tool for cleaning up user data/remotes
      warehouse

      # -----------------------------------------------------------------------
      # 1. TUI Store ("axios-store")
      # A terminal-centric "App Store" using fzf to search and install from Flathub
      # -----------------------------------------------------------------------
      (writeShellScriptBin "axios-store" ''
        if ! command -v fzf &> /dev/null; then
          echo "Error: fzf is required."
          exit 1
        fi

        echo "Fetching Flathub data..."
        # Get list, format nicely, feed to fzf
        SELECTED=$(flatpak remote-ls --app --columns=name,application,description flathub | \
          fzf --header="Axios App Store (Flatpak)" \
              --layout=reverse \
              --border \
              --prompt="Search Apps > " \
              --preview "flatpak remote-info --show-metadata flathub {2}" \
              --preview-window=right:50%:wrap)

        if [ -n "$SELECTED" ]; then
          APP_ID=$(echo "$SELECTED" | awk '{print $2}')
          APP_NAME=$(echo "$SELECTED" | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//')
          
          echo "Installing $APP_NAME ($APP_ID)..."
          flatpak install flathub "$APP_ID" -y
        fi
      '')

      # -----------------------------------------------------------------------
      # 2. Web Handler ("axios-flatpak-install")
      # Catches flatpakref links from browsers and opens them in a floating terminal
      # -----------------------------------------------------------------------
      (writeShellScriptBin "axios-flatpak-install" ''
        REF="$1"

        # Launch 'foot' in a specific size/title so Window Manager rules can float it
        ${pkgs.foot}/bin/foot \
          --title="Axios Store" \
          --window-size-chars=100x20 \
          -- \
          sh -c "echo 'Received request to install: $REF'; \
                 echo '-----------------------------------'; \
                 flatpak install --user --from '$REF'; \
                 echo '-----------------------------------'; \
                 echo 'Process complete. Press Enter to close.'; \
                 read"
      '')

      # -----------------------------------------------------------------------
      # 3. Desktop Entry
      # Registers the handler script with the Desktop Environment
      # -----------------------------------------------------------------------
      (makeDesktopItem {
        name = "axios-flatpak-install";
        desktopName = "Axios Flatpak Installer";
        exec = "axios-flatpak-install %u";
        icon = "system-software-install";
        terminal = false; # We spawn our own terminal window in the script
        type = "Application";
        mimeTypes = [
          "application/vnd.flatpak.ref"
          "application/vnd.flatpak.repo"
        ];
        noDisplay = true; # Don't clutter the app launcher
      })
    ];

    # === MIME Association ===
    # Tell the browser/OS to use our new desktop entry for flatpak files
    xdg.mime.enable = true;
    xdg.mime.defaultApplications = {
      "application/vnd.flatpak.ref" = "axios-flatpak-install.desktop";
      "application/vnd.flatpak.repo" = "axios-flatpak-install.desktop";
    };

    # === Flathub Remote Setup ===
    # Adds Flathub at the system level automatically on rebuild
    system.activationScripts.setupFlathubSystem = {
      text = ''
        ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      '';
      deps = [ "etc" ];
    };
  };
}
