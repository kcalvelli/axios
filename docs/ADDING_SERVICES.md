# Adding Services to Caddy

With the subdomain-based architecture, adding new services is straightforward.

## Current Services

- **OpenWebUI**: `http://openwebui.taile0fb4.ts.net/`

## Adding a New Service

### Example: Adding Grafana

1. **Enable the service in your module:**
```nix
services.grafana = {
  enable = true;
  settings.server = {
    http_addr = "127.0.0.1";
    http_port = 3000;
  };
};
```

2. **Add Caddy virtual host:**
```nix
services.caddy.virtualHosts."grafana.${tailnet}" = {
  extraConfig = ''
    reverse_proxy http://127.0.0.1:3000
  '';
};
```

3. **Access at:** `http://grafana.taile0fb4.ts.net/`

## Main Domain

The main domain `http://edge.taile0fb4.ts.net/` is available for:
- A landing page with service links
- Your primary application
- A service dashboard

Example landing page:
```nix
services.caddy.virtualHosts."${domain}.${tailnet}" = {
  extraConfig = ''
    respond "axiOS Services: OpenWebUI (openwebui.taile0fb4.ts.net), Grafana (grafana.taile0fb4.ts.net)" 200
  '';
};
```

## Benefits of Subdomain Architecture

✅ **No path conflicts** - Each service gets its own namespace  
✅ **Clean URLs** - No `/service1/`, `/service2/` prefixes  
✅ **Works with all apps** - Even apps that don't support base paths  
✅ **Easy SSL** - Each subdomain can have its own certificate  
✅ **Simple routing** - Just point subdomain → port

## Tailscale MagicDNS

All `*.taile0fb4.ts.net` subdomains are automatically available via Tailscale MagicDNS:
- No DNS configuration needed
- Accessible from any device on your tailnet
- Automatic HTTPS with Tailscale HTTPS
