{ pkgs, ... }:
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
in
{
  programs.brave = {
    enable = true;
    extensions = braveExtensions;
    commandLineArgs = braveArgs;
  };
}
