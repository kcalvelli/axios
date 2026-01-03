{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.enable {
    
    # === Core Flatpak Services ===
    services.flatpak.enable = true;
    services.packagekit.enable = false;

    # === Flatpak Utilities & Scripts ===
    environment.systemPackages = with pkgs; [
      warehouse

      # 1. TUI Store ("axios-store")
      (writeShellScriptBin "axios-store" ''
        if ! command -v fzf &> /dev/null; then
          echo "Error: fzf is required."
          exit 1
        fi
        
        # Check if we are in a terminal; if not, re-launch in foot
        if [ ! -t 0 ]; then
           exec ${pkgs.foot}/bin/foot $0 "$@"
        fi

        echo "Fetching Flathub data..."
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
          
          echo ""
          echo "Press Enter to exit..."
          read
        fi
      '')

      # 2. Web Handler ("axios-flatpak-install")
      # Updated to log errors to /tmp for debugging
      (writeShellScriptBin "axios-flatpak-install" ''
        REF="$1"
        LOG="/tmp/axios-flatpak-install.log"
        
        echo "$(date): Received request for $REF" >> "$LOG"

        # Launch 'foot'
        ${pkgs.foot}/bin/foot \
          --title="Axios Installer" \
          --window-size-chars=100x20 \
          -- \
          sh -c "echo 'Target: $REF'; \
                 echo '-----------------------------------'; \
                 flatpak install --user --from '$REF'; \
                 EXIT_CODE=\$?; \
                 echo '-----------------------------------'; \
                 if [ \$EXIT_CODE -eq 0 ]; then \
                    echo 'Success! Press Enter to close.'; \
                 else \
                    echo 'Failed! (Code: \$EXIT_CODE)'; \
                    echo 'Check output above.'; \
                 fi; \
                 read" >> "$LOG" 2>&1
      '')

      # 3. Desktop Entry
      (makeDesktopItem {
        name = "axios-flatpak-install";
        desktopName = "Axios Flatpak Installer";
        # Changed %u (URL) to %f (File path) to handle browser downloads correctly
        exec = "axios-flatpak-install %f"; 
        icon = "system-software-install";
        terminal = false; 
        type = "Application";
        mimeTypes = [ 
          "application/vnd.flatpak.ref" 
          "application/vnd.flatpak.repo"
          "x-scheme-handler/flatpak" # Handle flatpak:// URIs too
        ];
        noDisplay = true; 
      })
    ];

    # === MIME Association ===
    xdg.mime.enable = true;
    xdg.mime.defaultApplications = {
      "application/vnd.flatpak.ref" = "axios-flatpak-install.desktop";
      "application/vnd.flatpak.repo" = "axios-flatpak-install.desktop";
      "x-scheme-handler/flatpak" = "axios-flatpak-install.desktop";
    };

    # === Flathub Remote Setup ===
    system.activationScripts.setupFlathubSystem = {
      text = ''
        ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      '';
      deps = [ "etc" ];
    };
  };
}