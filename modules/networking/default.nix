{ config, lib, ... }:
let
  cfg = config.axios.networking;
in
{
  imports = [
    ./avahi.nix # Avahi service configuration
    ./samba.nix # Samba service configuration
    ./tailscale.nix # Tailscale service configuration
  ];

  options.axios.networking = {
    backend = lib.mkOption {
      type = lib.types.enum [
        "iwd"
        "wpa_supplicant"
      ];
      default = "iwd";
      description = "WiFi backend for NetworkManager. iwd is recommended for modern hardware and WiFi 6E support. Use wpa_supplicant only for legacy hardware.";
    };
  };

  config = {
    networking = {
      networkmanager = {
        enable = true;
        wifi.backend = cfg.backend;
      };
      useDHCP = false;
      firewall = {
        enable = true;
        allowedTCPPorts = [
          5355
        ];
        allowedUDPPorts = [
          5355
        ];
      };
      wireless.iwd = lib.mkIf (cfg.backend == "iwd") {
        enable = true;
        settings = {
          General = {
            EnableNetworkConfiguration = false; # Let NetworkManager handle this
          };
          Network = {
            EnableIPv6 = true;
            RoutePriorityOffset = 300;
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };
    };

    services = {
      resolved = {
        enable = true;
        llmnr = "resolve";
        dnssec = "allow-downgrade";
        settings.Resolve.MulticastDNS = "no";
      };
      openssh.enable = true;
    };

    systemd = {
      services = {
        wpa_supplicant = lib.mkIf (cfg.backend == "wpa_supplicant") {
          serviceConfig.LogLevelMax = 2;
        };
        NetworkManager-wait-online.enable = false;
        systemd-networkd-wait-online.enable = lib.mkForce false;
      };
    };

    programs.mtr.enable = true;

    # For RTL-SDR
    #hardware.rtl-sdr.enable = true;
  };
}
