#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

export PATH="$HOME/.local/share/mise/shims:$PATH"

mix ecto.migrate
exec mix phx.server
