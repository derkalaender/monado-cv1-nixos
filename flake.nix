{
  description = "Monado + OpenHMD (Oculus Rift CV1, thaytan rift-room-config) for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.treefmt-nix.flakeModule ];

      systems = [
        "x86_64-linux"
      ];

      perSystem =
        {
          lib,
          pkgs,
          self',
          ...
        }:
        let
          inherit (lib.fixedPoints) fix;
        in
        {
          packages = fix (final: {
            openhmd = pkgs.callPackage ./nix/openhmd.nix { };
            monado = pkgs.callPackage ./nix/monado.nix { inherit (final) openhmd; };
            vr-devices = pkgs.callPackage ./nix/vr-devices.nix { monado = final.monado; };
            default = final.monado;
          });

          devShells.default = pkgs.mkShell {
            inputsFrom = [
              self'.packages.monado
              self'.packages.openhmd
            ];
            packages = [
              # Built from the pinned upstream sources
              self'.packages.monado
              self'.packages.openhmd
              self'.packages.vr-devices
            ]
            ++ (with pkgs; [
              # C++ toolchain for ./tools
              clang-tools
              gdb
              meson
              ninja
              nixfmt

              # Debugging VR
              usbutils
              v4l-utils
              xrgears
              openxr-loader # hello_xr
            ]);

            # Clients started from this shell find the runtime without an
            # explicit XR_RUNTIME_JSON.
            XR_RUNTIME_JSON = "${self'.packages.monado}/share/openxr/1/openxr_monado.json";

            # Editor support: clangd reads the compilation database meson writes.
            shellHook = ''
              if [ ! -f tools/vr-devices/build/compile_commands.json ]; then
                meson setup tools/vr-devices/build tools/vr-devices
              fi
            '';
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              clang-format.enable = true;
              meson.enable = true;
              nixfmt.enable = true;
              shfmt.enable = true;
            };
          };
        };
    };
}
