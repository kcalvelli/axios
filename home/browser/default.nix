{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  braveExtensions = [
    { id = "ghbmnnjooekpmoecnnnilnnbdlolhkhi"; } # Google Docs Offline
    { id = "nimfmkdcckklbkhjjkmbjfcpaiifgamg"; } # Brave Talk for
    { id = "aomjjfmjlecjafonmbhlgochhaoplhmo"; } # 1Password
    { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; } # Claude
    { id = "bkhaagjahfmjljalopjnoealnfndnagc"; } # Octotree - GitHub code tree
    { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader - dark mode
    { id = "jlmpjdjjbgclbocgajdjefcidcncaied"; } # daily.dev - developer news
    { id = "gppongmhjkpfnbhagpmjfkannfbllamg"; } # Wappalyzer - tech profiler
    { id = "kbfnbcaeplbcioakkpcpgfkobkghlhen"; } # Grammarly - writing assistant
  ];

  braveArgs = [
    "--password-store=detect"
    "--gtk-version=4"
  ];

  # Helper to convert extension list to policy format
  # Brave/Chromium policy format: { "ExtensionSettings": { "<ID>": { "installation_mode": "normal_installed", "update_url": "..." } } }
  extensionPolicy = lib.listToAttrs (
    map (ext: {
      name = ext.id;
      value = {
        installation_mode = "normal_installed";
        update_url = "https://clients2.google.com/service/update2/crx";
      };
    }) braveExtensions
  );
in
{
  programs.brave = {
    enable = true;
    extensions = braveExtensions;
    commandLineArgs = braveArgs;
  };

  # Configure policies for Nightly (extensions)
  xdg.configFile."BraveSoftware/Brave-Browser-Nightly/policies/managed/default.json".text =
    builtins.toJSON
      {
        ExtensionSettings = extensionPolicy;
      };

  home.packages =
    let
      nightly = inputs.brave-browser-previews.packages.${pkgs.system}.brave-nightly;
    in
    [
      # Wrapped Nightly version with flags and Wayland support
      (pkgs.symlinkJoin {
        name = "brave-nightly";
        paths = [ nightly ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/brave-nightly \
            --add-flags "${builtins.concatStringsSep " " braveArgs}" \
            --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
        '';
      })
    ];
}
