extends Node3D
const Catalog = preload("res://course_catalog.gd")
var selected := 0
var POINTS: Array = Catalog.COURSES[0].points
const START := Vector3(0,0.5,8)
const FINISH := Vector3(8,0.5,20)
const FINISH_HALF_WIDTH := 1.15 # drone body centre, not the full footprint
const SPAWN := START + Vector3(0,0.18,0)
var best_times := {}
var gate_width := 5.0
var gate_height := 4.0
var geometry: Node3D
func title() -> String: return Catalog.COURSES[selected].name
func course_id() -> String: return "hangar-%02d-v1" % (selected+1)
var game: Node3D
var next_gate := 0
var state := "READY"
var seconds := 0.0
var best := 0.0
var landed_for := 0.0
var armed := false
var previous := SPAWN
var frames: Array[Node3D] = []
var labels: Array[Label3D] = []
var normals: Array[Vector3] = []
var route: Node3D
signal completed(time: float)

func _ready() -> void:
 rebuild()

func select(index: int) -> void:
 best_times[selected] = best
 selected = clampi(index,0,Catalog.COURSES.size()-1)
 var spec: Dictionary = Catalog.COURSES[selected]
 POINTS = spec.points
 gate_width = spec.width
 gate_height = spec.height
 best = best_times.get(selected,0.0)
 rebuild()
 reset_run()

func rebuild() -> void:
 var show_route := route.visible if is_instance_valid(route) else true
 if is_instance_valid(geometry):
  remove_child(geometry)
  geometry.queue_free()
 frames.clear()
 labels.clear()
 normals.clear()
 geometry = Node3D.new()
 add_child(geometry)
 for pair in [[START,Color(0.1,0.7,0.5),"START"],[FINISH,Color(0.5,0.3,0.9),"FINISH"]]:
  game.block(geometry,pair[0]-Vector3(0,0.25,0),Vector3(3,0.5,3),pair[1])
  var text := Label3D.new()
  text.text = pair[2]
  text.position = pair[0]+Vector3(0,0.02,-1.34 if pair[2]=="FINISH" else 0)
  text.rotation_degrees.x = -90
  text.font_size = 50 if pair[2]=="FINISH" else 100
  geometry.add_child(text)
 # The outside edge of this painted square is the timer's centre-position limit.
 var zone := Node3D.new()
 zone.name = "LandingZone"
 zone.position = FINISH
 geometry.add_child(zone)
 game.block(zone,Vector3(0,0.004,0),Vector3(2*FINISH_HALF_WIDTH,0.004,2*FINISH_HALF_WIDTH),Color(0.08,0.32,0.24),false)
 var line := 0.045
 for offset in [-1,1]:
  game.block(zone,Vector3(offset*(FINISH_HALF_WIDTH-line/2),0.009,0),Vector3(line,0.004,2*FINISH_HALF_WIDTH),Color(0.7,1,0.8),false)
  game.block(zone,Vector3(0,0.009,offset*(FINISH_HALF_WIDTH-line/2)),Vector3(2*FINISH_HALF_WIDTH,0.004,line),Color(0.7,1,0.8),false)
 for x in [-0.25,0.25]:
  game.block(zone,Vector3(x,0.012,-0.15),Vector3(0.06,0.004,0.6),Color.WHITE,false)
 game.block(zone,Vector3(0,0.012,-0.15),Vector3(0.5,0.004,0.06),Color.WHITE,false)
 var caption := Label3D.new()
 caption.text = "LAND HERE"
 caption.position = Vector3(0,0.02,0.7)
 caption.rotation_degrees.x = -90
 caption.font_size = 36
 zone.add_child(caption)
 var last := START
 for i in range(POINTS.size()):
  var p: Vector3 = POINTS[i]
  var normal := (p-last)*Vector3(1,0,1)
  normal = normal.normalized()
  normals.append(normal)
  var frame := Node3D.new()
  geometry.add_child(frame)
  frame.position = p
  frame.rotation.y = atan2(normal.x,normal.z)
  frames.append(frame)
  for x in [-gate_width/2-0.11,gate_width/2+0.11]:
   game.block(frame,Vector3(x,0,0),Vector3(0.22,gate_height+0.44,0.25),Color.ORANGE)
  for y in [-gate_height/2-0.11,gate_height/2+0.11]:
   game.block(frame,Vector3(0,y,0),Vector3(gate_width+0.44,0.22,0.25),Color.ORANGE)
  var label := Label3D.new()
  label.position = Vector3(0,gate_height/2+0.6,0)
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.font_size = 64
  frame.add_child(label)
  labels.append(label)
  last = p
 route = Node3D.new()
 geometry.add_child(route)
 route.visible = show_route
 var points: Array = [START+Vector3(0,2.5,0)]
 points.append_array(POINTS)
 points.append(FINISH+Vector3(0,1,0))
 for i in range(points.size()-1):
  var a: Vector3 = points[i]
  var b: Vector3 = points[i+1]
  var count := ceili(a.distance_to(b)/0.8)
  for j in range(count):
   var dot_mesh := MeshInstance3D.new()
   var sphere := SphereMesh.new()
   sphere.radius = 0.055
   sphere.height = 0.11
   dot_mesh.mesh = sphere
   dot_mesh.material_override = game.material(Color(0.3,0.85,1))
   dot_mesh.position = a.lerp(b,float(j)/count)
   route.add_child(dot_mesh)
 refresh()

