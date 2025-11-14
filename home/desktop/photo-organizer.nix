{ config, lib, pkgs, ... }:

let
  picturesDir = "${config.home.homeDirectory}/Pictures";
  logDir = "${config.home.homeDirectory}/.local/state/photo-organizer";

  # Script to organize a single photo/video file by EXIF date
  organizeScript = pkgs.writeShellScriptBin "photo-organizer" ''
    set -euo pipefail

    FILE="$1"
    PICTURES_DIR="${picturesDir}"
    LOG_FILE="${logDir}/photo-organizer.log"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
    }

    # Only process files directly in Pictures root (not subdirectories)
    FILE_DIR=$(dirname "$FILE")
    if [ "$FILE_DIR" != "$PICTURES_DIR" ]; then
      exit 0
    fi

    # Skip if file doesn't exist or is a directory
    if [ ! -f "$FILE" ]; then
      exit 0
    fi

    # Get file extension (lowercase)
    EXTENSION="''${FILE##*.}"
    EXTENSION=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

    # Only process image and video files
    case "$EXTENSION" in
      jpg|jpeg|png|gif|bmp|tiff|tif|webp|heic|heif|raw|cr2|nef|arw|\
      mp4|mov|avi|mkv|m4v|mpg|mpeg|wmv|flv|webm|3gp)
        ;;
      *)
        exit 0
        ;;
    esac

    # Try to extract date from EXIF data
    # Preference order: DateTimeOriginal > CreateDate > ModifyDate > FileModifyDate
    DATE=$(${pkgs.exiftool}/bin/exiftool -s -s -s \
      -d "%Y:%m" \
      -DateTimeOriginal \
      -CreateDate \
      -ModifyDate \
      -FileModifyDate \
      "$FILE" 2>/dev/null | head -n 1)

    # Fallback to file modification date if EXIF extraction failed
    if [ -z "$DATE" ]; then
      DATE=$(date -r "$FILE" '+%Y:%m')
      log "No EXIF date for $(basename "$FILE"), using file mtime: $DATE"
    fi

    # Parse YYYY and MM from date
    YEAR=$(echo "$DATE" | cut -d: -f1)
    MONTH=$(echo "$DATE" | cut -d: -f2)

    # Validate date components
    if [ -z "$YEAR" ] || [ -z "$MONTH" ]; then
      log "ERROR: Could not extract date from $(basename "$FILE")"
      exit 1
    fi

    # Create target directory
    TARGET_DIR="$PICTURES_DIR/$YEAR/$MONTH"
    mkdir -p "$TARGET_DIR"

    # Move file to target directory
    BASENAME=$(basename "$FILE")
    TARGET_FILE="$TARGET_DIR/$BASENAME"

    # Handle duplicate filenames by appending a number
    if [ -f "$TARGET_FILE" ]; then
      COUNTER=1
      NAME_WITHOUT_EXT="''${BASENAME%.*}"
      while [ -f "$TARGET_DIR/''${NAME_WITHOUT_EXT}_$COUNTER.$EXTENSION" ]; do
        COUNTER=$((COUNTER + 1))
      done
      TARGET_FILE="$TARGET_DIR/''${NAME_WITHOUT_EXT}_$COUNTER.$EXTENSION"
      log "Duplicate filename, renaming to: $(basename "$TARGET_FILE")"
    fi

    mv "$FILE" "$TARGET_FILE"
    log "Organized: $(basename "$FILE") → $YEAR/$MONTH/"
  '';

  # Watcher service using inotifywait
  watcherScript = pkgs.writeShellScript "photo-organizer-watcher" ''
    set -euo pipefail

    PICTURES_DIR="${picturesDir}"
    LOG_FILE="${logDir}/photo-organizer.log"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
    }

    log "Starting photo organizer watcher on $PICTURES_DIR"

    # Create Pictures directory if it doesn't exist
    mkdir -p "$PICTURES_DIR"

    # Watch for new files (close_write) and moved files (moved_to)
    ${pkgs.inotify-tools}/bin/inotifywait \
      --monitor \
      --event close_write \
      --event moved_to \
      --format '%w%f' \
      "$PICTURES_DIR" | while read -r FILE; do
        log "Detected new file: $(basename "$FILE")"
        ${organizeScript}/bin/photo-organizer "$FILE" || log "ERROR: Failed to organize $(basename "$FILE")"
      done
  '';

in
{
  # Install exiftool and inotify-tools
  home.packages = [
    pkgs.exiftool
    pkgs.inotify-tools
    organizeScript
  ];

  # Create log directory
  home.file."${logDir}/.keep".text = "";

  # Systemd service to watch Pictures directory
  systemd.user.services.photo-organizer = {
    Unit = {
      Description = "Automatic photo/video organizer by EXIF date";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${watcherScript}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
