{ pkgs, self, ... }:
{
  # Import necessary modules
  imports = [
    ./local.nix
    ./nix.nix
    ./boot.nix
    ./printing.nix
    ./sound.nix
    ./bluetooth.nix
  ];

  # Apply axios overlay to system pkgs
  nixpkgs.overlays = [ self.overlays.default ];

  # Configure home-manager to use system pkgs (with overlays)
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

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



}
