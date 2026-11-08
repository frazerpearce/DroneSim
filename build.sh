#!/bin/zsh
set -eu
cd "${0:A:h}"
version=$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' godot/project.godot)
[[ -n "$version" ]]
mkdir -p build/windows
# An isolated portable editor keeps export temporary files in this project.
if [[ -z "${GODOT_BIN:-}" && -x "$PWD/.tools/Godot" ]]; then export GODOT_BIN="$PWD/.tools/Godot"; fi
./run.sh --headless --log-file /tmp/dronesim-import.log --editor --import --quit
./run.sh --headless --log-file /tmp/dronesim-results.log --script res://test_results.gd
./run.sh --headless --log-file /tmp/dronesim-courses.log --script res://test_courses.gd
./run.sh --headless --log-file /tmp/dronesim-hud.log --script res://test_hud.gd
./run.sh --headless --log-file /tmp/dronesim-checks.log --script res://test_features.gd
./run.sh --headless --log-file /tmp/dronesim-takeoff.log --script res://test_takeoff.gd
./run.sh --headless --log-file /tmp/dronesim-dynamics.log --script res://test_dynamics.gd
./run.sh --headless --log-file /tmp/dronesim-flight.log --script res://test_flight.gd
./run.sh --headless --log-file /tmp/dronesim-export.log --export-release 'Windows Desktop'
./run.sh --headless --log-file /tmp/dronesim-macos.log --export-release macOS
cp README.md USER_GUIDE.md GODOT_LICENSE.txt build/windows/
cp README.md USER_GUIDE.md GODOT_LICENSE.txt build/DroneSim.app/Contents/Resources/
mkdir -p build/windows/docs build/DroneSim.app/Contents/Resources/docs
cp docs/DEVELOPMENT.md build/windows/docs/
cp docs/DEVELOPMENT.md build/DroneSim.app/Contents/Resources/docs/
codesign --force --deep --sign - build/DroneSim.app
codesign --verify --deep --strict build/DroneSim.app
/usr/bin/ditto -c -k --keepParent build/windows "build/DroneSim-$version-Windows.zip"
/usr/bin/ditto -c -k --keepParent build/DroneSim.app "build/DroneSim-$version-macOS.zip"
