{ pkgs }:
{
  # System desktop applications
  system = with pkgs; [
    mate.mate-polkit
    wayvnc
    xwayland-satellite
    brightnessctl
  ];

  # Icon themes
  themes = with pkgs; [
    colloid-icon-theme
    adwaita-icon-theme
    papirus-icon-theme
  ];

  # File manager and extensions
  fileManager = with pkgs; [
    nautilus
    code-nautilus
  ];
}
