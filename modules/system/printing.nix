{
  # Enable and configure printing services
  services.printing = {
    enable = true;
    openFirewall = true;
  };
  programs.system-config-printer.enable = true;

  # Enable color management for printers and displays
  services.colord.enable = true;
}
