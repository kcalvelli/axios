{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.c64;

  # Script to generate C64-style boot message with real system info
  c64BootScript = pkgs.writeShellScriptBin "c64-boot-message" ''
    # C64 colors
    BLUE="\033[38;2;62;49;162m"        # C64 blue background equivalent
    LIGHTBLUE="\033[38;2;124;112;218m" # C64 light blue text
    RESET="\033[0m"

    # Get system info (free is in procps, not coreutils)
    TOTAL_RAM=$(${pkgs.procps}/bin/free -h | ${pkgs.gnugrep}/bin/grep "Mem:" | ${pkgs.gawk}/bin/awk '{print $2}')
    AVAILABLE_RAM=$(${pkgs.procps}/bin/free -h | ${pkgs.gnugrep}/bin/grep "Mem:" | ${pkgs.gawk}/bin/awk '{print $7}')

    # Convert to bytes for BASIC BYTES FREE calculation (approximate)
    AVAILABLE_BYTES=$(${pkgs.procps}/bin/free -b | ${pkgs.gnugrep}/bin/grep "Mem:" | ${pkgs.gawk}/bin/awk '{print $7}')

    # Print boot message
    echo -e ""
    echo -e "    **** AXIOS COMMODORE 64 SYSTEM V2 ****"
    echo -e ""
    echo -e " $TOTAL_RAM RAM SYSTEM  $AVAILABLE_BYTES BASIC BYTES FREE"
    echo -e ""
  '';

  # Custom Fish config for C64 shell
  c64FishConfig = pkgs.writeText "c64-config.fish" ''
    # C64 Shell Configuration
    # Disable default greeting (we handle it ourselves)
    set -g fish_greeting

    # Show C64 boot message
    ${c64BootScript}/bin/c64-boot-message

    # C64 color theme (approximating classic blue screen)
    set -g fish_color_normal white
    set -g fish_color_command white --bold
    set -g fish_color_quote green
    set -g fish_color_redirection cyan
    set -g fish_color_end white
    set -g fish_color_error red --bold
    set -g fish_color_param white
    set -g fish_color_comment brblack
    set -g fish_color_match cyan
    set -g fish_color_selection white --background=brblack
    set -g fish_color_search_match --background=brblack
    set -g fish_color_operator cyan
    set -g fish_color_escape magenta
    set -g fish_color_autosuggestion brblack
    set -g fish_pager_color_progress white
    set -g fish_pager_color_prefix cyan
    set -g fish_pager_color_completion white
    set -g fish_pager_color_description brblack
  '';

  # Starship config for C64 shell (minimal, just READY. prompt)
  c64StarshipConfig = pkgs.writeText "c64-starship.toml" ''
    # C64-style minimal prompt
    format = """
    READY.
    $character"""

    [character]
    success_symbol = "█"
    error_symbol = "█"
    vimcmd_symbol = "█"
  '';

  # cool-retro-term configuration for C64 profile
  c64CoolRetroTermConfig = {
    profiles = [
      {
        name = "Commodore 64";
        colorScheme = "Commodore64";
        fontColor = "#7C70DA";
        backgroundColor = "#3E31A2";
        fontName = "COMMODORE_64";
        fontWidth = 1.0;
        fontScaling = 1.0;
        burnIn = 0.45;
        staticNoise = 0.05;
        jitter = 0.11;
        glowingLine = 0.2;
        bloom = 0.4;
        curvature = 0.1;
        screenCurvature = true;
        ambientLight = 0.2;
        saturationColor = 0.0;
        brightness = 0.5;
        rbgShift = 0.0;
        horizontalSync = 0.14;
        flickering = 0.1;
        rasterization = false;
      }
    ];
  };

  # Desktop launcher script
  c64ShellLauncher = pkgs.writeShellScriptBin "c64-shell" ''
    # Launch cool-retro-term with C64 Fish shell configuration
    exec ${pkgs.cool-retro-term}/bin/cool-retro-term \
      -e ${pkgs.fish}/bin/fish \
      --init-command="source ${c64FishConfig}; and set -x STARSHIP_CONFIG ${c64StarshipConfig}"
  '';
in
{
  options.programs.c64 = {
    enable = lib.mkEnableOption "Commodore 64 shell experience with cool-retro-term";
  };

  config = lib.mkIf cfg.enable {
    # Install cool-retro-term and support packages
    home.packages = [
      pkgs.cool-retro-term
      c64BootScript
      c64ShellLauncher
      # C64/Ultimate64 video/audio stream viewer
      inputs.c64-stream-viewer.packages.${pkgs.stdenv.hostPlatform.system}.av
      # Ultimate64 MCP server
      inputs.ultimate64-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Install C64 terminal icon
    home.file.".local/share/icons/c64term.png".source = ./resources/c64term.png;

    # Create desktop launcher
    xdg.desktopEntries.c64-shell = {
      name = "C64 Shell";
      genericName = "Commodore 64 Terminal";
      comment = "Authentic Commodore 64 terminal experience";
      exec = "${c64ShellLauncher}/bin/c64-shell";
      icon = "c64term";
      terminal = false;
      categories = [
        "System"
        "TerminalEmulator"
      ];
    };

    # Ensure Fish is available
    programs.fish.enable = lib.mkDefault true;
    programs.starship.enable = lib.mkDefault true;
  };
}
