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

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For dev shells
    "zig-overlay" = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri with DMS Shell
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    axios-monitor = {
      url = "github:kcalvelli/axios-monitor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      # Eliminate 15GB+ of duplicate packages by using unstable for stable channel too
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    # Fun with "AI"
    mcp-journal = {
      url = "github:kcalvelli/mcp-journal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-devshell-mcp = {
      url = "github:kcalvelli/nix-devshell-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ultimate64-mcp = {
      url = "github:kcalvelli/Ultimate64MCP";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    c64-stream-viewer = {
      url = "github:kcalvelli/c64-stream-viewer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Brave browser previews (nightly/beta)
    brave-browser-previews = {
      url = "github:kcalvelli/brave-browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Code formatting
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
    inputs@{
      flake-parts,
      systems,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { self, ... }:
      {
        systems = import systems;

        perSystem =
          { pkgs, ... }:
          {
            # Formatter for `nix fmt`
            formatter = (
              inputs.treefmt-nix.lib.mkWrapper pkgs {
                projectRootFile = "flake.nix";
                programs.nixfmt.enable = true;
              }
            );

            # Apps - exposed as `nix run github:kcalvelli/axios#<app>`
            apps = {
              init = {
                type = "app";
                program = toString (
                  pkgs.writeShellScript "axios-init" ''
                    export AXIOS_TEMPLATE_DIR="${./scripts/templates}"
                    exec ${pkgs.bash}/bin/bash ${./scripts/init-config.sh}
                  ''
                );
                meta.description = "Initialize a new axiOS configuration";
              };

              download-llama-models = {
                type = "app";
                program = toString (
                  pkgs.writeShellScript "download-llama-models" ''
                    exec ${pkgs.bash}/bin/bash ${./scripts/download-llama-models.sh} "$@"
                  ''
                );
                meta.description = "Download GGUF models for llama-cpp server";
              };

              add-pwa = {
                type = "app";
                program = toString (
                  pkgs.writeShellScript "axios-add-pwa" ''
                    export PATH="${
                      pkgs.lib.makeBinPath [
                        pkgs.bash
                        pkgs.curl
                        pkgs.jq
                        pkgs.imagemagick
                        pkgs.coreutils
                        pkgs.gnugrep
                        pkgs.gnused
                        pkgs.file
                      ]
                    }:$PATH"
                    export FETCH_SCRIPT="${./scripts/fetch-pwa-icon.sh}"
                    exec ${pkgs.bash}/bin/bash ${./scripts/add-pwa.sh} "$@"
                  ''
                );
                meta.description = "Interactive helper to add custom PWAs to your configuration";
              };

              fetch-pwa-icon = {
                type = "app";
                program = toString (
                  pkgs.writeShellScript "axios-fetch-pwa-icon" ''
                    export PATH="${
                      pkgs.lib.makeBinPath [
                        pkgs.bash
                        pkgs.curl
                        pkgs.jq
                        pkgs.imagemagick
                        pkgs.coreutils
                        pkgs.gnugrep
                        pkgs.gnused
                        pkgs.file
                      ]
                    }:$PATH"
                    exec ${pkgs.bash}/bin/bash ${./scripts/fetch-pwa-icon.sh} "$@"
                  ''
                );
                meta.description = "Fetch PWA icon from a website";
              };
            };
          };

        imports = [
          #inputs.treefmt-nix.flakeModule
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
      }
    );
}
