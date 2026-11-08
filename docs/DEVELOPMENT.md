# DroneSim development notes — 0.3.3

Keyboard quadcopter racing in a 40 × 60 × 18 m hangar, for macOS and Windows.

For installation and flying, see the [README](../README.md) and [user guide](../USER_GUIDE.md).
Only the latest application packages are published; source history is retained.

## Run (from the repository root)

Open `godot/project.godot` in Godot, or set `GODOT_BIN` and run `./run.sh`.
Standalone packages are in `build/`: unzip the macOS app or the Windows folder.
On Windows, run `DroneSim.exe` (no Godot installation required).
For source development, open `godot/project.godot` in Godot 4.7.2 or set
`GODOT_BIN` to a suitable executable before running the launcher.

## Setup and controls

Escape always opens/closes the setup panel. Its Quit button or Q exits the game (Q still types normally in text fields). Its tabs contain flight options,
LAN connection settings and full keyboard/mouse bindings. Every action has
three binding slots. Click a slot, then press a key, mouse button or wheel.
Backspace/Delete clears; Escape cancels capture. Duplicate assignments are
rejected. All actions are rebindable; Escape remains a recovery shortcut.
Preferences and bindings save locally in Godot's per-user DroneSim data directory.
Keyboard bindings refer to physical keys, so their positions survive layout changes.

| Default | Action |
| --- | --- |
| W / S | Pitch forwards / backwards |
| A / D | Roll left / right |
| Left / right | Yaw left / right |
| Up / down | Climb / descend |
| Space, held | Brake horizontally and hold height |
| H | Toggle altitude hold / manual collective |
| C | Chase / FPV camera |
| R | Reset drone and begin a new attempt |
| P | Pause / resume |
| F2 / Escape | Setup |
| N | LAN tab |
| Q / F10 | Quit |

Altitude hold is initially enabled. Release pitch/roll to level the drone;
horizontal velocity persists. Hold Space to brake. Manual collective centres on
nominal hover thrust and requires managing height yourself. Red rotors mark the nose.

## Course and timing

Press Up to arm the motors and take off from the green starting plinth. Cross every numbered rectangular gate in the selected course
in order, following the dotted blue suggested route, then land on the purple
finishing plinth. Green marks the next gate; cyan marks the one after it. Gates
must be crossed forwards through the clear aperture, allowing for the drone's
size. The timer starts when the drone leaves contact with the starting plinth.

The finish requires all gates of the selected course, contact within the finish plinth, speed below
0.5 m/s and 0.5 seconds of stable landing. The recorded time is backdated to the
start of that stable contact. Crashing, pausing, opening setup or losing focus
invalidates an airborne attempt. Reset to retry. Reset retains your best time;
saved personal bests remain when hosting, joining or disconnecting.
Times resolve to the 120 Hz physics tick, despite displaying three decimals.

## LAN ghost race

Either Mac or Windows can host up to eight pilots. Everyone must use version
0.3.3 and the same selected course. Open **Setup → LAN race**:

1. Host selects the UDP port (default **24568**) and clicks **HOST**.
2. Other pilots enter the host's LAN IP and the same port, then click **JOIN**.
3. Close setup and fly. Each pilot starts their own timer on takeoff.

Allow the chosen UDP port through the host firewall if prompted. The panel shows
local IP addresses. There is no automatic host discovery or Internet matchmaking.
Remote competitors are translucent, labelled visual ghosts with **no collision
bodies**. They cannot hit you or push you off course; everyone still collides
with the hangar and gates. Position updates are interpolated at each client.
The leaderboard ranks best completed times in ascending order: **fastest wins**.
There is no common countdown or fixed end to the session. Times are self-reported
by each pilot, suitable for friendly racing rather than cheat-resistant competition.

The ENet transport and three-slot input-binding approach are adapted from the
local Elite/Dogfight project. No Elite game assets are included. LAN race state,
course, UI and drone dynamics are specific to DroneSim. Voice chat is not included.

## Model

SI units; 120 Hz six-degree-of-freedom rigid-body integration. Forces act at
individual rotor positions, so attitude emerges from torque rather than directly
setting orientation. The attitude/rate controller commands the motors; it does
not overwrite position, velocity or angular rates. The flight HUD displays compass, attitude and vertical-speed instruments.

| Parameter | Representative value |
| --- | --- |
| Mass | 1.2 kg |
| Body principal inertia X/Y/Z | 0.025 / 0.045 / 0.025 kg m² |
| Rotor offsets | ±0.19 m in body X/Z |
| Gravity | 9.81 m/s² |
| Air density | 1.225 kg/m³ |
| Maximum rotor speed | 9000 RPM |
| Maximum thrust | 7 N per rotor at reference density |
| Motor speed time constants | 45 ms up / 80 ms down |
| Reaction torque / thrust | 0.018 m |
| Rotor rotational inertia | 3 × 10⁻⁶ kg m² each |
| Body drag Cd A, X/Y/Z | 0.045 / 0.080 / 0.045 m² |

