{
  # Enable and configure GPG
  programs.gpg = {
    enable = true;
    settings = {
      keyserver = "hkps://keys.openpgp.org";
      auto-key-retrieve = true;
      auto-key-import = true;
      keyserver-options = "honor-keyserver-url";
    };
  };

  # Additional security configurations can be added here
}
