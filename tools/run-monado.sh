#!/usr/bin/env bash
# Build the Monado from this flake and run it straight from the store.

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# A hand run owns the IPC socket, so the socket unit has to be down.
if systemctl --user is-active --quiet monado.socket 2>/dev/null; then
  echo "monado.socket is active; run: systemctl --user stop monado.socket monado.service" >&2
  exit 1
fi
if pgrep -x monado-service >/dev/null; then
  echo "monado-service is already running; stop it first" >&2
  exit 1
fi
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ]; then
  echo "warning: no WAYLAND_DISPLAY or DISPLAY; the compositor needs a session" >&2
fi

# Build and print the store path; a failed build exits non-zero.
out=$(nix build --no-link --print-out-paths .#monado)
if [ ! -x "$out/bin/monado-service" ]; then
  echo "no monado-service in '$out'" >&2
  exit 1
fi

# Keep the OpenXR registration pointing at the build we are about to run.
"$repo/tools/set-openxr-runtime.sh"

# A stale pid file makes the next start exit 255.
rm -f "$XDG_RUNTIME_DIR/monado.pid"

export XR_RUNTIME_JSON="$out/share/openxr/1/openxr_monado.json"
export XRT_NO_STDIN=1 # stdin need not be epollable
export XRT_COMPOSITOR_LOG="${XRT_COMPOSITOR_LOG:-info}"

echo "monado:  $out"
echo "clients: XR_RUNTIME_JSON=$XR_RUNTIME_JSON xrgears"
echo

exec "$out/bin/monado-service"
