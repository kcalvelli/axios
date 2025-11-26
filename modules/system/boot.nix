{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    boot.lanzaboote.enableSecureBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable Lanzaboote secure boot support.
        Should be enabled AFTER initial installation when secure boot keys are set up.
        Fresh installations should leave this disabled until keys are enrolled.
      '';
    };
  };

  config = {
    # Boot configuration
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      tmp.useTmpfs = true; # fewer SSD writes

      # Quiet boot
      kernelParams = [
        "quiet"
        "loglevel=0"
        "splash"
        "systemd.show_status=false"
        "psi=1"
      ];

      # Network & kernel tunables optimized for desktop/development
      kernel.sysctl = {
        # BBR congestion control (modern, efficient)
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";

        # Desktop-appropriate network buffers
        "net.core.rmem_max" = 1048576; # 1MB
        "net.core.wmem_max" = 1048576; # 1MB
        "net.ipv4.tcp_rmem" = "4096  87380  1048576";
        "net.ipv4.tcp_wmem" = "4096  65536  1048576";
        "net.core.netdev_max_backlog" = 1000;

        # TCP Fast Open
        "net.ipv4.tcp_fastopen" = 3;

        # Development workload optimizations
        "fs.inotify.max_user_watches" = 524288; # For IDEs and dev tools
        "vm.swappiness" = 10; # Prefer RAM over swap for better dev performance
        "vm.dirty_ratio" = 3; # Better for SSDs
        "vm.dirty_background_ratio" = 2;
      };

      loader = {
        # Use systemd-boot if secure boot is disabled, otherwise use lanzaboote
        systemd-boot.enable = lib.mkDefault (!config.boot.lanzaboote.enableSecureBoot);
        efi.canTouchEfiVariables = true;
      };

      # Lanzaboote SecureBoot support (disabled by default for fresh installs)
      lanzaboote = lib.mkIf config.boot.lanzaboote.enableSecureBoot {
        enable = true;
        configurationLimit = 5;
        pkiBundle = "/var/lib/sbctl";
      };

      bootspec.enable = true;

      # Enable systemd but keep it quiet
      initrd = {
        systemd.enable = true;
        systemd.tpm2.enable = lib.mkIf (!config.boot.lanzaboote.enableSecureBoot) true;
        verbose = false;
      };

      # Quiet, pretty startup
      plymouth.enable = true;
      consoleLogLevel = 0;
    };

    # Swap configuration
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };
  };
}
