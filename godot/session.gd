extends Node
const Transport = preload("res://transport.gd")
const PROTOCOL := "DroneSim-0.2.3-hangar-01-v1"
var net = Transport.new()
var game: Node3D
var status := "Single player"
var states := {}
var ghosts := {}
var scores := {}
var accumulator := 0.0
var connect_age := 0.0
var player_name := "Pilot"
var local_best := 0.0
var announced := false

func offline() -> void:
 net.close()
 for ghost in ghosts.values(): ghost.queue_free()
 ghosts.clear()
 states.clear()
 scores.clear()
 local_best = 0
 announced = false
 status = "Single player"

func host(port: int) -> void:
 offline()
 var err: int = net.start_host(port)
 status = "Hosting UDP %d — up to 8 pilots" % port if err == OK else "Host failed: "+error_string(err)

func join(address: String, port: int) -> void:
 offline()
 if address.strip_edges().is_empty():
  status = "Enter a host IP address"
  return
 var err: int = net.start_client(address.strip_edges(),port)
 status = "Connecting…" if err == OK else "Join failed: "+error_string(err)
 connect_age = 0

func record(time: float) -> void:
 if local_best == 0 or time < local_best: local_best = time

func local_state() -> Dictionary:
 return {"protocol":PROTOCOL,"name":player_name.left(24),"transform":game.drone.transform,"time":game.course.seconds,"gate":game.course.next_gate,"state":game.course.state,"best":local_best}

func valid(data: Dictionary) -> bool:
 if data.get("protocol") != PROTOCOL: return false
 if not data.get("transform") is Transform3D or not data.get("name") is String: return false
 var t: Transform3D = data.transform
 if not t.origin.is_finite() or t.origin.length() > 100: return false
 if not t.basis.x.is_finite() or not t.basis.y.is_finite() or not t.basis.z.is_finite(): return false
 if absf(t.basis.determinant()-1.0)>0.1: return false
 for field in ["time","best"]:
  var number: Variant = data.get(field)
  if not (number is float or number is int) or not is_finite(float(number)) or number<0 or number>86400: return false
 return data.get("gate") is int and data.gate>=0 and data.gate<=6 and data.get("state") is String

func _process(dt: float) -> void:
 if net.peer == null: return
 if net.peer.get_connection_status()==MultiplayerPeer.CONNECTION_DISCONNECTED:
  offline()
  status = "Disconnected — reconnect from LAN setup"
  return
 net.poll()
 if not net.is_host:
  connect_age += dt
  if not net.connected and connect_age > 8:
   offline()
   status = "Connection lost or timed out"
   return
  if net.connected:
   connect_age = 0
   status = "Connected — ghost race"
 for id in net.departed:
  states.erase(id)
  if ghosts.has(id):
   ghosts[id].queue_free()
   ghosts.erase(id)
 net.departed.clear()
 net.joined.clear()
 for packet in net.incoming:
  var data: Dictionary = packet.message
  if net.is_host and data.get("type") == "pilot":
   if valid(data): states[packet.sender] = data
   else: net.disconnect_peer(packet.sender)
  elif not net.is_host and packet.sender == 1 and data.get("type") == "snapshot":
   if data.get("protocol") != PROTOCOL:
    offline()
    status = "Incompatible DroneSim version/course"
    return
   if data.get("pilots") is Dictionary and data.pilots.size()<=8:
    states = data.pilots
 net.incoming.clear()
 accumulator += dt
 if accumulator >= 0.05:
  accumulator = 0
  if net.is_host:
   states[1] = local_state()
   net.send(0,{"type":"snapshot","protocol":PROTOCOL,"pilots":states},false,2)
  elif net.connected:
   var data := local_state()
   data.type = "pilot"
   net.send(1,data,false,1)
 update_ghosts(dt)

func update_ghosts(dt: float) -> void:
 var own: int = net.peer.get_unique_id() if net.peer != null and net.connected else 1
 for id in ghosts.keys():
  if not states.has(id):
   ghosts[id].queue_free()
   ghosts.erase(id)
 for id in states:
  if id == own or not states[id] is Dictionary or not valid(states[id]): continue
  var data: Dictionary = states[id]
  if not ghosts.has(id):
   var ghost := Node3D.new() # visual only: no bodies, areas or collision shapes
   game.add_child(ghost)
   var colour := Color.from_hsv(fmod(float(id)*0.137,1.0),0.65,1)
   var m: StandardMaterial3D = game.material(colour)
   m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
   m.albedo_color.a = 0.38
   m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
   for pos in [Vector3.ZERO,Vector3(-0.19,0,-0.19),Vector3(0.19,0,-0.19),Vector3(-0.19,0,0.19),Vector3(0.19,0,0.19)]:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.25,0.08,0.25)
    mesh.mesh = box
    mesh.position = pos
    mesh.material_override = m
    ghost.add_child(mesh)
   var label := Label3D.new()
   label.name = "Name"
   label.position.y = 0.5
   label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   label.font_size = 42
   label.modulate = Color(1,1,1,0.65)
   ghost.add_child(label)
   ghost.transform = data.transform
   ghosts[id] = ghost
  var ghost: Node3D = ghosts[id]
  ghost.transform = ghost.transform.interpolate_with(data.transform,1-exp(-dt*14))
  ghost.get_node("Name").text = str(data.name).left(24)

func leaderboard() -> String:
 var rows: Array = []
 var own: int = net.peer.get_unique_id() if net.peer!=null and net.connected else 1
 rows.append({"name":player_name+" (you)","best":local_best})
 for id in states:
  if id != own and states[id] is Dictionary and valid(states[id]): rows.append(states[id])
 rows.sort_custom(func(a,b): return (a.best if a.best>0 else INF)<(b.best if b.best>0 else INF))
 var text := "FASTEST COMPLETED TIMES\n"
 for i in range(rows.size()):
  text += "%d. %s  %s\n" % [i+1,str(rows[i].name).left(30),"%.3f s" % rows[i].best if rows[i].best>0 else "—"]
 return text

func _exit_tree() -> void:
 net.close()
