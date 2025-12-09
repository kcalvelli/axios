{
  programs.brave = {
    enable = true;
    extensions = [
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # ProtonPass
      { id = "ghbmnnjooekpmoecnnnilnnbdlolhkhi"; } # Google Docs Offline
      { id = "nimfmkdcckklbkhjjkmbjfcpaiifgamg"; } # Brave Talk for
      { id = "aomjjfmjlecjafonmbhlgochhaoplhmo"; } # 1Password
    ];
    commandLineArgs = [
      "--password-store=detect"
      "--gtk-version=4"
    ];
  };
}