func refresh() -> void:
 for i in range(frames.size()):
  var colour := Color(0.25,0.3,0.35) if i<next_gate else (Color(0.25,1,0.35) if i==next_gate else (Color(0.2,0.8,1) if i==next_gate+1 else Color(1,0.55,0.12)))
  labels[i].text = "%d%s" % [i+1," NEXT" if i==next_gate else (" THEN" if i==next_gate+1 else "")]
  labels[i].modulate = colour
  for body in frames[i].get_children():
   if body is StaticBody3D:
    for child in body.get_children():
     if child is MeshInstance3D: child.material_override.albedo_color = colour

func reset_run() -> void:
 next_gate = 0
 state = "READY"
 armed = false
 seconds = 0
 landed_for = 0
 previous = SPAWN
 refresh()

func invalidate(reason: String) -> void:
 if state == "FLYING": state = reason

func crossed(index: int, a: Vector3, b: Vector3) -> bool:
 var centre: Vector3 = POINTS[index]
 var normal := normals[index]
 var da := (a-centre).dot(normal)
 var db := (b-centre).dot(normal)
 if da >= 0 or db < 0: return false
 var hit := a.lerp(b,-da/(db-da))-centre
 var right := Vector3(normal.z,0,-normal.x)
 return absf(hit.dot(right)) <= gate_width/2-0.42 and absf(hit.y) <= gate_height/2-0.16

func tick(dt: float, pos: Vector3, velocity: Vector3, crashed: bool, contact: bool) -> void:
 if state == "READY" and contact and pos.distance_to(SPAWN)<0.4: armed = true
 if state == "READY" and armed and not contact and velocity.y>0.05:
  if Vector2(pos.x-START.x,pos.z-START.z).length() < 1.6:
   state = "FLYING"
  else: state = "INVALID START — reset"
 if state == "FLYING":
  seconds += dt
  if crashed: state = "CRASH — reset"
  elif next_gate < POINTS.size():
   if crossed(next_gate,previous,pos):
    next_gate += 1
    refresh()
  elif inside_finish_zone(pos) and pos.y < FINISH.y+0.26 and contact and velocity.length()<0.5:
   landed_for += dt
   if landed_for >= 0.5:
    seconds -= landed_for # timestamp initial stable contact, not dwell completion
    state = "FINISHED"
    if best == 0 or seconds < best: best = seconds
    completed.emit(seconds)
  else: landed_for = 0
 previous = pos

func inside_finish_zone(pos: Vector3) -> bool:
 return absf(pos.x-FINISH.x)<FINISH_HALF_WIDTH and absf(pos.z-FINISH.z)<FINISH_HALF_WIDTH
