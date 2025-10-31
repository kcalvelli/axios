{ config, lib, ... }:

{
  # AI home-manager configuration is activated when services.ai.enable is true
  imports = lib.optional config.services.ai.enable ./claude-code.nix;
}
