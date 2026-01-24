{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  dpkg,
  makeWrapper,
  autoPatchelfHook,
  binutils,
  gnutar,
  zstd,
  imagemagick,
  # Runtime dependencies (Electron app)
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libdrm,
  libnotify,
  libpulseaudio,
  libsecret,
  libuuid,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
  # MCP runtime dependencies
  nodejs,
  python3,
  git,
  ...
}:

let
  pname = "goose-desktop";
  version = "1.21.1";

  src = fetchurl {
    url = "https://github.com/block/goose/releases/download/v${version}/goose_${version}_amd64.deb";
    sha256 = "sha256-eUEbRTtpJgq21NYA9kY/M3qdNZ76pnBSK0opu3CGPOM=";
  };

  # Extract and prepare the debian package
  goose-unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version src;

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      makeWrapper
      binutils # for ar
      gnutar
      zstd # data.tar is zstd compressed
      imagemagick # for icon generation
    ];

    buildInputs = [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libappindicator-gtk3
      libdrm
      libnotify
      libpulseaudio
      libsecret
      libuuid
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence
    ];

    unpackPhase = ''
      runHook preUnpack
      # Use ar + tar to extract, ignoring permission errors on chrome-sandbox
      ar x $src
      tar xf data.tar.* --no-same-permissions --no-same-owner || true
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      # Copy application files from usr/lib/goose
      mkdir -p $out/lib
      cp -r usr/lib/goose $out/lib/

      # Create launcher script (the original is a symlink to Goose binary)
      mkdir -p $out/bin
      cat > $out/bin/goose-desktop << EOF
      #!/bin/sh
      exec "$out/lib/goose/Goose" "\$@"
      EOF
      chmod +x $out/bin/goose-desktop

      # Copy desktop file and icons
      mkdir -p $out/share/applications
      cp usr/share/applications/goose.desktop $out/share/applications/goose-desktop.desktop

      mkdir -p $out/share/pixmaps
      cp usr/share/pixmaps/goose.png $out/share/pixmaps/goose-desktop.png

      # Install SVG icon (scalable)
      mkdir -p $out/share/icons/hicolor/scalable/apps
      cp usr/lib/goose/resources/images/icon.svg $out/share/icons/hicolor/scalable/apps/goose-desktop.svg

      # Generate multiple icon sizes from SVG for dock/panel compatibility
      for size in 16 24 32 48 64 128 256 512; do
        mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
        magick usr/lib/goose/resources/images/icon.svg -resize ''${size}x''${size} \
          $out/share/icons/hicolor/''${size}x''${size}/apps/goose-desktop.png
      done

      # Fix desktop file paths
      substituteInPlace $out/share/applications/goose-desktop.desktop \
        --replace-warn 'Exec=/usr/lib/goose/Goose' "Exec=$out/bin/goose-desktop" \
        --replace-warn 'Icon=/usr/share/pixmaps/goose.png' "Icon=goose-desktop"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Goose Desktop - Block's open-source AI agent desktop application";
      longDescription = ''
        Goose is an open-source, extensible AI agent that goes beyond code suggestions.
        It can install, execute, edit, and test with any LLM provider.

        Features:
        - Multi-provider support (Claude, GPT, Ollama, etc.)
        - Native MCP (Model Context Protocol) integration
        - Autonomous task execution
        - Extension system for custom tools
      '';
      homepage = "https://block.github.io/goose/";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };

  # FHS environment wrapper for MCP server support
  goose-fhs = buildFHSEnv {
    name = "goose-desktop";
    inherit (goose-unwrapped) meta;

    targetPkgs =
      pkgs: with pkgs; [
        goose-unwrapped

        # MCP server runtime dependencies
        nodejs
        python3
        git

        # Common utilities MCP servers might need
        curl
        wget
        jq

        # For potential native extensions
        gcc
        gnumake
      ];

    runScript = "${goose-unwrapped}/bin/goose-desktop";

    extraInstallCommands = ''
      # Copy desktop file and icons from unwrapped package
      mkdir -p $out/share/applications
      for desktop in ${goose-unwrapped}/share/applications/*.desktop; do
        if [ -f "$desktop" ]; then
          cp "$desktop" $out/share/applications/
        fi
      done

      # Copy icons
      for dir in ${goose-unwrapped}/share/icons ${goose-unwrapped}/share/pixmaps; do
        if [ -d "$dir" ]; then
          cp -r "$dir" $out/share/ || true
        fi
      done
    '';
  };

  # Wayland wrapper
  goose-wayland = stdenv.mkDerivation {
    pname = "goose-desktop-wayland";
    inherit version;

    nativeBuildInputs = [ makeWrapper ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin

      # Wayland variant with Ozone flags
      makeWrapper ${goose-fhs}/bin/goose-desktop $out/bin/goose-desktop \
        --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
        --add-flags "--ozone-platform=wayland"

      # XWayland fallback
      ln -s ${goose-fhs}/bin/goose-desktop $out/bin/goose-desktop-xwayland

      # Copy desktop file and update it
      mkdir -p $out/share/applications
      for desktop in ${goose-fhs}/share/applications/*.desktop; do
        if [ -f "$desktop" ]; then
          cp "$desktop" $out/share/applications/
          basename=$(basename "$desktop")
          substituteInPlace "$out/share/applications/$basename" \
            --replace-quiet "${goose-fhs}/bin/goose-desktop" "$out/bin/goose-desktop" \
            --replace-quiet "${goose-unwrapped}/bin/goose-desktop" "$out/bin/goose-desktop"
        fi
      done

      # Copy icons
      for dir in ${goose-fhs}/share/icons ${goose-fhs}/share/pixmaps; do
        if [ -d "$dir" ]; then
          cp -r "$dir" $out/share/ || true
        fi
      done
    '';

    meta = goose-unwrapped.meta;
  };

in
# Export Wayland wrapper by default
goose-wayland
// {
  unwrapped = goose-unwrapped;
  fhs = goose-fhs;

  passthru = {
    inherit version;
    updateScript = lib.warn "Check https://github.com/block/goose/releases for updates" null;
  };
}
