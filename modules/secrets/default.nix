{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.secrets;
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  options = {
    secrets = {
      enable = lib.mkEnableOption "age-encrypted secrets management with agenix";

      identityPaths = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
        description = ''
          Paths to SSH private keys used to decrypt secrets.
          By default, uses the system's SSH host keys.
          The first key that exists will be used.
        '';
      };

      secretsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./secrets";
        description = ''
          Optional path to a directory containing .age secret files.
          If set, axios will automatically register all .age files found
          in this directory as secrets, making them available at
          /run/agenix/<filename> (without the .age extension).

          This provides convention over configuration for simple use cases.
          For more control, use age.secrets directly.
        '';
      };

      installCLI = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to install the agenix CLI tool for managing secrets.
          The CLI is accessible as 'agenix' in the system environment.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure agenix identity paths
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

        # Generate age.secrets entries
        mkSecretEntry = name: {
          name = lib.removeSuffix ".age" name;
          value = {
            file = cfg.secretsDir + "/${name}";
          };
        };
      in
      builtins.listToAttrs (map mkSecretEntry (builtins.attrNames ageFiles))
    );

    # Install agenix CLI and age package
    environment.systemPackages = [ pkgs.age ]
      ++ lib.optional cfg.installCLI inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
