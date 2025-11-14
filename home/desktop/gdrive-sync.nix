{ config, lib, pkgs, ... }:

let
  remoteName = "gdrive";
  syncInterval = "15min";

  rcloneConfigPath = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
  rcloneBin = "${pkgs.rclone}/bin/rclone";
  logDir = "${config.home.homeDirectory}/.local/state/rclone";

  # Common options for all rclone operations
  commonOptions = [
    "--retries" "3"
    "--retries-sleep" "1m"
    "--drive-skip-gdocs"
    "--drive-use-trash"
    "--config" rcloneConfigPath
  ];

  # Generate one-way sync service (remote -> local, read-only pull)
  mkCopyService = { name, remoteDir, localDir }:
    let
      serviceName = "gdrive-${name}-sync";
      execCommand = lib.strings.escapeShellArgs (
        [
          rcloneBin
          "sync"
          "${remoteName}:${remoteDir}"
          "${config.home.homeDirectory}/${localDir}"
          "--log-file" "${logDir}/gdrive-${name}.log"
        ] ++ commonOptions
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
  mkBisyncService = { name, remoteDir, localDir, maxDelete ? "50%" }:
    let
      serviceName = "gdrive-${name}-sync";
      bisyncOptions = [
        "--resilient"
        "--check-access"
        "--max-delete" maxDelete
      ];
      execCommand = lib.strings.escapeShellArgs (
        [
          rcloneBin
          "bisync"
          "${remoteName}:${remoteDir}"
          "${config.home.homeDirectory}/${localDir}"
          "--log-file" "${logDir}/gdrive-${name}.log"
        ] ++ bisyncOptions ++ commonOptions
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

  # Pictures: one-way pull only
  picturesSync = mkCopyService {
    name = "pictures";
    remoteDir = "Photos";
    localDir = "Pictures";
  };

  # Documents: bidirectional sync
  documentsSync = mkBisyncService {
    name = "documents";
    remoteDir = "Documents";
    localDir = "Documents";
    maxDelete = "50%";
  };

  # Music: bidirectional sync
  musicSync = mkBisyncService {
    name = "music";
    remoteDir = "Music";
    localDir = "Music";
    maxDelete = "50%";
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

      # Check if rclone config exists
      if [ ! -f "${rcloneConfigPath}" ]; then
        echo "Step 1: Configure rclone for Google Drive"
        echo "----------------------------------------"
        echo "1. Choose 'n' for new remote"
        echo "2. Name it '${remoteName}'"
        echo "3. Choose 'drive' (Google Drive)"
        echo "4. Leave client_id and client_secret blank"
        echo "5. Choose scope '1' (full access)"
        echo "6. Leave root_folder_id blank"
        echo "7. Leave service_account_file blank"
        echo "8. Choose 'n' for advanced config"
        echo "9. Choose 'y' to use auto config (opens browser)"
        echo "10. Choose 'n' for team drive"
        echo ""
        read -p "Press Enter to start rclone config..."
        ${rcloneBin} config
        echo ""
      else
        echo "✓ Rclone config found at ${rcloneConfigPath}"
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
        remote_count=$(${rcloneBin} size "${remoteName}:$remote_dir" --config ${rcloneConfigPath} 2>/dev/null | grep "Total objects:" | awk '{print $3}' || echo "0")

        echo "  Local $local_dir: $local_count files"
        echo "  Remote ${remoteName}:$remote_dir: $remote_count files"
        echo ""

        read -p "Initialize $folder sync? This will MERGE both locations. [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Skipping $folder"
          continue
        fi

        echo "Initializing $folder sync..."
        ${rcloneBin} bisync \
          "${remoteName}:$remote_dir" \
          "$local_dir" \
          --resync \
          --create-empty-src-dirs \
          --config ${rcloneConfigPath}
        echo "✓ $folder initialized"
        echo ""
      done

      echo ""
      echo "Step 3: Enable automatic sync timers"
      echo "-------------------------------------"
      echo ""
      echo "📸 Pictures: One-way sync (Google Drive → Local, read-only, safe)"
      systemctl --user enable --now gdrive-pictures-sync.timer
      echo "✓ Pictures sync timer enabled"
      echo ""
      echo "📄 Documents & 🎶 Music: Bidirectional (changes sync both ways)"
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
      echo "Manual sync: systemctl --user start gdrive-{pictures,documents,music}-sync.service"
    '')
  ];

  # Create log directory
  home.file."${logDir}/.keep".text = "";

  # Merge all services
  systemd.user.services = lib.mkMerge [
    picturesSync.service
    documentsSync.service
    musicSync.service
  ];

  # Merge all timers
  systemd.user.timers = lib.mkMerge [
    picturesSync.timer
    documentsSync.timer
    musicSync.timer
  ];
}
