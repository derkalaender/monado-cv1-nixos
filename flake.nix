{
  description = "Monado + OpenHMD (Oculus Rift CV1, thaytan rift-room-config) for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

      perSystem =
        {
          lib,
          pkgs,
          ...
        }:
        let
          inherit (lib.fixedPoints) fix;
        in
        {
          packages = fix (final: {
            openhmd = pkgs.callPackage ./nix/openhmd.nix { };
            monado = pkgs.callPackage ./nix/monado.nix { inherit (final) openhmd; };
            default = final.monado;
          });
        };
    };
}
