{
  lib,
  stdenv,
  makeWrapper,
  ghostty,
  fish,
  starship,
  procps,
  gnugrep,
  gawk,
}:

stdenv.mkDerivation rec {
  pname = "c64-shell";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    ghostty
    fish
    starship
    procps
    gnugrep
    gawk
  ];

  # Script to generate C64-style boot message with real system info
  bootScript = ''
    #!/usr/bin/env bash
    # C64 colors
    BLUE="\033[38;2;62;49;162m"        # C64 blue background equivalent
    LIGHTBLUE="\033[38;2;124;112;218m" # C64 light blue text
    RESET="\033[0m"

    # Get system info (free is in procps, not coreutils)
    TOTAL_RAM=$(${procps}/bin/free -h | ${gnugrep}/bin/grep "Mem:" | ${gawk}/bin/awk '{print $2}')
    AVAILABLE_RAM=$(${procps}/bin/free -h | ${gnugrep}/bin/grep "Mem:" | ${gawk}/bin/awk '{print $7}')

    # Convert to bytes for BASIC BYTES FREE calculation (approximate)
    AVAILABLE_BYTES=$(${procps}/bin/free -b | ${gnugrep}/bin/grep "Mem:" | ${gawk}/bin/awk '{print $7}')

    # Print boot message
    echo -e ""
    echo -e "    **** AXIOS COMMODORE 64 SYSTEM V2 ****"
    echo -e ""
    echo -e " $TOTAL_RAM RAM SYSTEM  $AVAILABLE_BYTES BASIC BYTES FREE"
    echo -e ""
  '';

  # Custom Fish config for C64 shell
  fishConfig = ''
    # C64 Shell Configuration
    # Disable default greeting (we handle it ourselves)
    set -g fish_greeting

    # Show C64 boot message
    c64-boot-message

    # Initialize Starship prompt
    ${starship}/bin/starship init fish | source

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
  starshipConfig = ''
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
  ghosttyConfig = ''
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

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/c64-shell
    mkdir -p $out/share/icons/hicolor/512x512/apps

    # Install icon
    cp ${src}/resources/c64term.png $out/share/icons/hicolor/512x512/apps/c64term.png

    # Install configs
    echo "$fishConfig" > $out/share/c64-shell/config.fish
    echo "$starshipConfig" > $out/share/c64-shell/starship.toml
    echo "$ghosttyConfig" > $out/share/c64-shell/ghostty.conf

    # Install boot script
    echo "$bootScript" > $out/bin/c64-boot-message
    chmod +x $out/bin/c64-boot-message

    # Create launcher script
    cat > $out/bin/c64-shell <<'LAUNCHER_EOF'
    #!/usr/bin/env bash
    # Create temporary XDG config home for isolated C64 Ghostty instance
    C64_XDG_HOME="''${XDG_RUNTIME_DIR:-/tmp}/c64-xdg-config"
    mkdir -p "$C64_XDG_HOME/ghostty"

    # Copy C64 config to proper Ghostty config location
    cp @GHOSTTY_CONFIG@ "$C64_XDG_HOME/ghostty/config"

    # Launch Ghostty with isolated config and Fish shell
    exec env XDG_CONFIG_HOME="$C64_XDG_HOME" @GHOSTTY@ \
      -e @FISH@ \
      --init-command="source @FISH_CONFIG@; and set -x STARSHIP_CONFIG @STARSHIP_CONFIG@"
    LAUNCHER_EOF

    chmod +x $out/bin/c64-shell

    # Substitute paths in launcher
    substituteInPlace $out/bin/c64-shell \
      --replace-fail "@GHOSTTY_CONFIG@" "$out/share/c64-shell/ghostty.conf" \
      --replace-fail "@GHOSTTY@" "${ghostty}/bin/ghostty" \
      --replace-fail "@FISH@" "${fish}/bin/fish" \
      --replace-fail "@FISH_CONFIG@" "$out/share/c64-shell/config.fish" \
      --replace-fail "@STARSHIP_CONFIG@" "$out/share/c64-shell/starship.toml"
  '';

  meta = with lib; {
    description = "Commodore 64 themed terminal shell with authentic colors and C64 development tools";
    homepage = "https://github.com/kcalvelli/axios";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "c64-shell";
  };
}
