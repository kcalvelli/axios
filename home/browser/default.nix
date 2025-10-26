{
  imports = [
    ./pwa.nix # Progressive Web Apps
  ];

  programs.brave = {
    enable = true;
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # ProtonPass
      { id = "ghbmnnjooekpmoecnnnilnnbdlolhkhi"; } # Google Docs Offline
      { id = "nimfmkdcckklbkhjjkmbjfcpaiifgamg"; } # Brave Talk for Calendars
    ];
    commandLineArgs = [
      "--password-store=detect"
      "--gtk-version=4"
    ];
  };
}
