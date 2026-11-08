extends RefCounted
# Local profiles: canonical player name -> best time by stable course ID.
var path := "user://times.json"
var players := {}
var error := ""

static func key(name: String) -> String:
 return name.strip_edges().left(24).to_lower()

func best(name: String, course: String) -> float:
 var profile: Dictionary = players.get(key(name),{})
 return float(profile.get("times",{}).get(course,0.0))

func record(name: String, course: String, seconds: float) -> bool:
 if key(name).is_empty() or not is_finite(seconds) or seconds<=0 or seconds>86400: return false
 var id := key(name)
 var profile: Dictionary = players.get(id,{"name":name.strip_edges().left(24),"times":{}})
 var previous := float(profile.times.get(course,0.0))
 if previous>0 and previous<=seconds: return false
 profile.name = name.strip_edges().left(24)
 profile.times[course] = seconds
 players[id] = profile
 save()
 return true

func load_file() -> bool:
 error = ""
 if path.is_empty() or not FileAccess.file_exists(path): return true
 var file := FileAccess.open(path,FileAccess.READ)
 if file==null:
  error="Could not read saved times"
  return false
 var parser := JSON.new()
 var parse_result := parser.parse(file.get_as_text())
 var parsed: Variant = parser.data if parse_result==OK else null
 if not parsed is Dictionary or parsed.get("version")!=1 or not parsed.get("players") is Dictionary:
  error="Saved times format is invalid; original file preserved"
  return false
 var clean := {}
 for id in parsed.players:
  var profile: Variant = parsed.players[id]
  if not id is String or not profile is Dictionary or not profile.get("name") is String or not profile.get("times") is Dictionary: continue
  if key(profile.name)!=id or id.is_empty(): continue
  var times := {}
  for course in profile.times:
   var value: Variant = profile.times[course]
   if course is String and (value is int or value is float) and is_finite(float(value)) and value>0 and value<=86400: times[course]=float(value)
  clean[id]={"name":profile.name.left(24),"times":times}
 players=clean
 return true

func save() -> bool:
 if path.is_empty(): return true
 # Never overwrite an unreadable or malformed original.
 if not error.is_empty(): return false
 var temp := path+".tmp"
 var file := FileAccess.open(temp,FileAccess.WRITE)
 if file==null:
  error="Could not save times"
  return false
 file.store_string(JSON.stringify({"version":1,"players":players},"  "))
 file.flush()
 var result := file.get_error()
 file.close()
 if result==OK: result=DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(path))
 if result!=OK:
  error="Could not save times: "+error_string(result)
  return false
 return true

func total(name: String) -> float:
 var sum := 0.0
 for course in preload("res://course_catalog.gd").COURSES:
  var seconds := best(name,course.id)
  if seconds<=0: return 0.0
  sum+=seconds
 return sum
