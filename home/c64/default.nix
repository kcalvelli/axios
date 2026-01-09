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

    # Initialize Starship prompt
    ${pkgs.starship}/bin/starship init fish | source

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
        # Disable all default modules to remove hostname/username
        format = """READY.
    $character"""

        [character]
        success_symbol = "█"
        error_symbol = "█"
        vimcmd_symbol = "█"
  '';

  # Ghostty configuration for C64 shell (authentic C64 colors)
  c64GhosttyConfig = pkgs.writeText "c64-ghostty-config" ''
    title = C64 Shell

    background = 3e31a2
    foreground = 7c70da

    palette = 0=#000000
    palette = 1=#ffffff
    palette = 2=#883932
    palette = 3=#67b6bd
    palette = 4=#8b3f96
    palette = 5=#55a049
    palette = 6=#40318d
    palette = 7=#bfce72
    palette = 8=#8b5429
    palette = 9=#574200
    palette = 10=#b86962
    palette = 11=#505050
    palette = 12=#787878
    palette = 13=#94e089
    palette = 14=#7869c4
    palette = 15=#9f9f9f

    font-family = Monospace
    font-size = 12

    window-padding-x = 10
    window-padding-y = 10

    cursor-style = block
    cursor-style-blink = true
  '';

  # Desktop launcher script
  c64ShellLauncher = pkgs.writeShellScriptBin "c64-shell" ''
    # Create temporary XDG config home for isolated C64 Ghostty instance
    C64_XDG_HOME="''${XDG_RUNTIME_DIR:-/tmp}/c64-xdg-config"
    mkdir -p "$C64_XDG_HOME/ghostty"

    # Copy C64 config to proper Ghostty config location
    cp ${c64GhosttyConfig} "$C64_XDG_HOME/ghostty/config"

    # Launch Ghostty with isolated config and Fish shell
    exec env XDG_CONFIG_HOME="$C64_XDG_HOME" ${pkgs.ghostty}/bin/ghostty \
      -e ${pkgs.fish}/bin/fish \
      --init-command="source ${c64FishConfig}; and set -x STARSHIP_CONFIG ${c64StarshipConfig}"
  '';
in
{
  options.programs.c64 = {
    enable = lib.mkEnableOption "Commodore 64 shell experience with authentic colors and font";
  };

  config = lib.mkIf cfg.enable {
    # Install C64 tools and support packages
    home.packages = [
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
      icon = "${config.home.homeDirectory}/.local/share/icons/c64term.png";
      terminal = false;
      categories = [
        "System"
        "TerminalEmulator"
      ];
    };

    # Ensure required programs are available
    programs.fish.enable = lib.mkDefault true;
    programs.starship.enable = lib.mkDefault true;
    programs.ghostty.enable = lib.mkDefault true;
  };
}
