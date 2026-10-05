{
  lib,
  stdenv,
  meson,
  ninja,
  pkg-config,
  monado,
}:

# Lists the devices a running Monado service exposes (name, serial, DoF, role)
# over libmonado's IPC.
stdenv.mkDerivation {
  pname = "vr-devices";
  version = "1.0.0";

  src = ../tools/vr-devices;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [ monado ];

  meta = {
    description = "List the devices a running Monado service exposes";
    license = lib.licenses.boost;
    platforms = lib.platforms.linux;
    mainProgram = "vr-devices";
  };
}
