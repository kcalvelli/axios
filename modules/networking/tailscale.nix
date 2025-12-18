{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.tailscale;
in
{
  options.networking.tailscale = {
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "tail1234ab.ts.net";
      description = ''
        The Tailscale MagicDNS domain for this tailnet.
        Used for service routing and reverse proxy configuration.
        Find your tailnet domain in the Tailscale admin console under DNS settings.
      '';
    };

    operator = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "wheel";
      description = ''
        Group or user that can operate Tailscale without root privileges.
        Common values: "wheel" (admin group), username (single user), or null (root only).
        If null, only root can manage Tailscale.
      '';
    };
  };

  config = {
    # Configure firewall settings for Tailscale
    networking = {
      firewall = {
        trustedInterfaces = [ config.services.tailscale.interfaceName ]; # Allow Tailscale interface through the firewall
        allowedUDPPorts = [ config.services.tailscale.port ]; # Allow UDP ports used by Tailscale
      };
    };

    # Enable and configure Tailscale service
    services = {
      tailscale = {
        enable = true; # Enable Tailscale service
        openFirewall = true;
        extraSetFlags = lib.optional (cfg.operator != null) "--operator=${cfg.operator}";
        useRoutingFeatures = "both"; # Enable both inbound and outbound routing features
        # Note: Caddy integration (permitCertUid) is configured in services/caddy.nix
        # This allows Tailscale to work independently without requiring Caddy
      };
    };
    environment = {
      systemPackages = with pkgs; [ trayscale ];
    };
  };
}
