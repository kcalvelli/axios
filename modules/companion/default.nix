# Companion Module: cairn-companion integration
# Provides system-level concerns (Syncthing memory sync) for cairn-companion.
# User-level configuration (daemon, CLI, TUI, spokes, channels) is handled
# by the home-manager module in home/companion/.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.services.companion;
in
{
  # Import cairn-companion NixOS module (provides services.cairn-companion.sync options)
  imports = [ inputs.cairn-companion.nixosModules.default ];

  options.services.companion = {
    enable = lib.mkEnableOption "cairn-companion (persistent persona wrapper around Claude Code)";
  };
}
