{ ... }:
let
  username = "myuser";
  fullName = "My Full Name";
  email = "me@example.com";
  homeDir = "/home/${username}";
in
{
  # Define the user account
  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    # Set password with: sudo passwd ${username}
    # Or use: hashedPassword = "..."; (generate with mkpasswd)
    extraGroups = [
      "networkmanager"
      "wheel" # sudo access
      "video"
      "audio"
      "input"
      "libvirtd" # if using virtualization
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
  };

  # Grant sudo access
  nix.settings.trusted-users = [ username ];
}
