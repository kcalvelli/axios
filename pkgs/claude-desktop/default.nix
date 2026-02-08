{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  dpkg,
  makeWrapper,
  autoPatchelfHook,
  # Runtime dependencies
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
  # X11 libraries (using new top-level names)
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libxcb,
  libxshmfence,
  ...
}:

let
  pname = "claude-desktop";
  version = "1.0.2768";
  debVersion = "1.2.1";

  src = fetchurl {
    url = "https://github.com/aaddrick/claude-desktop-debian/releases/download/v${debVersion}%2Bclaude${version}/claude-desktop_${version}_amd64.deb";
    sha256 = "sha256-W7e9+1PDXZTDVVtJMAXXOE2WSf6/NohwCmtxtLeNcPo=";
  };

  # Extract and prepare the debian package
  claude-unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version src;

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      makeWrapper
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
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      libxcb
      libxshmfence
    ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      # Copy application files from usr/lib
      mkdir -p $out/lib
      cp -r usr/lib/claude-desktop $out/lib/

      # Copy the launcher script
      mkdir -p $out/bin
      cp usr/bin/claude-desktop $out/bin/

      # Make the launcher executable
      chmod +x $out/bin/claude-desktop

      # Patch the launcher script to use nix store paths
      substituteInPlace $out/bin/claude-desktop \
        --replace-fail '/usr/lib/claude-desktop' "$out/lib/claude-desktop"

      # Copy desktop file and icons if they exist
      mkdir -p $out/share
      if [ -d usr/share/applications ]; then
        cp -r usr/share/applications $out/share/
      fi
      if [ -d usr/share/icons ]; then
        cp -r usr/share/icons $out/share/
      fi
      if [ -d usr/share/pixmaps ]; then
        cp -r usr/share/pixmaps $out/share/
      fi

      # Fix desktop file to point to nix store
      if [ -f $out/share/applications/claude-desktop.desktop ]; then
        substituteInPlace $out/share/applications/claude-desktop.desktop \
          --replace-quiet '/usr/bin/claude-desktop' "$out/bin/claude-desktop" \
          --replace-quiet '/usr/lib/claude-desktop' "$out/lib/claude-desktop"
      fi

      runHook postInstall
    '';

    meta = with lib; {
      description = "Claude Desktop - Unofficial Linux build based on claude-desktop-debian";
      longDescription = ''
        Claude Desktop application for Linux, packaged from the claude-desktop-debian project.
        This is an unofficial build that wraps Anthropic's Windows release for Linux.

        Note: This requires unfree software (Claude Desktop is proprietary).
      '';
      homepage = "https://claude.ai";
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
    };
  };

  # FHS environment wrapper for MCP server support and better compatibility
  claude-fhs = buildFHSEnv {
    name = "claude-desktop";
    inherit (claude-unwrapped) meta;

    targetPkgs =
      pkgs: with pkgs; [
        claude-unwrapped

        # Additional runtime dependencies for MCP servers
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

    runScript = "${claude-unwrapped}/bin/claude-desktop";

    extraInstallCommands = ''
      # Copy desktop file and icons from unwrapped package
      mkdir -p $out/share/applications
      if [ -f ${claude-unwrapped}/share/applications/claude-desktop.desktop ]; then
        cp ${claude-unwrapped}/share/applications/claude-desktop.desktop $out/share/applications/
      fi

      # Copy icons
      for dir in ${claude-unwrapped}/share/icons ${claude-unwrapped}/share/pixmaps; do
        if [ -d "$dir" ]; then
          cp -r "$dir" $out/share/ || true
        fi
      done
    '';
  };

  # Wayland wrapper for the FHS environment
  claude-wayland = stdenv.mkDerivation {
    pname = "claude-desktop-wayland";
    inherit version;

    nativeBuildInputs = [ makeWrapper ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin

      # Wayland variant with flags
      makeWrapper ${claude-fhs}/bin/claude-desktop $out/bin/claude-desktop \
        --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
        --add-flags "--ozone-platform=wayland"

      # XWayland fallback
      ln -s ${claude-fhs}/bin/claude-desktop $out/bin/claude-desktop-xwayland

      # Copy desktop file and update it
      mkdir -p $out/share/applications
      if [ -f ${claude-fhs}/share/applications/claude-desktop.desktop ]; then
        cp ${claude-fhs}/share/applications/claude-desktop.desktop $out/share/applications/
        substituteInPlace $out/share/applications/claude-desktop.desktop \
          --replace-quiet "${claude-fhs}/bin/claude-desktop" "$out/bin/claude-desktop" \
          --replace-quiet "${claude-unwrapped}/bin/claude-desktop" "$out/bin/claude-desktop"
      fi

      # Copy icons
      for dir in ${claude-fhs}/share/icons ${claude-fhs}/share/pixmaps; do
        if [ -d "$dir" ]; then
          cp -r "$dir" $out/share/ || true
        fi
      done
    '';

    meta = claude-unwrapped.meta;
  };

in
# Export Wayland wrapper by default (best compatibility)
# Access other variants: pkgs.claude-desktop.unwrapped, pkgs.claude-desktop.fhs
claude-wayland
// {
  unwrapped = claude-unwrapped;
  fhs = claude-fhs;

  # Convenience passthru for version info
  passthru = {
    inherit version debVersion;
    updateScript = lib.warn "No automatic update script available - check https://github.com/aaddrick/claude-desktop-debian/releases" null;
  };
}
