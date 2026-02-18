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
    # Install desktop entry (upstream uses "lobehub-desktop" naming)
    install -Dm644 ${appimageContents}/lobehub-desktop.desktop $out/share/applications/lobehub.desktop

    # Fix desktop entry paths and name
    substituteInPlace $out/share/applications/lobehub.desktop \
      --replace-quiet 'Exec=AppRun' "Exec=$out/bin/lobehub" \
      --replace-quiet 'Exec=lobehub-desktop' "Exec=$out/bin/lobehub" \
      --replace-quiet 'Icon=lobehub-desktop' 'Icon=lobehub'

    # Install icon (only 512x512 available in AppImage)
    install -Dm644 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/lobehub-desktop.png \
      $out/share/icons/hicolor/512x512/apps/lobehub.png

    # Also install the root-level icon as fallback
    install -Dm644 ${appimageContents}/lobehub-desktop.png \
      $out/share/icons/hicolor/256x256/apps/lobehub.png

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
