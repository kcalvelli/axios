{ config, lib, ... }:
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
        useRoutingFeatures = "both"; # Enable both inbound and outbound routing features
        permitCertUid = config.services.caddy.user; # Permit certificate UID for the Caddy user
      };
    };
  };
}