Thrust and aerodynamic propeller torque scale with rotor speed squared. Motor
speed approaches its commanded value exponentially; thrust therefore has a
nonlinear transient. Motors retain residual thrust while spinning down. The
model includes reaction torque from rotor acceleration and the gyroscopic torque
of the net spinning-rotor angular momentum. The mixer preserves requested torque
proportions when motor authority is exhausted, at the cost of tracking performance.

Body drag is quadratic in **body-frame air-relative velocity** with separate
projected areas per axis. In-plane rotor drag scales with airspeed and the square
root of total thrust. Rotational aerodynamic damping opposes body angular rates.
Godot's generic linear/angular damping is disabled to avoid double-counting.
`wind_velocity` is a world-frame input, initially zero. Physical parameters are
exposed on the drone script for tuning; runtime mass/inertia changes should also
update the corresponding rigid-body properties.

These are physically motivated approximations, not a validated model of a
particular airframe. No ground effect, vortex ring state, detailed blade-element
inflow, battery depletion or flexible propellers. Collision box remains
0.58 × 0.22 × 0.58 m. Chase camera may be occluded by obstacles. Menus freeze
only your drone; the LAN session continues.

## Build and verify

`build.sh` is a **macOS/zsh** script: it uses `codesign` and `/usr/bin/ditto`.
It needs Godot 4.7.2 and matching Windows x86-64 and universal macOS export
templates. It is not a Windows or generic Linux build script. Set `GODOT_BIN`
to an executable absolute path, or install Godot in one of the locations supported
by `run.sh`. `.tools/` is a local convenience, not a repository dependency.

The following commands are for macOS/zsh, from the repository root:


```sh
./build.sh
./run.sh --headless --log-file /tmp/dronesim-flight.log --script res://test_flight.gd
./run.sh --headless --log-file /tmp/dronesim-features.log --script res://test_features.gd
./run.sh --headless --script res://test_results.gd
./run.sh --headless --script res://test_courses.gd
./run.sh --headless --script res://test_hud.gd
./run.sh --headless --script res://test_takeoff.gd
./run.sh --headless --script res://test_dynamics.gd
# Requires permission to open UDP sockets:
./run.sh --headless --log-file /tmp/dronesim-lan.log --script res://test_features.gd -- --lan
```

The build requires Godot 4.7.2 with Windows x86-64 and macOS export templates.
It produces both platform packages and runs feature checks first. Source tests
cover flight physics, course direction/aperture/landing, invalidation, bindings,
settings panel behaviour, ghost collision absence and leaderboard data validation.
Additional dynamics checks cover RPM lag, thrust scaling, spin-down, anisotropic
drag, force/torque allocation, saturation, unassisted angular acceleration and
motors-off free fall. The optional live ENet check connects a host/client over loopback, exchanges
states and times, and checks disconnect cleanup. Version 0.2.3 was manually tested on Windows and over LAN by Frazer Pearce,
who reported both working. The multi-course changes in 0.3.3 have not yet been
manually validated across machines. Windows cross-export alone does not
constitute Windows gameplay testing.

Godot's MIT licence is in `GODOT_LICENSE.txt`. Godot third-party component
licences are available at https://godotengine.org/license/.

## Course architecture

`godot/course_catalog.gd` defines the ten named courses, difficulty hints,
clear gate apertures and waypoints. `course.gd` rebuilds gate collision geometry,
labels and the suggested route when selection changes. The aperture test includes
a conservative drone footprint margin. Timers, gate progress and spawn state
reset on a change; best times are saved per player and course across launches.

The selection is exposed in Escape → Flight & course. LAN snapshots include the
host's selected course; clients apply it before rendering other pilots' states.
Client course changes are disabled while connected. Pilot state validation checks
the gate count against that pilot's advertised course. Ghosts and leaderboard
rows are filtered to the active course. All peers require version 0.3.3.

`test_courses.gd` checks all ten gate lists, aperture direction, finish detection,
per-course best restoration, course-length packet validation and the Escape
selector. Run it with `./run.sh --headless --script res://test_courses.gd`.

## Saved result profiles

`godot/results.gd` stores versioned JSON in `user://times.json`, keyed by a trimmed,
case-insensitive player name and stable course ID. Only positive, finite best
times are retained. Writes use a temporary file and rename; unreadable or malformed
originals are preserved. The Escape Best times table lists all locally known
players. Completed LAN bests are retained locally; no cloud sync or authentication
is implied. Changing the active name restores that profile's times and invalidates
an airborne attempt. New runs cannot be credited to a different name midway.

Scripted scene fixtures set `test_mode` before adding the scene to the tree so
synthetic completions never read or overwrite real player histories. Persistence
tests use isolated temporary files and exercise reloads, multiple names/courses,
best-only updates, profile switching and corrupt-file preservation.

Course display order can change independently of saved results: each catalogue
entry has an explicit stable ID. Courses 9 and 10 were swapped in 0.3.3 without
moving old results to a different route. Legacy numeric course preferences are
translated to their original stable IDs. The Total column sums the ten current
routes' personal bests only when all ten exist; unrelated saved IDs are ignored.
