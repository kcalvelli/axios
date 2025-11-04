{ config, lib, ... }:
let
  cfg = config.services.hass;
in
{
  options.services.hass = {
    enable = lib.mkEnableOption "Home Assistant with voice support (port 8123)";
  };

  config = lib.mkIf cfg.enable (
    let
      haComponents = [
        "default_config"
        "frontend"
        "conversation"
        "media_source"
        "assist_pipeline"
        "mqtt"
        "matter"
        "thread"
        "tts"
        "google_translate"
        "ffmpeg"
        "cast"
        "wyoming"
        "tplink"
        "smartthings"
        "tuya"
        "rachio"
        "homekit"
        "homekit_controller"
        "sonos"
        "google"
        "google_photos"
        "google_maps"
      ];
    in
    {
      services.home-assistant = {
        enable = true;
        # Open port 8123 for direct access
        openFirewall = true;
        extraComponents = haComponents;
        config = {
          homeassistant = { };
          http = { }; # Removed proxy config since we're using direct access
          default_config = { };
          frontend = { };
          conversation = { };
          media_source = { };
          tts = [{
            platform = "google_translate";
            language = "en";
            cache = true;
            time_memory = 300;
            service_name = "google_say";
          }];
        };
      };

      # Enable related services
      services.matter-server.enable = true;

      # Let HA hear mDNS and SSDP broadcasts
      networking.firewall.allowedUDPPorts = [ 5353 1900 ];

      #############################
      # Wyoming Voice (disabled by default)
      #############################
      #virtualisation.oci-containers.containers = {
      #  wyoming-whisper = {
      #    image = "rhasspy/wyoming-whisper:latest";
      #    autoStart = true;
      #    ports = [ "127.0.0.1:10300:10300" ];
      #    volumes = [
      #      "/var/lib/wyoming/whisper:/data"
      #      "/var/cache/wyoming/hf:/root/.cache/huggingface"
      #    ];
      #    cmd = [ "--model" "small-int8" "--language" "en" ];
      #  };
      #
      #  wyoming-piper = {
      #    image = "rhasspy/wyoming-piper:latest";
      #    autoStart = true;
      #    ports = [ "127.0.0.1:10200:10200" ];
      #    volumes = [ "/var/lib/wyoming/piper:/data" ];
      #    cmd = [ "--voice" "en_US-lessac-medium" ];
      #  };
      #
      #  wyoming-openwakeword = {
      #    image = "rhasspy/wyoming-openwakeword:latest";
      #    autoStart = true;
      #    ports = [ "127.0.0.1:10400:10400" ];
      #    cmd = [ "--preload-model" "ok_nabu" ];
      #    volumes = [ "/var/lib/wyoming/openwakeword:/data" ];
      #    extraOptions = [ "--pull=always" ];
      #  };
      #};
    }
  );
}
