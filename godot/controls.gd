class_name DroneControls
extends RefCounted

const SLOT_COUNT := 3
# Negative codes distinguish mouse buttons from physical keyboard keys.
const MOUSE_LABELS := {1:"Mouse Left",2:"Mouse Right",3:"Mouse Middle",4:"Wheel Up",5:"Wheel Down",6:"Wheel Left",7:"Wheel Right",8:"Mouse Back",9:"Mouse Forward"}
const DEFAULTS := {
 "pitch_forward":[KEY_W], "pitch_back":[KEY_S], "roll_left":[KEY_A], "roll_right":[KEY_D],
 "yaw_left":[KEY_LEFT], "yaw_right":[KEY_RIGHT], "climb":[KEY_UP], "descend":[KEY_DOWN],
 "brake":[KEY_SPACE], "camera":[KEY_C], "altitude":[KEY_H], "reset":[KEY_R],
 "pause":[KEY_P], "setup":[KEY_F2], "network":[KEY_N], "quit":[KEY_Q,KEY_F10]}
const LABELS := {"pitch_forward":"Pitch forwards", "pitch_back":"Pitch backwards", "roll_left":"Roll left", "roll_right":"Roll right", "yaw_left":"Yaw left", "yaw_right":"Yaw right", "climb":"Climb", "descend":"Descend", "brake":"Brake / hold", "camera":"Switch camera", "altitude":"Altitude hold", "reset":"Reset / new attempt", "pause":"Pause", "setup":"Setup panel", "network":"LAN panel", "quit":"Quit"}
const STEERING := ["pitch_forward","pitch_back","roll_left","roll_right","yaw_left","yaw_right","climb","descend","brake"]
var bindings: Dictionary=DEFAULTS.duplicate(true)
var path := ""
var error := ""

static func valid_key(code: int) -> bool:
 return MOUSE_LABELS.has(-code) if code<0 else code>0 and code<0x1000000 and code != KEY_ESCAPE

static func event_code(event: InputEvent) -> int:
 if event is InputEventKey:
  return event.physical_keycode
 if event is InputEventMouseButton and MOUSE_LABELS.has(event.button_index):
  return -event.button_index
 return 0

static func is_wheel(code: int) -> bool:
 return code in [-MOUSE_BUTTON_WHEEL_UP,-MOUSE_BUTTON_WHEEL_DOWN,-MOUSE_BUTTON_WHEEL_LEFT,-MOUSE_BUTTON_WHEEL_RIGHT]

func assign_key(action: String,slot: int,code: int) -> bool:
 error=""
 if not bindings.has(action) or slot<0 or slot>=SLOT_COUNT:
  return false
 if code!=0 and not valid_key(code):
  error="Escape stays reserved for opening/closing setup."
  return false
 if code!=0:
  for other in bindings:
   for index in range(SLOT_COUNT):
    if key_at(other,index)==code and (other!=action or index!=slot):
     error="Already used by "+LABELS[other]+". Clear that slot first, or choose another key."
     return false
 var pair: Array=bindings[action].duplicate()
 pair.resize(SLOT_COUNT)
 pair[slot]=code
 for i in range(SLOT_COUNT):
  if pair[i]==null:
   pair[i]=0
 bindings[action]=pair
 return true

func key_at(action: String,slot: int) -> int:
 var pair: Array=bindings[action]
 return int(pair[slot]) if slot<pair.size() else 0

func key_label(action: String,slot: int,compact: bool=false) -> String:
 var code := key_at(action,slot)
 if code<0:
  if compact and -code in [1,2,3]:
   return {1:"LMB",2:"RMB",3:"MMB"}[-code]
  return MOUSE_LABELS.get(-code,"Unbound")
 return OS.get_keycode_string(code) if code else "Unbound"

func matches(action: String,code: int) -> bool:
 return code!=0 and bindings[action].has(code)

func strength(action: String,held_keys: Dictionary) -> float:
 for code in bindings[action]:
  if code!=0 and held_keys.has(code):
   return 1.0
 return 0.0

func restore_defaults() -> void:
 bindings=DEFAULTS.duplicate(true)

func save() -> Error:
 if path.is_empty(): return OK
 var config := ConfigFile.new()
 for action in bindings: config.set_value("bindings",action,bindings[action])
 return config.save(path)

func load_file(filename: String) -> bool:
 path = filename
 var config := ConfigFile.new()
 if config.load(path) != OK: return false
 var proposed := {}
 var used := {}
 for action in DEFAULTS:
  var pair: Variant = config.get_value("bindings",action,DEFAULTS[action])
  if not pair is Array or pair.size() > SLOT_COUNT: return false
  for code in pair:
   if not code is int or (code != 0 and (not valid_key(code) or used.has(code))): return false
   if code != 0: used[code] = true
  proposed[action] = pair.duplicate()
 bindings = proposed
 return true
