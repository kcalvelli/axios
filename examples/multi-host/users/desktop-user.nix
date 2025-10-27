{ self, config, ... }:
let
  username = "alice";
  fullName = "Alice Smith";
  email = "alice@example.com";
  homeDir = "/home/${username}";
in
{
  # Define the user account
  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    initialPassword = "changeme";  # Change on first login!
    extraGroups = [
      "networkmanager"
      "wheel"        # sudo access
      "video"
      "audio"
      "input"
    ];
  };

  # Home Manager configuration for the user
  home-manager.users.${username} = {
    home = {
      stateVersion = "24.05";
      homeDirectory = homeDir;
      username = username;
    };

    nixpkgs.config = {
      allowUnfree = true;
    };

    # User-specific git configuration  
    programs.git.settings = {
      user = {
        name = fullName;
        email = email;
      };
    };
  };

  # Grant sudo access
  nix.settings.trusted-users = [ username ];
}
