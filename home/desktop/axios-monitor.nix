{
  inputs,
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
{
  imports = [ inputs.axios-monitor.homeManagerModules.default ];

  config = lib.mkIf (osConfig.modules.desktop or false) {
    programs.axios-monitor = {
      enable = true;

      # Rebuild commands matching fish functions (rebuild-switch and rebuild-boot)
      rebuildCommand = [
        "bash"
        "-c"
        ''
          FLAKE_PATH=''${FLAKE_PATH:-~/.config/nixos_config}
          sudo nixos-rebuild switch --flake "$FLAKE_PATH#$(hostname)" 2>&1
        ''
      ];

      rebuildBootCommand = [
        "bash"
        "-c"
        ''
          FLAKE_PATH=''${FLAKE_PATH:-~/.config/nixos_config}
          sudo nixos-rebuild boot --flake "$FLAKE_PATH#$(hostname)" 2>&1
        ''
      ];

      # axiOS version tracking (instead of nixpkgs)
      localRevisionCommand = [
        "bash"
        "-c"
        ''
          FLAKE_PATH=''${FLAKE_PATH:-~/.config/nixos_config}
          jq -r '.nodes.axios.locked.rev // "N/A"' "$FLAKE_PATH/flake.lock" 2>/dev/null | cut -c 1-7 || echo 'N/A'
        ''
      ];

      remoteRevisionCommand = [
        "bash"
        "-c"
        "git ls-remote https://github.com/kcalvelli/axios.git master 2>/dev/null | cut -c 1-7 || echo 'N/A'"
      ];

      # Standard NixOS system commands (using defaults from fork)
      generationsCommand = [
        "sh"
        "-c"
        "nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l"
      ];

      storeSizeCommand = [
        "sh"
        "-c"
        "du -sh /nix/store 2>/dev/null | cut -f1"
      ];

      gcCommand = [
        "sh"
        "-c"
        "nix-collect-garbage -d 2>&1"
      ];

      # Update interval: 5 minutes for stats, 1 hour for version check
      updateInterval = 300;
    };
  };
}
