# Syncthing XDG Sync Module
# Declarative Syncthing configuration for peer-to-peer XDG directory
# synchronization across axiOS hosts via Tailscale MagicDNS.
{
  config,
  lib,
  ...
}:

let
  cfg = config.axios.syncthing;
  tailscaleDomain = config.networking.tailscale.domain;

  # XDG directory name → subdirectory under $HOME
  xdgDirMap = {
    documents = "Documents";
    music = "Music";
    pictures = "Pictures";
    videos = "Videos";
    downloads = "Downloads";
    templates = "Templates";
    desktop = "Desktop";
    publicshare = "Public";
  };

  supportedXdgNames = lib.attrNames xdgDirMap;

  userHome = "/home/${cfg.user}";

  # Resolve folder path: pathOverride takes precedence, otherwise XDG default
  resolveFolderPath =
    name: folderCfg:
    if folderCfg.pathOverride != null then
      folderCfg.pathOverride
    else
      "${userHome}/${xdgDirMap.${name}}";

  # Resolve device address: explicit addresses > tailscaleName > attr name via MagicDNS
  resolveDeviceAddresses =
    name: deviceCfg:
    if deviceCfg.addresses != null then
      deviceCfg.addresses
    else
      let
        machineName = if deviceCfg.tailscaleName != null then deviceCfg.tailscaleName else name;
      in
      [ "tcp://${machineName}.${tailscaleDomain}:22000" ];

  # Check if any device uses MagicDNS (no explicit addresses)
  anyDeviceUsesMagicDNS = lib.any (name: cfg.devices.${name}.addresses == null) (
    lib.attrNames cfg.devices
  );

  # Device submodule
  deviceModule = lib.types.submodule {
    options = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Syncthing device ID.";
        example = "AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH";
      };

      tailscaleName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Tailscale machine name override. If null, the device attribute name
          is used as the Tailscale machine name for MagicDNS address resolution.
        '';
        example = "google-pixel-10";
      };

      addresses = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = ''
          Explicit Syncthing addresses. If null, the address is derived from the
          Tailscale MagicDNS name (tcp://<name>.<tailnet>:22000).
        '';
        example = [ "tcp://192.168.1.100:22000" ];
      };
    };
  };

  # Folder submodule
  folderModule = lib.types.submodule {
    options = {
      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of device names to share this folder with.";
        example = [
          "laptop"
          "server"
        ];
      };

      pathOverride = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Override the default XDG path for this folder.
          If null, the standard XDG default path is used (e.g., ~/Documents).
        '';
      };

      ignorePatterns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Syncthing ignore patterns for this folder.";
        example = [
          "*.tmp"
          ".DS_Store"
        ];
      };
    };
  };
in
{
  options.axios.syncthing = {
    enable = lib.mkEnableOption "Syncthing XDG directory sync over Tailscale";

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "System user to run Syncthing as. XDG paths are resolved relative to this user's home directory.";
      example = "alice";
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf deviceModule;
      default = { };
      description = ''
        Syncthing peer devices. Attribute names are used as Tailscale machine
        names by default for MagicDNS address resolution.
      '';
    };

    folders = lib.mkOption {
      type = lib.types.attrsOf folderModule;
      default = { };
      description = "XDG directories to sync. Keys must be valid XDG directory names.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.user != null;
        message = ''
          axios.syncthing.user must be set when Syncthing is enabled.

          Example:
            axios.syncthing.user = "alice";
        '';
      }
      {
        assertion = !anyDeviceUsesMagicDNS || tailscaleDomain != null;
        message = ''
          networking.tailscale.domain must be set when Syncthing devices use
          MagicDNS addressing (no explicit 'addresses' override).

          Find your tailnet domain in the Tailscale admin console.
          Example: networking.tailscale.domain = "example-tailnet.ts.net";
        '';
      }
      {
        assertion = lib.all (name: lib.elem name supportedXdgNames) (lib.attrNames cfg.folders);
        message = ''
          axios.syncthing.folders contains invalid XDG directory names.

          Supported names: ${lib.concatStringsSep ", " supportedXdgNames}
        '';
      }
    ];

    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = "users";
      dataDir = userHome;
      configDir = "${userHome}/.config/syncthing";

      overrideDevices = true;
      overrideFolders = true;

      settings = {
        options = {
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1;
        };

        devices = lib.mapAttrs (name: deviceCfg: {
          inherit (deviceCfg) id;
          addresses = resolveDeviceAddresses name deviceCfg;
        }) cfg.devices;

        folders = lib.mapAttrs (name: folderCfg: {
          path = resolveFolderPath name folderCfg;
          devices = folderCfg.devices;
          ignorePerms = false;
        }) cfg.folders;
      };
    };
  };
}
