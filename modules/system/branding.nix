{
  config,
  lib,
  pkgs,
  ...
}:
{
  # axiOS Branding Configuration
  # Configures system branding to display axiOS identity instead of generic NixOS

  config = lib.mkIf config.axios.system.enable {
    # Set axiOS as the distribution identity
    system.nixos = {
      distroId = "axios";
      distroName = "axiOS";
    };

    # Install axiOS logo to system pixmaps directory
    # This makes it available for desktop environments and applications
    environment.systemPackages = [
      (pkgs.runCommand "axios-branding" { } ''
        mkdir -p $out/share/pixmaps
        cp ${./resources/branding/axios.png} $out/share/pixmaps/axios.png
      '')
    ];

    # Override the LOGO field in /etc/os-release
    # DMS and other desktop components read this to display the OS logo
    # Note: mkAfter only appends; we need to replace the existing LOGO line
    system.activationScripts.axiosBranding = lib.stringAfter [ "etc" ] ''
      ${pkgs.gnused}/bin/sed -i 's/^LOGO=.*/LOGO=axios/' /etc/os-release
    '';
  };
}
