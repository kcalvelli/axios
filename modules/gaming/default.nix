{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./vr.nix
  ];

  options.gaming = {
    enable = lib.mkEnableOption "Gaming support with Steam, GameMode, and performance tools";
  };

  config = lib.mkIf config.gaming.enable {
    # === Gaming System Packages ===
    environment.systemPackages = with pkgs; [
      gamescope
      gamemode # Performance optimization for games
      mangohud # Performance overlay
      superTuxKart # Fun racing game
      protonup-ng
    ];

    # === Binary Compatibility for Games ===
    # Many games (especially indie, MonoGame, Unity) ship as native Linux binaries
    # that expect system libraries. nix-ld provides FHS compatibility.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # SDL2 family (used by many indie games and game engines)
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        # Graphics APIs
        libGL
        vulkan-loader
        # X11 (for older games and some engines)
        xorg.libX11
        xorg.libXi
        xorg.libXrandr
        # Audio subsystems
        alsa-lib
        openal
        libpulseaudio
        # Common runtime dependencies
        stdenv.cc.cc
        freetype
        libvorbis
        libogg
        zlib
        # Input devices
        libusb1
      ];
    };

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
  };
}
