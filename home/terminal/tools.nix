{
  pkgs,
  ...
}:
{
  # CLI helper programs
  programs = {
    eza = {
      enable = true;
      git = true;
      icons = "auto";
      enableFishIntegration = true;
      enableBashIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    ripgrep.enable = true;
    fd.enable = true;
    fzf.enable = true;
    gh.enable = true;
    zoxide.enable = true;

    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
    ];
  };
}
