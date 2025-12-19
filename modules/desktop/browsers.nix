{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  braveExtensionIds = [
    "ghbmnnjooekpmoecnnnilnnbdlolhkhi" # Google Docs Offline
    "nimfmkdcckklbkhjjkmbjfcpaiifgamg" # Brave Talk
    "aomjjfmjlecjafonmbhlgochhaoplhmo" # 1Password
    "fcoeoabgfenejglbffodgkkbkcdhcgfn" # Claude
    "bkhaagjahfmjljalopjnoealnfndnagc" # Octotree - GitHub code tree
    "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader - dark mode
  ];

  braveArgs = [
    "--password-store=detect"
    "--gtk-version=4"
  ];
in
{
  # Import NixOS module from flake
  imports = [ inputs.brave-browser-previews.nixosModules.default ];

  config = lib.mkIf config.desktop.enable {
    # === Brave Nightly Configuration (System) ===
    programs.brave-nightly = {
      enable = true;
      extensions = braveExtensionIds;
      commandLineArgs = braveArgs;
    };

    # === Brave Stable Configuration (Home Manager) ===
    home-manager.sharedModules = [
      (
        { pkgs, ... }:
        {
          programs.brave = {
            enable = true;
            extensions = map (id: { inherit id; }) braveExtensionIds;
            commandLineArgs = braveArgs;
          };
        }
      )
    ];
  };
}
