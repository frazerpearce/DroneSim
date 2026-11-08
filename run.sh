#!/bin/zsh
set -eu
cd "${0:A:h}"
engine="${GODOT_BIN:-}"
if [[ -z "$engine" ]]; then
  if [[ -x "$PWD/.tools/Godot" ]]; then
    engine="$PWD/.tools/Godot"
  elif command -v godot >/dev/null 2>&1; then
    engine="$(command -v godot)"
  elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
    engine=/Applications/Godot.app/Contents/MacOS/Godot
  else
    print -u2 'Open godot/project.godot in Godot, or set GODOT_BIN to your Godot 4 executable.'
    exit 1
  fi
fi
if [[ ! -x "$engine" ]]; then
  print -u2 "Godot executable not found: $engine"
  exit 1
fi
exec "$engine" --path "$PWD/godot" "$@"
