{ config, lib, ... }:
let
  cfg = config.axios.networking.avahi;
  sambaCfg = config.networking.samba;
in
{
  options.axios.networking.avahi = {
    enable = lib.mkEnableOption "Avahi mDNS/DNS-SD service discovery" // {
      default = sambaCfg.enable or false;
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "Avahi mDNS/DNS-SD service discovery for local network auto-discovery";
      description = ''
        Avahi provides mDNS/DNS-SD service discovery, allowing devices on the local network
        to automatically discover services like Samba file shares.

        When enabled, broadcasts:
        - Hostname resolution via .local domain
        - Samba/SMB service advertisement (if Samba is enabled)

        Defaults to enabled when Samba is enabled, disabled otherwise.
        Disable to reduce network noise if you don't need auto-discovery.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Avahi networking configuration
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
      };
    };
  };
}
