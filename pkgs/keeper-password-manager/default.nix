{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libnotify,
  libsecret,
  libuuid,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "keeper-password-manager";
  version = "17.4.1";

  src = fetchurl {
    url = "https://www.keepersecurity.com/desktop_electron/Linux/repo/deb/keeperpasswordmanager_${version}_amd64.deb";
    hash = "sha256-XPR/pQdP56unn7djbpPy0Dkj+BBW2rfihqCjTd43NGs=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libnotify
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

  # Some dependencies are optional and can be ignored if missing
  # libvips is for image processing (sharp npm module)
  # musl libc is for Alpine Linux builds (not needed on glibc systems)
  autoPatchelfIgnoreMissingDeps = [
    "libvips-cpp.so.42"
    "libc.musl-x86_64.so.1"
    "libpcsclite.so.1" # PC/SC smart card library (optional for WebAuthn)
  ];

  unpackPhase = ''
    runHook preUnpack
    # Use ar+tar to extract without preserving setuid bits
    ar x $src
    tar xf data.tar.xz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/bin
    mkdir -p $out/share
    mkdir -p $out/lib

    # Copy application files
    cp -r usr/lib/keeperpasswordmanager $out/lib/
    cp -r usr/share/* $out/share/

    # Create wrapper script
    makeWrapper $out/lib/keeperpasswordmanager/keeperpasswordmanager \
      $out/bin/keeperpasswordmanager \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --prefix PATH : "${lib.makeBinPath [ xorg.xdpyinfo ]}"

    # Fix desktop file icon path to use absolute path
    substituteInPlace $out/share/applications/keeperpasswordmanager.desktop \
      --replace-fail "Icon=keeperpasswordmanager" "Icon=$out/share/pixmaps/keeperpasswordmanager.png"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Keeper Password Manager - Secure password management and digital vault";
    homepage = "https://www.keepersecurity.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "keeperpasswordmanager";
  };
}
