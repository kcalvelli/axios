{ config, lib, inputs, osConfig ? { }, ... }:

let
  cfg = config.secrets;
  # Check if secrets are enabled at system level
  systemSecretsEnabled = osConfig.secrets.enable or false;
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  options = {
    secrets = {
      enable = lib.mkEnableOption "age-encrypted secrets management for home-manager" // {
        default = systemSecretsEnabled;
      };

      identityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "${config.home.homeDirectory}/.ssh/id_ed25519"
          "${config.home.homeDirectory}/.ssh/id_rsa"
        ];
        description = ''
          Paths to SSH private keys used to decrypt secrets.
          By default, uses the user's SSH keys (id_ed25519 and id_rsa).
        '';
      };

      secretsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = osConfig.secrets.secretsDir or null;
        example = lib.literalExpression "./secrets";
        description = ''
          Optional path to a directory containing .age secret files for this user.
          If set, axios will automatically register all .age files found
          in this directory as secrets, making them available at
          ~/.config/agenix/<filename> (without the .age extension).

          By default, inherits from system-level secrets.secretsDir if configured.
          This provides convention over configuration for simple use cases.
          For more control, use age.secrets directly.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure agenix identity paths for home-manager
    age.identityPaths = cfg.identityPaths;

    # Auto-register secrets from secretsDir if provided
    age.secrets = lib.mkIf (cfg.secretsDir != null) (
      let
        # Read all .age files from the secrets directory
        secretFiles = builtins.readDir cfg.secretsDir;
        ageFiles = lib.filterAttrs
          (name: type:
            type == "regular" && lib.hasSuffix ".age" name
          )
          secretFiles;

        # Generate age.secrets entries for home-manager
        mkSecretEntry = name: {
          name = lib.removeSuffix ".age" name;
          value = {
            file = cfg.secretsDir + "/${name}";
          };
        };
      in
      builtins.listToAttrs (map mkSecretEntry (builtins.attrNames ageFiles))
    );
  };
}
