{
  description = "axiOS - A modular NixOS distribution";

  inputs = {

    #nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };

    systems = {
      url = "github:nix-systems/x86_64-linux";
    };

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };

    agenix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:ryantm/agenix";
    };

    devshell = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/devshell";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # For dev shells
    "zig-overlay".url = "github:mitchellh/zig-overlay";
    fenix.url = "github:nix-community/fenix";

    lazyvim = {
      url = "github:matadaniel/LazyVim-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs = {
        #flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    # Niri with DMS Shell
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      inputs.dms-cli.follows = "dms-cli";
    };

    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fun with "AI"
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    mcp-journal.url = "github:kcalvelli/mcp-journal";
    nix-devshell-mcp.url = "github:kcalvelli/nix-devshell-mcp";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust overlay
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://numtide.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-substituters = [
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431kS1gBOk6429S9g0f1NXtv+FIsf8Xma0="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

  outputs =
    inputs@{ flake-parts
    , systems
    , nixpkgs
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ self, ... }: {
      systems = import systems;

      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;

        # Apps - exposed as `nix run github:kcalvelli/axios#<app>`
        apps = {
          init = {
            type = "app";
            program = toString (pkgs.writeShellScript "axios-init" ''
              export AXIOS_TEMPLATE_DIR="${./scripts/templates}"
              exec ${pkgs.bash}/bin/bash ${./scripts/init-config.sh}
            '');
            meta.description = "Initialize a new axiOS configuration";
          };
        };
      };

      imports = [
        ./pkgs
        ./modules
        ./home
        ./devshells.nix
      ];

      # Export library functions for downstream flakes
      flake.lib = import ./lib {
        inherit inputs;
        inherit self;
        lib = nixpkgs.lib;
      };
    });
}
