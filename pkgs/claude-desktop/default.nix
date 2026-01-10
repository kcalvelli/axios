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
  xorg,
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

    runScript = "claude-desktop";

    extraInstallCommands = ''
      # Copy desktop file from unwrapped package
      mkdir -p $out/share/applications
      if [ -f ${claude-unwrapped}/share/applications/claude-desktop.desktop ]; then
        cp ${claude-unwrapped}/share/applications/claude-desktop.desktop $out/share/applications/

        # Update exec path to use FHS wrapper
        substituteInPlace $out/share/applications/claude-desktop.desktop \
          --replace-fail "${claude-unwrapped}/bin/claude-desktop" "$out/bin/claude-desktop"
      fi

      # Copy icons
      for dir in ${claude-unwrapped}/share/icons ${claude-unwrapped}/share/pixmaps; do
        if [ -d "$dir" ]; then
          cp -r "$dir" $out/share/ || true
        fi
      done
    '';
  };

in
# Export both variants
# Default export is FHS wrapper (better MCP compatibility)
# Access unwrapped with: pkgs.claude-desktop.unwrapped
claude-fhs
// {
  unwrapped = claude-unwrapped;

  # Convenience passthru for version info
  passthru = {
    inherit version debVersion;
    updateScript = lib.warn "No automatic update script available - check https://github.com/aaddrick/claude-desktop-debian/releases" null;
  };
}
