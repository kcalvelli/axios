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

  gemini = {
    name = "Gemini";
    url = "https://gemini.google.com/";
    icon = "gemini";
    categories = [
      "Office"
      "Utility"
    ];
  };

  google-ai-studio = {
    name = "Google AI Studio";
    url = "https://aistudio.google.com/";
    icon = "google-ai-studio";
    categories = [
      "Development"
      "Utility"
    ];
  };

  notebooklm = {
    name = "NotebookLM";
    url = "https://notebooklm.google.com/";
    icon = "notebooklm";
    categories = [
      "Office"
      "Utility"
    ];
  };

  google-search = {
    name = "Google Search";
    url = "https://www.google.com/";
    icon = "google-search";
    categories = [
      "Network"
      "WebBrowser"
    ];
  };

  youtube-music = {
    name = "YouTube Music";
    url = "https://music.youtube.com/";
    icon = "youtube-music";
    categories = [
      "AudioVideo"
      "Audio"
    ];
  };

  google-news = {
    name = "Google News";
    url = "https://news.google.com/";
    icon = "google-news";
    categories = [
      "Network"
      "News"
    ];
  };

  google-voice = {
    name = "Google Voice";
    url = "https://voice.google.com/";
    icon = "google-voice";
    categories = [
      "Network"
      "Telephony"
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

  google-docs = {
    name = "Google Docs";
    url = "https://docs.google.com/";
    icon = "google-docs";
    categories = [
      "Office"
      "WordProcessor"
    ];
  };

  google-sheets = {
    name = "Google Sheets";
    url = "https://sheets.google.com/";
    icon = "google-sheets";
    categories = [
      "Office"
      "Spreadsheet"
    ];
  };

  google-slides = {
    name = "Google Slides";
    url = "https://slides.google.com/";
    icon = "google-slides";
    categories = [
      "Office"
      "Presentation"
    ];
  };

  google-calendar = {
    name = "Google Calendar";
    url = "https://calendar.google.com/";
    icon = "google-calendar";
    categories = [
      "Office"
      "Calendar"
    ];
    mimeTypes = [
      "x-scheme-handler/webcal"
      "x-scheme-handler/webcals"
      "text/calendar"
    ];
  };

  google-keep = {
    name = "Google Keep";
    url = "https://keep.google.com/";
    icon = "google-keep";
    categories = [
      "Office"
      "Utility"
    ];
  };

  google-contacts = {
    name = "Google Contacts";
    url = "https://contacts.google.com/";
    icon = "google-contacts";
    categories = [
      "Office"
      "ContactManagement"
    ];
  };

  google-forms = {
    name = "Google Forms";
    url = "https://forms.google.com/";
    icon = "google-forms";
    categories = [
      "Office"
      "Utility"
    ];
  };

  google-classroom = {
    name = "Google Classroom";
    url = "https://classroom.google.com/";
    icon = "google-classroom";
    categories = [
      "Education"
      "Office"
    ];
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
