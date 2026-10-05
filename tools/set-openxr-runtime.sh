#!/usr/bin/env bash
# Register this repo's Monado as the OpenXR runtime for the current user, so
# OpenXR clients (games under Proton, hello_xr) find it without XR_RUNTIME_JSON.
#
#   tools/set-openxr-runtime.sh --print   # show the manifest, change nothing
#   tools/set-openxr-runtime.sh           # write ~/.config/openxr/1/active_runtime.json

set -euo pipefail

# Resolve the repo, so the script works from any directory.
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

out="$(nix build --no-link --print-out-paths "$repo#monado")"

# The package's own manifest already names the runtime and its library path.
manifest="$out/share/openxr/1/openxr_monado.json"
[ -s "$manifest" ] || { echo "no manifest at $manifest" >&2; exit 1; }

json="$(cat "$manifest")"

if [ "${1:-}" = "--print" ]; then
	printf '%s\n' "$json"
	exit 0
fi

dest="${XDG_CONFIG_HOME:-$HOME/.config}/openxr/1/active_runtime.json"
mkdir -p "$(dirname "$dest")"
printf '%s\n' "$json" > "$dest"
echo "wrote $dest"
