{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  hidapi,
  libusb1,
  opencv4,
  libjpeg,
}:
# thaytan's rift-room-config branch (Oculus Rift CV1 6DoF), plus the patches
# this repo carries on top of it.
stdenv.mkDerivation {
  pname = "openhmd-rift";
  version = "0.3.0-unstable-2026-07-29";

  src = fetchFromGitHub {
    owner = "thaytan";
    repo = "OpenHMD";
    rev = "68bb1cd64c7e4e9ee8d4f99976d489f6c6e95193";
    hash = "sha256-djjqWviFQi8ExE6TZIbITrishnYc4TDXpeyiBHm0NAA=";
  };

  patches = [
    ./openhmd-patches/opencv-lookup.patch
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    hidapi
    libusb1
    opencv4
    libjpeg
  ];

  mesonFlags = [
    "-Ddrivers=rift"
    # Monado links libusb itself for its own drivers, hidraw backend would be conflicting.
    "-Dhidapi=libusb"
    "-Dexamples="
    "-Dtests=false"
  ];

  meta = {
    description = "OpenHMD with the Oculus Rift CV1 6DoF (rift-room-config) driver";
    homepage = "https://github.com/thaytan/OpenHMD";
    license = lib.licenses.boost;
    platforms = lib.platforms.linux;
  };
}
