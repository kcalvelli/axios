{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Cairn Branding Configuration
  # Configures system branding to display Cairn identity instead of generic NixOS

  config = lib.mkIf config.cairn.system.enable {
    # Set Cairn as the distribution identity
    system.nixos = {
      distroId = "cairn";
      distroName = "Cairn";
    };

    # Install Cairn logo to system pixmaps directory
    # This makes it available for desktop environments and applications
    environment.systemPackages = [
      (pkgs.runCommand "cairn-branding" { } ''
        mkdir -p $out/share/pixmaps
        cp ${./resources/branding/cairn.png} $out/share/pixmaps/cairn.png
      '')
    ];

    # Override the LOGO field in /etc/os-release
    # DMS and other desktop components read this to display the OS logo
    # Note: mkAfter only appends; we need to replace the existing LOGO line
    system.activationScripts.cairnBranding = lib.stringAfter [ "etc" ] ''
      ${pkgs.gnused}/bin/sed -i 's/^LOGO=.*/LOGO=cairn/' /etc/os-release
    '';
  };
}
