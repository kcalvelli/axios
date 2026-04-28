# Companion Home Module: cairn-companion user configuration
# Imports the cairn-companion home-manager module so users can configure
# services.cairn-companion.* (daemon, CLI, TUI, spokes, channels, persona).
{
  inputs,
  osConfig,
  lib,
  ...
}:
let
  isEnabled = (osConfig.services.companion.enable or false);
in
{
  imports = lib.optional (
    isEnabled && inputs ? cairn-companion
  ) inputs.cairn-companion.homeManagerModules.default;
}
