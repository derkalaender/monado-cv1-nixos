project(
    'vr-devices',
    'cpp',
    version: '1.0.0',
    default_options: ['cpp_std=c++23', 'warning_level=2'],
)

# libmonado ships no pkg-config file, so find it through the compiler's search
# path (in the Nix dev shell that is monado in buildInputs). Building outside
# Nix needs the include dir and library on CPATH/LIBRARY_PATH.
cc = meson.get_compiler('cpp')
monado = cc.find_library('monado', required: true)

executable('vr-devices', 'main.cpp', dependencies: monado, install: true)
