# DroneSim — A Free Drone Flight Demonstrator

DroneSim is a small, free, physics-based drone flying game for Windows and macOS.

Fly a virtual quadcopter around an indoor course using your keyboard. Practise
taking off, hovering, navigating gates and landing, or race against other
players over a local network.

The flight model is deliberately simplified. DroneSim is intended to demonstrate
the principles of drone control, not to replace a professional flight simulator
or real-world training.

No specialist hardware, account or internet connection is required to play.
You need an internet connection to download it, and a local network for multiplayer.

Developed by **Frazer Pearce** as an experiment in rapid, AI-assisted software creation.

## Download and install

**Latest release: 0.3.1** — ten selectable courses, analogue flight instruments,
LAN ghost racing and saved best times by player/course. Both platform downloads
below include the game and its guides; **Godot is not required to play**.

| Platform | Download |
| --- | --- |
| Windows (64-bit Intel/AMD) | [DroneSim-0.3.1-Windows.zip](https://github.com/frazerpearce/DroneSim/releases/download/v0.3.1/DroneSim-0.3.1-Windows.zip) |
| macOS (Apple Silicon and Intel) | [DroneSim-0.3.1-macOS.zip](https://github.com/frazerpearce/DroneSim/releases/download/v0.3.1/DroneSim-0.3.1-macOS.zip) |

Download the ZIP for your platform using the direct links above, then extract it.
The source-code ZIP offered by GitHub is for developers; it is not the packaged game.

Each download includes the guide for its own release. On Windows it is next to
`DroneSim.exe`; inside the macOS app it is under `Contents/Resources/` (Finder →
Show Package Contents). The guides linked in this repository describe **0.3.1**.

The downloaded game itself has no account or sign-in requirement.

### Windows

1. Download `DroneSim-0.3.1-Windows.zip`.
2. Right-click the ZIP and choose **Extract All**.
3. Open the extracted `windows` folder and run **DroneSim.exe**.

There is no installer and Godot does not need to be installed. Use 64-bit Windows
on an Intel or AMD PC. The build is unsigned, so Windows may display a reputation
warning. Only proceed if you recognise and trust the downloaded file.

### macOS

1. Download `DroneSim-0.3.1-macOS.zip` and double-click to extract it.
2. Drag **DroneSim.app** to Applications, or keep it in a folder of your choice.
3. Open **DroneSim.app**.

The app is built for Apple Silicon and Intel Macs. It is ad-hoc signed rather
than Apple-notarised. If macOS blocks opening it, use **System Settings → Privacy
& Security → Open Anyway** for the app, then confirm that you want to open it.
Do this only for a download you trust; there is no need to disable Gatekeeper.

## Your first flight

1. Start the game. The drone rests on the green starting plinth.
2. Hold **Up Arrow** to arm the motors and climb. Release it at a comfortable height.
3. With altitude hold enabled by default, the drone maintains approximately that height.
4. Use **W/S** to pitch forwards/backwards and **A/D** to roll left/right.
5. Release the steering keys to level the drone. It still carries momentum:
   hold **Space** to brake.
6. Use **Down Arrow** to descend gently onto a plinth. Press **R** to reset after a crash.

The red front rotors mark the nose. Steering follows the drone's orientation,
so yawing changes which way “forwards” points. **C** switches between chase and
onboard FPV views. Chase view is a useful place to start.

## Flight instruments

The HUD uses analogue instruments rather than numerical flight telemetry:

- **Direction:** rotating compass; white arrow shows horizontal travel and blue
  points towards the next gate (or the finish plinth).
- **Tilt:** artificial horizon showing pitch and bank against a fixed aircraft reference.
- **Rise / fall:** upward or downward arrow; a centred dot indicates approximately level flight.
- **Course lamps:** completed gates turn green; the next gate is blue.

Race times and leaderboard results remain numerical.

## Saved best times

Open **Escape → Best times** for a compact player-by-course table. Each cell is
the fastest completed time for that player and course; a dash means no result.
Course numbers are explained below the table, with full names in cell tooltips.

Enter a pilot name in **Flight & course**, then press Enter or leave the field
to load that player's saved results. Names ignore case and surrounding spaces.
Changing player during a run invalidates the attempt, so results cannot be
accidentally assigned to a different pilot. Changing course loads the matching best.

Times save automatically on this computer and survive restarts and LAN disconnects.
Completed best times received from LAN competitors are also retained by name.
These are local profiles, not accounts or authenticated identities; no cloud sync
is involved. The data is in `times.json` in Godot's per-user DroneSim data directory.

## Default controls

| Key | Action |
| --- | --- |
| W / S | Pitch forwards / backwards |
| A / D | Roll left / right |
| Left / Right Arrow | Yaw left / right |
| Up / Down Arrow | Climb / descend |
| Space, held | Brake horizontally and hold height |
| H | Toggle altitude hold / manual collective |
| C | Switch chase / FPV camera |
| R | Reset drone and course attempt |
| P | Pause / resume |
| Escape / F2 | Open setup |
| N | Open LAN panel |
| Q / F10 | Quit |

**Escape** opens setup, including flight options, camera field of view, pilot
name, LAN settings and key bindings. There is also a **Quit** button. Q quits
from the setup panel unless you are typing into a text field or assigning a binding.

Every action has up to three bindings: keys, mouse buttons or the mouse wheel.
Click a binding slot, then press the desired input. Backspace/Delete clears it;
Escape cancels assignment. Duplicate bindings are rejected. Escape always remains
available to open/close setup. Preferences save locally between runs.

## Choose a course

Open **Escape → Flight & course** and select a course from the dropdown.
Changing course resets the drone to the starting plinth and clears the current
attempt. Each course retains its own best time between launches under the pilot name. Your course
choice is remembered for the next launch. Difficulty labels are design targets,
not ratings established through user testing.

| Course | Difficulty | Gates | Clear opening | Focus |
| --- | --- | --- | --- | --- |
| First Flight | Beginner | 6 | 5.0 × 4.0 m | Level flight, wide openings |
| Gentle Slalom | Easy | 6 | 4.8 × 3.8 m | Side-to-side control |
| Step Up | Easy | 6 | 4.6 × 3.6 m | Progressive climbs and descent |
| Hangar Circuit | Moderate | 6 | 4.4 × 3.4 m | Original circuit |
| Switchbacks | Moderate | 7 | 4.2 × 3.4 m | Braking and reversals |
| Rollercoaster | Challenging | 7 | 4.0 × 3.2 m | Alternating height changes |
| Precision Run | Challenging | 7 | 2.8 × 2.8 m | Accurate alignment |
| High Wire | Hard | 8 | 3.0 × 2.8 m | High-level flight and descent |
| Technical Slalom | Expert | 9 | 2.5 × 2.6 m | Tight slalom with height changes |
| Master Circuit | Expert | 10 | 2.2 × 2.4 m | Long, narrow, mixed-height circuit |

In LAN play, **the host selects the course** and clients follow automatically.
The client selector is disabled while connected. A host course change resets
every pilot's attempt. Only times for the same course appear together on the
leaderboard; results are not compared across different courses.

## Fly the course

Take off from the **green start plinth**, pass through **every numbered gate of the selected course in order**, then land on the **purple finish plinth**.

- **Green gate:** the next gate to cross.
- **Cyan gate:** the gate after that.
- **Blue dotted pathway:** the suggested route; it can be hidden in setup.

Cross each gate through its opening, travelling in the direction of the course.
The timer starts when you lift off the starting plinth. The finish requires a
slow, stable landing on the finishing plinth after every gate. A half-second
of stable contact confirms the landing; the recorded time is taken from the
start of that contact.

Crashing, pausing, opening setup or losing window focus during a run invalidates
that attempt. Press **R** to try again. Your best completed time remains available
between launches under the pilot name. The display shows milliseconds, but timing resolves to the
120 Hz physics tick.

## Race over a local network

Up to **eight players** can share the hangar. Windows and macOS players can race
together; everyone must use the same game version.

1. On the host computer, open **Escape → LAN race** and click **HOST**.
2. Note the host's local IP address shown in the panel and its UDP port
   (default **24568**).
3. On each other computer, enter that host IP and matching port, then click **JOIN**.
4. Close setup and fly.

Allow the chosen UDP port through the host's firewall if prompted. This is local
network play, without automatic host discovery or internet matchmaking.

Other pilots appear as **translucent, labelled drones**. They have no collision
bodies: competitors cannot hit or push one another. The hangar and gates remain
solid for each pilot.

Each pilot starts their own timer on takeoff. The leaderboard ranks best valid
completed times: **fastest wins**. There is no shared countdown or fixed session
end. Hosting, joining or disconnecting clears remote live entries; saved personal bests remain. Times
are self-reported, suitable for friendly racing rather than cheat-resistant competition.

## About the flight model

The model includes mass, inertia, gravity, individual rotor thrusts, angular
motion, aerodynamic drag and motor response. Thrust scales with rotor RPM squared.
A stabilising flight controller sits above those dynamics, making keyboard flight
manageable. Switching off altitude hold makes height control more demanding.

The parameters describe a representative 1.2 kg quadcopter, not a calibrated
commercial drone. Ground effect, detailed propeller inflow and battery depletion
are omitted. The demonstrator illustrates basic control and momentum; proficiency
here does not establish competence with a real aircraft.

## Run the current source (0.3.1)

The repository contains **source code**, not a ready-to-run `.exe` or `.app`.
Cloning it or downloading GitHub's **Source code** ZIP does not install the game.
Install **Godot 4.7.2**, import/open **`godot/project.godot`**, then press **F5**
to run the configured main scene. No external
assets or package-manager dependencies are required.

To clone the repository:

```sh
git clone https://github.com/frazerpearce/DroneSim.git
cd DroneSim
```

On macOS, either double-click `Launch DroneSim.command` or run:

```sh
GODOT_BIN=/absolute/path/to/Godot.app/Contents/MacOS/Godot ./run.sh
```

`run.sh` uses zsh. It checks `GODOT_BIN`, then a local `.tools/Godot`, a `godot`
command on PATH, and `/Applications/Godot.app/Contents/MacOS/Godot`.
The `.tools/` directory is optional and is **not** included in the repository.

On Windows, use the Godot editor or PowerShell from the repository root:

```powershell
& 'C:\path\to\Godot.exe' --path .\godot
```

On Linux, use Godot directly from the repository root:

```sh
/path/to/godot --path ./godot
```

Linux source execution is available through Godot, but no Linux application
package is supplied or tested here.

## Repository layout and building

| Path in the repository | Purpose |
| --- | --- |
| `README.md` | Download status, installation and quick start |
| `USER_GUIDE.md` | Flying, instruments, courses, controls and saved times |
| `docs/DEVELOPMENT.md` | Physics parameters, tests and build details |
| `godot/project.godot` | Project to open in Godot |
| `godot/main.tscn`, `godot/main.gd` | Main scene, hangar and game loop |
| `godot/drone.gd` | Drone dynamics and controller |
| `godot/course_catalog.gd`, `godot/course.gd` | Ten course definitions and timing |
| `godot/flight_hud.gd`, `godot/setup.gd` | Analogue instruments and Escape panel |
| `godot/results.gd`, `godot/session.gd`, `godot/transport.gd` | Saved times and LAN racing |
| `godot/test_*.gd` | Automated checks (directly in `godot/`, not a `tests/` subfolder) |
| `godot/export_presets.cfg` | Windows and macOS export presets |
| `run.sh`, `Launch DroneSim.command` | Source launchers for macOS/zsh |
| `build.sh` | macOS build, checks, signing and packaging |
| `.github/workflows/release.yml` | Automated build/release workflow |
| `GODOT_LICENSE.txt` | Godot engine licence |

**Building both application packages requires macOS**, zsh, Godot 4.7.2 and its
matching macOS/Windows export templates. From the repository root:

```sh
GODOT_BIN=/absolute/path/to/Godot.app/Contents/MacOS/Godot ./build.sh
```

This runs the automated checks and creates:

- `build/windows/DroneSim.exe` and bundled guides;
- `build/DroneSim.app`, with guides in `Contents/Resources/`;
- `build/DroneSim-0.3.1-Windows.zip` and `build/DroneSim-0.3.1-macOS.zip`.

`build/`, `.tools/` and `godot/.godot/` are generated/local directories and are
excluded from Git. They will not appear in a fresh clone. See the
[development notes](docs/DEVELOPMENT.md) for individual test commands.

## Status and credits

Current release: **0.3.1**.

Built with [Godot](https://godotengine.org/). The engine's MIT licence is included
in [GODOT_LICENSE.txt](GODOT_LICENSE.txt); its third-party component notices are
available on [Godot's licence page](https://godotengine.org/license/).
