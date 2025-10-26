{ pkgs, lib, ... }:
let
  braveExe = lib.getExe pkgs.brave;
in
{
  # PWA Desktop entries
  # If you are not me, do not use this
  xdg.desktopEntries = {
    "brave-aghbiahbpaijignceidepookljebhfak-Default" = {
      name = "Google Drive";
      exec = "${braveExe} --profile-directory=Default --app-id=aghbiahbpaijignceidepookljebhfak";
      icon = "brave-aghbiahbpaijignceidepookljebhfak-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_aghbiahbpaijignceidepookljebhfak";
      };
    };
    "brave-agimnkijcaahngcdmfeangaknmldooml-Default" = {
      name = "YouTube";
      exec = "${braveExe} --profile-directory=Default --app-id=agimnkijcaahngcdmfeangaknmldooml";
      icon = "brave-agimnkijcaahngcdmfeangaknmldooml-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_agimnkijcaahngcdmfeangaknmldooml";
      };
      actions = {
        "Subscriptions" = {
          name = "Subscriptions";
          exec = "${braveExe} --profile-directory=Default --app-id=agimnkijcaahngcdmfeangaknmldooml --app-launch-url-for-shortcuts-menu-item=https://www.youtube.com/feed/subscriptions";
        };
        "Explore" = {
          name = "Explore";
          exec = "${braveExe} --profile-directory=Default --app-id=agimnkijcaahngcdmfeangaknmldooml --app-launch-url-for-shortcuts-menu-item=https://www.youtube.com/feed/explore";
        };
      };
    };
    "brave-ejhkdoiecgkmdpomoahkdihbcldkgjci-Default" = {
      name = "Element";
      exec = "${braveExe} --profile-directory=Default --app-id=ejhkdoiecgkmdpomoahkdihbcldkgjci";
      icon = "brave-ejhkdoiecgkmdpomoahkdihbcldkgjci-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_ejhkdoiecgkmdpomoahkdihbcldkgjci";
      };
    };
    "brave-hpfldicfbfomlpcikngkocigghgafkph-Default" = {
      name = "Messages";
      exec = "${braveExe} --profile-directory=Default --app-id=hpfldicfbfomlpcikngkocigghgafkph";
      icon = "brave-hpfldicfbfomlpcikngkocigghgafkph-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_hpfldicfbfomlpcikngkocigghgafkph";
      };
    };
    "brave-kjgfgldnnfoeklkmfkjfagphfepbbdan-Default" = {
      name = "Google Meet";
      exec = "${braveExe} --profile-directory=Default --app-id=kjgfgldnnfoeklkmfkjfagphfepbbdan";
      icon = "brave-kjgfgldnnfoeklkmfkjfagphfepbbdan-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_kjgfgldnnfoeklkmfkjfagphfepbbdan";
      };
    };
    "brave-mdpkiolbdkhdjpekfbkbmhigcaggjagi-Default" = {
      name = "Google Chat";
      exec = "${braveExe} --profile-directory=Default --app-id=mdpkiolbdkhdjpekfbkbmhigcaggjagi";
      icon = "brave-mdpkiolbdkhdjpekfbkbmhigcaggjagi-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_mdpkiolbdkhdjpekfbkbmhigcaggjagi";
      };
    };
    "brave-mnhkaebcjjhencmpkapnbdaogjamfbcj-Default" = {
      name = "Google Maps";
      exec = "${braveExe} --profile-directory=Default --app-id=mnhkaebcjjhencmpkapnbdaogjamfbcj";
      icon = "brave-mnhkaebcjjhencmpkapnbdaogjamfbcj-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_mnhkaebcjjhencmpkapnbdaogjamfbcj";
      };
    };
    "brave-ncmjhecbjeaamljdfahankockkkdmedg-Default" = {
      name = "Google Photos";
      exec = "${braveExe} --profile-directory=Default --app-id=ncmjhecbjeaamljdfahankockkkdmedg";
      icon = "brave-ncmjhecbjeaamljdfahankockkkdmedg-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_ncmjhecbjeaamljdfahankockkkdmedg";
      };
    };
    "brave-ibblmnobmgdmpoeblocemifbpglakpoi-Default" = {
      name = "Telegram Web";
      exec = "${braveExe} --profile-directory=Default --app-id=ibblmnobmgdmpoeblocemifbpglakpoi";
      icon = "brave-ibblmnobmgdmpoeblocemifbpglakpoi-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_ibblmnobmgdmpoeblocemifbpglakpoi";
      };
    };
    "brave-dnbnnnhjocpglknpbaaajdkbapeamick-Default" = {
      name = "Outlook (PWA)";
      exec = "${braveExe} --profile-directory=Default --app-id=dnbnnnhjocpglknpbaaajdkbapeamick %U";
      icon = "brave-dnbnnnhjocpglknpbaaajdkbapeamick-Default";
      terminal = false;
      type = "Application";
      mimeType = [ "x-scheme-handler/mailto" ];
      settings = {
        StartupWMClass = "crx_dnbnnnhjocpglknpbaaajdkbapeamick";
        Actions = "New-event;New-message;Open-calendar";
      };
      actions = {
        "New-event" = {
          name = "New event";
          exec = "${braveExe} --profile-directory=Default --app-id=dnbnnnhjocpglknpbaaajdkbapeamick --app-launch-url-for-shortcuts-menu-item=https://outlook.office365.com.mcas.ms/calendar/deeplink/compose";
        };
        "New-message" = {
          name = "New message";
          exec = "${braveExe} --profile-directory=Default --app-id=dnbnnnhjocpglknpbaaajdkbapeamick --app-launch-url-for-shortcuts-menu-item=https://outlook.office365.com.mcas.ms/mail/deeplink/compose";
        };
        "Open-calendar" = {
          name = "Open calendar";
          exec = "${braveExe} --profile-directory=Default --app-id=dnbnnnhjocpglknpbaaajdkbapeamick --app-launch-url-for-shortcuts-menu-item=https://outlook.office365.com.mcas.ms/calendar";
        };
      };
    };
    "brave-oiocllghmdadfpahmllbbhkgjfmaidmm-Default" = {
      name = "Microsoft Teams";
      exec = "${braveExe} --profile-directory=Default --app-id=oiocllghmdadfpahmllbbhkgjfmaidmm";
      icon = "brave-oiocllghmdadfpahmllbbhkgjfmaidmm-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_oiocllghmdadfpahmllbbhkgjfmaidmm";
      };
    };
    "brave-cicjgplghpdkjlhjlppobdmdkjlpfpml-Default" = {
      name = "Sonos";
      exec = "${braveExe} --profile-directory=Default --app-id=cicjgplghpdkjlhjlppobdmdkjlpfpml";
      icon = "brave-cicjgplghpdkjlhjlppobdmdkjlpfpml-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_cicjgplghpdkjlhjlppobdmdkjlpfpml";
      };
    };
    "brave-hkhckfoofhljcngmlnlojcbplgkcpcab-Default" = {
      name = "Proton Pass Web App";
      exec = "${braveExe} --profile-directory=Default --app-id=hkhckfoofhljcngmlnlojcbplgkcpcab";
      icon = "brave-hkhckfoofhljcngmlnlojcbplgkcpcab-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_hkhckfoofhljcngmlnlojcbplgkcpcab";
      };
    };
    "brave-jnpecgipniidlgicjocehkhajgdnjekh-Default" = {
      name = "Proton Mail";
      exec = "${braveExe} --profile-directory=Default --app-id=jnpecgipniidlgicjocehkhajgdnjekh";
      icon = "brave-jnpecgipniidlgicjocehkhajgdnjekh-Default";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Email" ];
      mimeType = [ "x-scheme-handler/mailto" ];
      settings = {
        StartupWMClass = "crx_jnpecgipniidlgicjocehkhajgdnjekh";
      };
    };
    "brave-fnnddiokljlbkmeppnclajginnfbffgb-Default" = {
      name = "Proton Drive";
      exec = "${braveExe} --profile-directory=Default --app-id=fnnddiokljlbkmeppnclajginnfbffgb";
      icon = "brave-fnnddiokljlbkmeppnclajginnfbffgb-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_fnnddiokljlbkmeppnclajginnfbffgb";
      };
    };
    "brave-ojibjkjikcpjonjjngfkegflhmffeemk-Default" = {
      name = "Proton Calendar";
      exec = "${braveExe} --profile-directory=Default --app-id=ojibjkjikcpjonjjngfkegflhmffeemk";
      icon = "brave-ojibjkjikcpjonjjngfkegflhmffeemk-Default";
      terminal = false;
      type = "Application";
      categories = [ "Office" "Calendar" ];
      mimeType = [
        "x-scheme-handler/webcal"
        "x-scheme-handler/webcals"
        "text/calendar" # .ics
        "application/ics" # sometimes used
        "application/x-ics" # sometimes used
        "text/x-vcalendar" # legacy
      ];
      settings = {
        StartupWMClass = "crx_ojibjkjikcpjonjjngfkegflhmffeemk";
      };
    };
    "brave-kdnccncfodjdpogfgcekohdeabddjfke-Default" = {
      name = "Proton Wallet";
      exec = "${braveExe} --profile-directory=Default --app-id=kdnccncfodjdpogfgcekohdeabddjfke";
      icon = "brave-kdnccncfodjdpogfgcekohdeabddjfke-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_kdnccncfodjdpogfgcekohdeabddjfke";
      };
    };

    # "brave-jdklklfpinionkgpmghaghehojplfjio-Default" = {
    #   name = "Photopea";
    #   exec = "${braveExe} --profile-directory=Default --app-id=jdklklfpinionkgpmghaghehojplfjio %U";
    #   icon = "brave-jdklklfpinionkgpmghaghehojplfjio-Default";
    #   terminal = false;
    #   type = "Application";
    #   mimeType = [
    #     "application/pdf"
    #     "image/ai"
    #     "image/bmp"
    #     "image/cdr"
    #     "image/eps"
    #     "image/gif"
    #     "image/jp2"
    #     "image/jpeg"
    #     "image/jpx"
    #     "image/png"
    #     "image/psb"
    #     "image/psd"
    #     "image/pxd"
    #     "image/sketch"
    #     "image/svg+xml"
    #     "image/tiff"
    #     "image/vnd-ms.dds"
    #     "image/webp"
    #     "image/x-icon"
    #     "image/x-tga"
    #     "image/xcf"
    #     "image/xd"
    #   ];
    #   settings = {
    #     StartupWMClass = "crx_jdklklfpinionkgpmghaghehojplfjio";
    #   };
    # };

    "brave-oijgmambjjhcpfnploolbhpnehlkheid-Default" = {
      name = "Windows App";
      exec = "${braveExe} --profile-directory=Default --app-id=oijgmambjjhcpfnploolbhpnehlkheid";
      icon = "brave-oijgmambjjhcpfnploolbhpnehlkheid-Default";
      terminal = false;
      type = "Application";
      settings = {
        StartupWMClass = "crx_oijgmambjjhcpfnploolbhpnehlkheid";
      };
    };
  };

  systemd.user.services.clear-pwa-desktop-entries = {
    Unit = {
      Description = "Clear PWA Desktop Entries";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/rm -f $HOME/.local/share/applications/brave-*.desktop'";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
