extends Node3D
const POINTS := [Vector3(0,3,0),Vector3(-7,4,-10),Vector3(0,5,-20),Vector3(9,4,-10),Vector3(10,3,2),Vector3(8,2.5,12)]
const START := Vector3(0,0.5,8)
const FINISH := Vector3(8,0.5,20)
const SPAWN := START + Vector3(0,0.18,0)
const ID := "hangar-01-v1"
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
 for pair in [[START,Color(0.1,0.7,0.5),"START"],[FINISH,Color(0.5,0.3,0.9),"FINISH"]]:
  game.block(self,pair[0]-Vector3(0,0.25,0),Vector3(3,0.5,3),pair[1])
  var text := Label3D.new()
  text.text = pair[2]
  text.position = pair[0]+Vector3(0,0.02,0)
  text.rotation_degrees.x = -90
  text.font_size = 100
  add_child(text)
 var last := START
 for i in range(POINTS.size()):
  var p: Vector3 = POINTS[i]
  var normal := (p-last)*Vector3(1,0,1)
  normal = normal.normalized()
  normals.append(normal)
  var frame := Node3D.new()
  add_child(frame)
  frame.position = p
  frame.rotation.y = atan2(normal.x,normal.z)
  frames.append(frame)
  for x in [-2.2,2.2]:
   game.block(frame,Vector3(x,0,0),Vector3(0.22,3.4,0.25),Color.ORANGE)
  for y in [-1.7,1.7]:
   game.block(frame,Vector3(0,y,0),Vector3(4.6,0.22,0.25),Color.ORANGE)
  var label := Label3D.new()
  label.position = Vector3(0,2.2,0)
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.font_size = 64
  frame.add_child(label)
  labels.append(label)
  last = p
 route = Node3D.new()
 add_child(route)
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
 return absf(hit.dot(right)) <= 1.78 and absf(hit.y) <= 1.28

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
  elif absf(pos.x-FINISH.x) < 1.15 and absf(pos.z-FINISH.z) < 1.15 and pos.y < FINISH.y+0.26 and contact and velocity.length()<0.5:
   landed_for += dt
   if landed_for >= 0.5:
    seconds -= landed_for # timestamp initial stable contact, not dwell completion
    state = "FINISHED"
    if best == 0 or seconds < best: best = seconds
    completed.emit(seconds)
  else: landed_for = 0
 previous = pos
