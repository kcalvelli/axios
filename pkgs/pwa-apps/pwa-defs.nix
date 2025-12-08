# PWA Definitions
# Maps PWA names to their URLs and metadata
{
  google-drive = {
    name = "Google Drive";
    url = "https://drive.google.com/";
    icon = "google-drive";
    categories = [
      "Office"
      "FileManager"
    ];
  };

  youtube = {
    name = "YouTube";
    url = "https://www.youtube.com/";
    icon = "youtube";
    categories = [
      "AudioVideo"
      "Video"
    ];
    actions = {
      "Subscriptions" = {
        name = "Subscriptions";
        url = "https://www.youtube.com/feed/subscriptions";
      };
      "Explore" = {
        name = "Explore";
        url = "https://www.youtube.com/feed/explore";
      };
    };
  };

  element = {
    name = "Element";
    url = "https://app.element.io/";
    icon = "element";
    categories = [
      "Network"
      "InstantMessaging"
    ];
  };

  google-messages = {
    name = "Messages";
    url = "https://messages.google.com/web";
    icon = "google-messages";
    categories = [
      "Network"
      "InstantMessaging"
    ];
  };

  google-meet = {
    name = "Google Meet";
    url = "https://meet.google.com/";
    icon = "google-meet";
    categories = [
      "Network"
      "VideoConference"
    ];
  };

  google-chat = {
    name = "Google Chat";
    url = "https://chat.google.com/";
    icon = "google-chat";
    categories = [
      "Network"
      "InstantMessaging"
    ];
  };

  google-maps = {
    name = "Google Maps";
    url = "https://www.google.com/maps";
    icon = "google-maps";
    categories = [
      "Education"
      "Geoscience"
    ];
  };

  google-photos = {
    name = "Google Photos";
    url = "https://photos.google.com/";
    icon = "google-photos";
    categories = [
      "Graphics"
      "Photography"
    ];
  };

  gmail = {
    name = "Gmail";
    url = "https://mail.google.com/";
    icon = "gmail";
    categories = [
      "Office"
      "Email"
    ];
    mimeTypes = [ "x-scheme-handler/mailto" ];
    actions = {
      "Compose" = {
        name = "Compose";
        url = "https://mail.google.com/mail/?view=cm&fs=1&tf=1";
      };
    };
  };

  telegram = {
    name = "Telegram Web";
    url = "https://web.telegram.org/";
    icon = "telegram";
    categories = [
      "Network"
      "InstantMessaging"
    ];
  };

  outlook = {
    name = "Outlook (PWA)";
    url = "https://outlook.office365.com/mail";
    icon = "outlook";
    categories = [
      "Office"
      "Email"
    ];
    mimeTypes = [ "x-scheme-handler/mailto" ];
    actions = {
      "New-event" = {
        name = "New event";
        url = "https://outlook.office365.com/calendar/deeplink/compose";
      };
      "New-message" = {
        name = "New message";
        url = "https://outlook.office365.com/mail/deeplink/compose";
      };
      "Open-calendar" = {
        name = "Open calendar";
        url = "https://outlook.office365.com/calendar";
      };
    };
  };

  teams = {
    name = "Microsoft Teams";
    url = "https://teams.microsoft.com/";
    icon = "teams";
    categories = [
      "Network"
      "VideoConference"
    ];
  };

  sonos = {
    name = "Sonos";
    url = "https://sonos.com/controller";
    icon = "sonos";
    categories = [
      "AudioVideo"
      "Audio"
    ];
  };

  proton-pass = {
    name = "Proton Pass Web App";
    url = "https://pass.proton.me/";
    icon = "proton-pass";
    categories = [
      "Utility"
      "Security"
    ];
  };

  proton-mail = {
    name = "Proton Mail";
    url = "https://mail.proton.me/";
    icon = "proton-mail";
    categories = [
      "Network"
      "Email"
    ];
    mimeTypes = [ "x-scheme-handler/mailto" ];
  };

  proton-drive = {
    name = "Proton Drive";
    url = "https://drive.proton.me/";
    icon = "proton-drive";
    categories = [
      "Office"
      "FileManager"
    ];
  };

  proton-calendar = {
    name = "Proton Calendar";
    url = "https://calendar.proton.me/";
    icon = "proton-calendar";
    categories = [
      "Office"
      "Calendar"
    ];
    mimeTypes = [
      "x-scheme-handler/webcal"
      "x-scheme-handler/webcals"
      "text/calendar"
      "application/ics"
      "application/x-ics"
      "text/x-vcalendar"
    ];
  };

  proton-wallet = {
    name = "Proton Wallet";
    url = "https://wallet.proton.me/";
    icon = "proton-wallet";
    categories = [
      "Office"
      "Finance"
    ];
  };
}
