{ config, lib, pkgs, ... }:

let
  # Google Drive remote for Documents and Music
  gdriveRemote = "gdrive"; # Google Drive (type: drive)
  syncInterval = "15min";

  rcloneConfigPath = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
  rcloneBin = "${pkgs.rclone}/bin/rclone";
  logDir = "${config.home.homeDirectory}/.local/state/rclone";

  # Common options for all rclone operations
  commonOptions = [
    "--retries"
    "3"
    "--retries-sleep"
    "1m"
    "--config"
    rcloneConfigPath
  ];

  # Google Drive specific options
  gdriveOptions = [
    "--drive-skip-gdocs"
    "--drive-use-trash"
  ];

  # Generate one-way sync service (remote -> local, read-only pull)
  mkCopyService = { name, remote, remoteDir, localDir, extraOptions ? [ ] }:
    let
      serviceName = "gdrive-${name}-sync";
      execCommand = lib.strings.escapeShellArgs (
        [
          rcloneBin
          "sync"
          "${remote}:${remoteDir}"
          "${config.home.homeDirectory}/${localDir}"
          "--log-file"
          "${logDir}/gdrive-${name}.log"
        ] ++ commonOptions ++ extraOptions
      );
    in
    {
      service = {
        "${serviceName}" = {
          Unit = {
            Description = "Rclone one-way sync for Google Drive ${name}";
            After = [ "network-online.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = execCommand;
          };
        };
      };

      timer = {
        "${serviceName}" = {
          Unit = {
            Description = "Timer for Google Drive ${name} sync";
          };
          Timer = {
            OnBootSec = "5min";
            OnUnitActiveSec = syncInterval;
            Persistent = true;
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      };
    };

  # Generate bidirectional sync service
  mkBisyncService = { name, remote, remoteDir, localDir, maxDelete ? "100", extraOptions ? [ ] }:
    let
      serviceName = "gdrive-${name}-sync";
      bisyncOptions = [
        "--resilient"
        "--check-access"
        "--max-delete"
        maxDelete
      ];
      execCommand = lib.strings.escapeShellArgs (
        [
          rcloneBin
          "bisync"
          "${remote}:${remoteDir}"
          "${config.home.homeDirectory}/${localDir}"
          "--log-file"
          "${logDir}/gdrive-${name}.log"
        ] ++ bisyncOptions ++ commonOptions ++ extraOptions
      );
    in
    {
      service = {
        "${serviceName}" = {
          Unit = {
            Description = "Rclone bidirectional sync for Google Drive ${name}";
            After = [ "network-online.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = execCommand;
          };
        };
      };

      timer = {
        "${serviceName}" = {
          Unit = {
            Description = "Timer for Google Drive ${name} sync";
          };
          Timer = {
            OnBootSec = "5min";
            OnUnitActiveSec = syncInterval;
            Persistent = true;
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      };
    };

  # Documents: bidirectional sync with Google Drive
  documentsSync = mkBisyncService {
    name = "documents";
    remote = gdriveRemote;
    remoteDir = "Documents";
    localDir = "Documents";
    maxDelete = "100";
    extraOptions = gdriveOptions;
  };

  # Music: bidirectional sync with Google Drive
  musicSync = mkBisyncService {
    name = "music";
    remote = gdriveRemote;
    remoteDir = "Music";
    localDir = "Music";
    maxDelete = "100";
    extraOptions = gdriveOptions;
  };

in
{
  # Google Drive sync for desktop users
  home.packages = [
    pkgs.rclone

    # Setup helper script (properly in PATH)
    (pkgs.writeShellScriptBin "setup-gdrive-sync" ''
      set -euo pipefail

      echo "=== Google Drive Sync Setup ==="
      echo ""
      echo "This will sync Documents and Music with Google Drive."
      echo "Note: Photos are NOT synced automatically due to Google Photos API restrictions."
      echo "Consider using Google Takeout for manual photo backups."
      echo ""

      # Check for Google Drive remote
      if ! ${rcloneBin} listremotes --config ${rcloneConfigPath} 2>/dev/null | grep -q "^${gdriveRemote}:"; then
        echo "Step 1: Configure rclone for Google Drive"
        echo "------------------------------------------"
        echo "You need to create a remote named '${gdriveRemote}' for Google Drive."
        echo ""
        echo "Instructions:"
        echo "1. Choose 'n' for new remote"
        echo "2. Name it '${gdriveRemote}'"
        echo "3. Choose '22' for Google Drive"
        echo "4. Leave client_id and client_secret blank (press Enter)"
        echo "5. Choose scope '1' (full access to all files)"
        echo "6. Leave root_folder_id blank (press Enter)"
        echo "7. Leave service_account_file blank (press Enter)"
        echo "8. Choose 'n' for advanced config"
        echo "9. Choose 'y' to use auto config (opens browser)"
        echo "10. Authenticate in browser"
        echo "11. Choose 'n' for team drive"
        echo "12. Confirm with 'y'"
        echo "13. Choose 'q' to quit"
        echo ""
        read -p "Press Enter to start rclone config..."
        ${rcloneBin} config
        echo ""
      else
        echo "✓ Google Drive remote '${gdriveRemote}' found"
        echo ""
      fi

      # Initialize bidirectional syncs with --resync
      echo "Step 2: Initialize bidirectional syncs"
      echo "---------------------------------------"
      echo ""
      echo "⚠️  WARNING: BEFORE PROCEEDING ⚠️"
      echo "Bidirectional sync will MERGE both locations."
      echo "If either side is empty, files will be COPIED (not deleted)."
      echo ""
      echo "However, AFTER initial setup, deletions on either side WILL sync."
      echo ""

      for folder in documents music; do
        remote_dir=$(echo "$folder" | sed 's/.*/\u&/')  # Capitalize
        local_dir="${config.home.homeDirectory}/$(echo "$folder" | sed 's/.*/\u&/')"

        echo "Checking $folder..."

        # Count files on both sides
        local_count=$(find "$local_dir" -type f 2>/dev/null | wc -l || echo "0")
        remote_count=$(${rcloneBin} size "${gdriveRemote}:$remote_dir" --config ${rcloneConfigPath} 2>/dev/null | grep "Total objects:" | awk '{print $3}' || echo "0")

        echo "  Local $local_dir: $local_count files"
        echo "  Remote ${gdriveRemote}:$remote_dir: $remote_count files"
        echo ""

        read -p "Initialize $folder sync? This will MERGE both locations. [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Skipping $folder"
          continue
        fi

        echo "Initializing $folder sync..."
        ${rcloneBin} bisync \
          "${gdriveRemote}:$remote_dir" \
          "$local_dir" \
          --resync \
          --create-empty-src-dirs \
          --config ${rcloneConfigPath} \
          --drive-skip-gdocs \
          --drive-use-trash
        echo "✓ $folder initialized"
        echo ""
      done

      echo ""
      echo "Step 3: Enable automatic sync timers"
      echo "-------------------------------------"
      echo ""
      echo "📄 Documents & 🎶 Music: Bidirectional (Google Drive ↔ Local)"
      systemctl --user enable --now gdrive-documents-sync.timer
      systemctl --user enable --now gdrive-music-sync.timer
      echo "✓ Documents and Music sync timers enabled"

      echo ""
      echo "✓ Setup complete!"
      echo ""
      echo "Sync status:"
      systemctl --user list-timers 'gdrive-*'
      echo ""
      echo "View logs: journalctl --user -u 'gdrive-*' -f"
      echo "Manual sync: systemctl --user start gdrive-{documents,music}-sync.service"
    '')
  ];

  # Create log directory
  home.file."${logDir}/.keep".text = "";

  # Merge all services
  systemd.user.services = lib.mkMerge [
    documentsSync.service
    musicSync.service
  ];

  # Merge all timers
  systemd.user.timers = lib.mkMerge [
    documentsSync.timer
    musicSync.timer
  ];
}
