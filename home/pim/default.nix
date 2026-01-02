{
  config,
  lib,
  osConfig,
  ...
}:
{
  imports = [ ./davmail.nix ];

  # Auto-enable DavMail when PIM module is enabled and user wants it
  # Users can explicitly disable with programs.davmail.enable = false
  config = lib.mkIf (osConfig.pim.enable or false) {
    programs.davmail.enable = lib.mkDefault false; # Opt-in by default
  };
}
