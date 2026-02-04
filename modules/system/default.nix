{
  config,
  lib,
  pkgs,
  self,
  inputs,
  ...
}:
{
  options.axios.system = {
    enable = lib.mkEnableOption "core axiOS system configuration" // {
      default = true;
    };
  };

  # Import necessary modules (must be at top level to register options)
  imports = [
    ./branding.nix
    ./locale.nix
    ./nix.nix
    ./boot.nix
    ./memory.nix
    ./printing.nix
    ./sound.nix
    ./bluetooth.nix
  ];

  config = lib.mkIf config.axios.system.enable {
    # Apply overlays to system pkgs (makes packages available to home-manager via useGlobalPkgs)
    nixpkgs.overlays = [
      self.overlays.default
      # mcp-servers-nix overlay provides pre-built MCP servers (mcp-server-git, etc.)
      inputs.mcp-servers-nix.overlays.default
      # mcp-gateway overlay provides the gateway package
      inputs.mcp-gateway.overlays.default
    ];

    # Configure home-manager to use system pkgs (with overlays)
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    # NOTE: External home-manager modules (dankMaterialShell, niri) may set
    # nixpkgs.config or nixpkgs.overlays, which triggers a deprecation warning when
    # useGlobalPkgs = true. This is a known issue and will be fixed in future versions
    # of those modules. The warning is harmless and can be safely ignored.

    # === System Packages ===
    environment.systemPackages = with pkgs; [
      # Core system utilities
      killall
      wget
      curl

      # Filesystem and mount tools
      sshfs
      fuse
      ntfs3g

      # System monitoring and information
      pciutils
      wirelesstools
      gtop
      htop
      lm_sensors
      smartmontools

      # Archive and compression tools
      p7zip
      unzip
      unrar
      xarchiver

      # Security and secret management
      libsecret
      lssecret
      openssl

      # Nix ecosystem tools
      fh # Flake helper CLI
    ];

    # Build smaller systems
    documentation.enable = false;
    documentation.nixos.enable = false;
    documentation.dev.enable = false;
    programs.command-not-found.enable = false;
    programs.vim = {
      enable = true;
      package = (pkgs.vim.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          rm -f $out/share/applications/gvim.desktop
        '';
      }));
      defaultEditor = true;
    };
  };
}
