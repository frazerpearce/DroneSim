# DroneSim 0.3.2 — User guide

A keyboard-controlled flight demonstrator for Windows and macOS.
For download and installation, see [README.md](README.md). This guide covers
**0.3.2**, including the new marked landing zone. The currently published 0.3.1
downloads do not include the marker. Windows and macOS downloads are listed in
[GitHub Releases](https://github.com/frazerpearce/DroneSim/releases/latest).

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

The finish plinth has a pale-green outlined **LAND HERE** square. The drone's
**body centre** must be inside that 2.3 × 2.3 m square; the whole drone need not
fit within it. Touch down slowly and remain settled for half a second.

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

## Reading the instruments

The compass uses N/E/S/W for the hangar's fixed world directions. The amber
marker represents the drone's nose; the white arrow shows where it is actually
travelling. The blue arrow points towards the next course gate or finishing plinth.
An arrow to the side means you need to turn or translate towards that side;
it does not mean the drone has already turned.

In the tilt indicator, the amber aircraft reference stays fixed while the
blue sky/brown ground horizon moves. A flat, centred horizon means level
attitude. You can be level and still moving: watch the white travel arrow or
hold Space to brake.

The rise/fall arrow responds to actual vertical speed, not the climb key.
A green arrow points up while climbing; an amber arrow points down while
descending. A centred dot means little vertical movement. There are no
numerical flight telemetry readouts; race results remain numerical.

## If something goes wrong

- **The drone will not lift off:** return to flight from setup, resume if paused,
  press R to reset after a crash, then hold the bound Climb key (Up by default).
- **The drone keeps drifting:** releasing pitch/roll levels it but does not stop
  horizontal momentum. Hold Space to brake.
- **A gate does not count:** return to its approach side and cross the opening
  forwards. Gates count in order; clipping the frame does not count as a pass.
- **The timer does not finish:** complete every gate, then descend slowly onto
  the purple plinth and remain settled briefly.
- **A timed attempt becomes invalid:** reset after pausing, opening setup,
  losing window focus or crashing. Untimed flying is still available.
- **LAN connection fails:** check that both computers are on the same LAN,
  use matching game versions and UDP ports, and allow the host port through
  its firewall. Internet matchmaking is not provided.

The flight model is simplified and is not a substitute for real-world training.

## Saved times by player and course

**Escape → Best times** shows a small table with one row per player and ten
course columns. It retains the fastest completed time in each cell and saves
automatically. Enter a name under **Flight & course**, then press Enter or leave
the field to load that player's history. Capitalisation and surrounding spaces
do not create a new player. Changing names invalidates an airborne attempt.

Your personal bests persist across restarts, course changes and LAN disconnects.
LAN competitors' received bests are saved locally too. These names are labels,
not verified accounts; sharing the same name shares a local score history.
