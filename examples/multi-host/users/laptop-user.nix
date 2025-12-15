{ ... }:
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
    hashedPassword = "..."; # Set via passwd or mkpasswd
    extraGroups = [
      "networkmanager"
      "wheel" # sudo access
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

    # Note: nixpkgs.config is managed at the system level by axios
    # when using home-manager.useGlobalPkgs

    # User-specific git configuration
    programs.git.settings = {
      user = {
        name = fullName;
        email = email;
      };
    };

    # Laptop-specific: Enable battery monitoring
    # services.poweralertd.enable = true;
  };

  # Grant sudo access
  nix.settings.trusted-users = [ username ];
}
