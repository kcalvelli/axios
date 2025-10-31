# Service Port Reference

All services use port-based access for simplicity and compatibility with Tailscale.

## Current Service Ports

| Service | Port | URL | Notes |
|---------|------|-----|-------|
| **OpenWebUI** | 8080 | `http://edge.taile0fb4.ts.net/` | Main domain via Caddy |
| **Ollama** | 11434 | `http://edge.taile0fb4.ts.net:11434/` | Direct access |
| **Home Assistant** | 8123 | `http://edge.taile0fb4.ts.net:8123/` | When enabled |
| **ntopng** | 3000 | `http://edge.taile0fb4.ts.net:3000/` | When enabled |
| **MQTT** | 1883 | N/A | Localhost only |

## Enabling Services

### OpenWebUI (AI Module)
```nix
modules.ai = true;
```
Access: `http://edge.taile0fb4.ts.net/` (proxied via Caddy)

### Home Assistant
```nix
services.hass.enable = true;
```
Access: `http://edge.taile0fb4.ts.net:8123/`

### ntopng (Network Monitoring)
```nix
services.ntop.enable = true;
```
Access: `http://edge.taile0fb4.ts.net:3000/`

### MQTT Broker
```nix
services.mqtt.enable = true;
```
Access: Localhost only (127.0.0.1:1883)

## Why Port-Based Access?

✅ **Simple** - No path rewriting or subdomain DNS issues  
✅ **Compatible** - Works with all applications regardless of base path support  
✅ **Tailscale-friendly** - No MagicDNS limitations  
✅ **Secure** - Tailscale handles authentication and encryption  
✅ **Flexible** - Each service is independent  

## Adding New Services

1. Configure service to listen on localhost or 0.0.0.0
2. Open firewall port if needed
3. Document port in this file
4. Access via `http://edge.taile0fb4.ts.net:PORT/`

**Exception:** Services that don't support base paths and need clean URLs can use Caddy on the main domain (like OpenWebUI currently does).
