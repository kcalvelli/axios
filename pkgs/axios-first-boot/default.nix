{
  lib,
  pkgs,
  writeShellScriptBin,
  makeWrapper,
  gum,
  gnused,
  gnugrep,
  coreutils,
  findutils,
  hostname,
}:

let
  script = builtins.readFile ../../scripts/first-boot.sh;
in
writeShellScriptBin "axios-first-boot" ''
  export PATH="${
    lib.makeBinPath [
      gum
      gnused
      gnugrep
      coreutils
      findutils
      hostname
      pkgs.nixos-rebuild
    ]
  }:$PATH"

  ${script}
''
