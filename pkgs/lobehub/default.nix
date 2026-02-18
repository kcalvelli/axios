{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

let
  pname = "lobehub";
  version = "2.1.23";

  src = fetchurl {
    url = "https://github.com/lobehub/lobehub/releases/download/v${version}/LobeHub-${version}.AppImage";
    sha256 = "sha256-2u4Qg+EyBYcbwrKXYhnIi1u9VBk9rt7q/FxIvNllCg0=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Install desktop entry
    install -Dm644 ${appimageContents}/lobehub.desktop $out/share/applications/lobehub.desktop

    # Fix desktop entry paths
    substituteInPlace $out/share/applications/lobehub.desktop \
      --replace-quiet 'Exec=AppRun' "Exec=$out/bin/lobehub" \
      --replace-quiet 'Exec=lobehub' "Exec=$out/bin/lobehub"

    # Install icons
    for size in 16 32 48 64 128 256 512 1024; do
      icon="${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/lobehub.png"
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" "$out/share/icons/hicolor/''${size}x''${size}/apps/lobehub.png"
      fi
    done

    # Fallback: install any icon found
    if [ ! -d "$out/share/icons" ]; then
      for icon in ${appimageContents}/lobehub.png ${appimageContents}/.DirIcon; do
        if [ -f "$icon" ]; then
          install -Dm644 "$icon" "$out/share/icons/hicolor/256x256/apps/lobehub.png"
          break
        fi
      done
    fi

    # Wrap with Wayland flags for Niri compositor
    source ${makeWrapper}/nix-support/setup-hook
    wrapProgram $out/bin/lobehub \
      --add-flags "--ozone-platform=wayland" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
  '';

  meta = with lib; {
    description = "Open-source AI chat UI and model hub for local and cloud LLMs";
    homepage = "https://lobehub.com";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    mainProgram = "lobehub";
  };
}
