{ pkgs, lib, ... }:
let
  # Import categorized package lists
  packages = import ./packages.nix { inherit pkgs; };
in
{
  # === Gaming System Packages ===
  # Organized by category in packages.nix for easier management
  environment.systemPackages = packages.gaming;

  # === Gaming Programs ===
  programs = {
    # Steam configuration
    # Note: No package override needed - modern Steam FHS includes all standard libraries
    # Only override if you have specific games requiring additional libraries not in FHS
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      protontricks = {
        enable = true;
        package = pkgs.protontricks;
      };

      # Uncomment and add packages ONLY if you encounter specific game issues
      # package = pkgs.steam.override {
      #   extraPkgs = pkgs: with pkgs; [
      #     # Example: keyutils libkrb5  # For games requiring Kerberos auth
      #   ];
      # };
      
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      gamescopeSession.enable = true;
    };

    # GameMode configuration
    gamemode = {
      enable = true;
      settings = {
        general = {
          softrealtime = "auto";
          inhibit_screensaver = 1;
          renice = 5;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          amd_performance_level = "high";
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
