# Enabling Services in axiOS

Services are enabled in your host configuration file (`~/.config/nixos_config/hosts/yourhost.nix`).

## Quick Reference

### AI Services (OpenWebUI + Ollama + Claude)

**In your host config:**
```nix
modules = {
  ai = true;  # Enable AI module
  # ... other modules
};
```

**Access:**
- OpenWebUI: `http://edge.taile0fb4.ts.net/`
- Ollama: `http://edge.taile0fb4.ts.net:11434/`
- Claude: `claude` command in terminal

---

### Home Assistant

**In your host config:**
```nix
extraConfig = {
  services.hass.enable = true;
};
```

**Access:**
- `http://edge.taile0fb4.ts.net:8123/`

**Features:**
- Voice support ready (Wyoming containers disabled by default)
- Matter/Thread support
- Google integrations
- Smart home device support (TP-Link, SmartThings, Tuya, etc.)

---

### ntopng (Network Monitoring)

**In your host config:**
```nix
extraConfig = {
  services.ntop.enable = true;
};
```

**Access:**
- `http://edge.taile0fb4.ts.net:3000/`

**What it does:**
- Network traffic monitoring
- Protocol analysis
- Top talkers and hosts
- Historical data

---

### MQTT Broker

**In your host config:**
```nix
extraConfig = {
  services.mqtt.enable = true;
};
```

**Access:**
- Localhost only: `127.0.0.1:1883`
- Not exposed to network (security)

**Use for:**
- Home automation
- IoT device communication
- Smart home integrations

---

## Complete Example

Here's a full host config with all services enabled:

```nix
# hosts/edge.nix
{ lib, userModulePath, ... }:
{
  hostConfig = {
    hostname = "edge";
    system = "x86_64-linux";
    formFactor = "desktop";
    
    hardware = {
      vendor = "msi";
      cpu = "amd";
      gpu = "amd";
      hasSSD = true;
      isLaptop = false;
    };
    
    # Enable module groups
    modules = {
      system = true;
      desktop = true;
      development = true;
      services = true;      # Required for service modules
      graphics = true;
      networking = true;
      users = true;
      virt = true;
      gaming = true;
      ai = true;            # AI services (OpenWebUI, Ollama, Claude)
    };
    
    # Virtualization
    virt = {
      libvirt.enable = true;
      containers.enable = true;
    };
    
    homeProfile = "workstation";
    userModulePath = userModulePath;
    
    # Enable individual services
    extraConfig = {
      # Home automation
      services.hass.enable = true;
      
      # Network monitoring
      services.ntop.enable = true;
      
      # MQTT broker
      services.mqtt.enable = true;
      
      # System settings
      time.hardwareClockInLocalTime = true;
      boot.lanzaboote.enableSecureBoot = true;
    };
    
    diskConfigPath = ./edge/disks.nix;
  };
}
```

## Applying Changes

After editing your host config:

```bash
cd ~/.config/nixos_config
nix flake update axios  # Pull latest changes
rebuild-switch          # Apply configuration
```

## Checking Service Status

```bash
# Check if a service is running
systemctl status open-webui
systemctl status home-assistant
systemctl status ntopng
systemctl status ollama

# View service logs
journalctl -u open-webui -f
journalctl -u home-assistant -f
```

## Port Reference

See [SERVICE_PORTS.md](./SERVICE_PORTS.md) for complete port listing.

## Module Requirements

- **AI services** require `modules.ai = true`
- **Other services** require `modules.services = true`
- **Services are configured in** `extraConfig` section
