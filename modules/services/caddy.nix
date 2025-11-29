# Caddy Reverse Proxy with Tailscale HTTPS
# Provides automatic HTTPS certificates from Tailscale for self-hosted services
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.selfHosted;
  tailscaleDomain = config.networking.tailscale.domain;
in
{
  options.selfHosted.caddy = {
    routes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            domain = lib.mkOption {
              type = lib.types.str;
              description = ''
                Domain for this route (e.g., hostname.tailscale.domain).
                Multiple routes can share the same domain.
              '';
            };

            path = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/llama/*";
              description = ''
                Path prefix for this route. If null, this is a catch-all handler.
                Path-specific routes are automatically ordered before catch-all routes.
              '';
            };

            target = lib.mkOption {
              type = lib.types.str;
              example = "http://127.0.0.1:8081";
              description = "Upstream target for reverse proxy";
            };

            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Additional Caddy configuration for this route handler";
            };

            priority = lib.mkOption {
              type = lib.types.int;
              default = if path == null then 1000 else 100;
              description = ''
                Route priority. Lower numbers are evaluated first.
                Default: 100 for path-specific routes, 1000 for catch-all.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Route registry for reverse proxy handlers.
        Services register their routes here, and Caddy config is generated
        with proper ordering (path-specific routes before catch-all routes).
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Additional Caddyfile configuration to append.
        Use this for custom reverse proxy entries not using the route registry.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = tailscaleDomain != null;
        message = ''
          selfHosted requires networking.tailscale.domain to be set.

          Find your tailnet domain in the Tailscale admin console under DNS settings.
          Example: networking.tailscale.domain = "tail1234ab.ts.net";
        '';
      }
    ];

    services.caddy =
      let
        # Generate Caddy config from route registry
        routes = lib.attrValues cfg.caddy.routes;

        # Group routes by domain
        routesByDomain = lib.groupBy (r: r.domain) routes;

        # Generate handle block for a single route
        mkHandle =
          route:
          if route.path != null then
            ''
              handle ${route.path} {
                reverse_proxy ${route.target}
                ${route.extraConfig}
              }
            ''
          else
            ''
              handle {
                reverse_proxy ${route.target}
                ${route.extraConfig}
              }
            '';

        # Generate domain block with sorted routes
        mkDomainBlock =
          domain: domainRoutes:
          let
            # Sort routes by priority (lower = first)
            sortedRoutes = lib.sort (a: b: a.priority < b.priority) domainRoutes;
          in
          ''
            ${domain} {
              ${lib.concatMapStrings mkHandle sortedRoutes}
            }
          '';

        # Generate all domain blocks
        generatedConfig = lib.concatStrings (lib.mapAttrsToList mkDomainBlock routesByDomain);
      in
      {
        # Global Caddy settings
        globalConfig = ''
          # Use Tailscale for HTTPS certificates
          # Caddy automatically gets certs from local Tailscale daemon for *.ts.net domains
        '';

        # Generated config from route registry + additional extraConfig
        extraConfig = generatedConfig + cfg.caddy.extraConfig;
      };
  };
}
