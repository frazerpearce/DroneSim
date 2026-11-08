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

**Current development version: 0.3.1** — ten selectable courses and analogue flight instruments.

The published downloads below are **0.2.3** (the original single-course release).
The new 0.3.1 packages are built locally; their upload is pending. To use the new
courses immediately, run the current source with Godot.

| Platform | Download |
| --- | --- |
| Windows (64-bit Intel/AMD) | [DroneSim-0.2.3-Windows.zip](https://github.com/frazerpearce/DroneSim/releases/download/v0.2.3/DroneSim-0.2.3-Windows.zip) |
| macOS (Apple Silicon and Intel) | [DroneSim-0.2.3-macOS.zip](https://github.com/frazerpearce/DroneSim/releases/download/v0.2.3/DroneSim-0.2.3-macOS.zip) |

Only the latest packaged version is offered in [GitHub Releases](https://github.com/frazerpearce/DroneSim/releases/latest).
Open **Assets** and select the ZIP for your platform. The source-code ZIP offered
by GitHub is for developers; it is not the packaged game.

The downloads include a [user guide](USER_GUIDE.md). The source history is retained for development.

### Windows

1. Download `DroneSim-0.2.3-Windows.zip`.
2. Right-click the ZIP and choose **Extract All**.
3. Open the extracted `windows` folder and run **DroneSim.exe**.

There is no installer and Godot does not need to be installed. Use 64-bit Windows
on an Intel or AMD PC. The build is unsigned, so Windows may display a reputation
warning. Only proceed if you recognise and trust the downloaded file.

### macOS

1. Download `DroneSim-0.2.3-macOS.zip` and double-click to extract it.
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

## Run or develop from source

Install **Godot 4.7.2** and open `godot/project.godot`, then run the project from
the editor. The game uses the compatibility renderer and no external game assets.

On macOS or Linux, a command-line Godot installation can also run it:

```sh
git clone https://github.com/frazerpearce/DroneSim.git
cd DroneSim
GODOT_BIN=/path/to/godot ./run.sh
```

On Windows, open the project in Godot or run:

```powershell
& 'C:\path\to\Godot.exe' --path .\godot
```

See the [user guide](USER_GUIDE.md) for flying and racing, and [development notes](docs/DEVELOPMENT.md) for model parameters, build requirements
and test commands. `.tools/`, generated Godot caches and `build/` are excluded
from source control. The release workflow builds both platforms on macOS and
publishes ZIP files to GitHub Releases after its checks pass.

## Status and credits

Current development version: **0.3.1**. **Version 0.2.3 was tested successfully
on Windows and over LAN by Frazer Pearce.** This replaces the earlier unverified
platform/network status for that version. The new multi-course selection and
host/client course synchronisation have automated coverage where possible, but
still require interactive testing on Windows and across a live LAN.

The local automated checks cover flight dynamics, takeoff after idling,
all ten course layouts and completion, key bindings, instruments and ghost-race
state. Headless checks are not a substitute for interactive testing.

Built with [Godot](https://godotengine.org/). The engine's MIT licence is included
in [GODOT_LICENSE.txt](GODOT_LICENSE.txt); its third-party component notices are
available on [Godot's licence page](https://godotengine.org/license/).
