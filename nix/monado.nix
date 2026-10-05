{
  lib,
  fetchFromGitLab,
  monado,
  openhmd,
}:
# Upstream Monado (main) built with the OpenHMD Rift CV1 driver instead of
# Monado's native Rift driver.
monado.overrideAttrs (old: {
  pname = "monado-rift";
  version = "25.1.0-unstable-2026-10-10";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "monado";
    repo = "monado";
    rev = "13b5c134b16c86ff3e3be52e8fa6dc720a8247e0";
    hash = "sha256-ql0SOTRuJiJa3XiA+3qoQJSvPLfWWRtfR0KDbqguv8k=";
  };

  # nixpkgs backports monado-cylinder-aspectRatio.patch to v25.1.0; main has it.
  patches = builtins.filter (p: (p.name or "") != "monado-cylinder-aspectRatio.patch") (
    old.patches or [ ]
  );

  buildInputs = (old.buildInputs or [ ]) ++ [ openhmd ];

  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    (lib.cmakeBool "XRT_BUILD_DRIVER_OHMD" true)

    # The CV1 goes through OpenHMD, not Monado's native Rift driver.
    (lib.cmakeBool "XRT_BUILD_DRIVER_RIFT" false)
    (lib.cmakeBool "XRT_BUILD_DRIVER_RIFT_SENSOR" false)
    (lib.cmakeBool "XRT_BUILD_DRIVER_UVC" false)
  ];

  # Catch silent builds without OpenHMD.
  postConfigure = (old.postConfigure or "") + ''
    grep -qE '^XRT_BUILD_DRIVER_OHMD:BOOL=(ON|TRUE|1)$' CMakeCache.txt || {
      echo "XRT_BUILD_DRIVER_OHMD is not enabled - missing openhmd or renamed option?" >&2
      exit 1
    }
  '';

  meta = (old.meta or { }) // {
    description = "OpenXR runtime built with the OpenHMD Rift CV1 driver";
  };
})
