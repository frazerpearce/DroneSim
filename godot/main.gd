extends Node3D
const Drone = preload("res://drone.gd")
var drone: RigidBody3D
var camera: Camera3D
var hud: Label
var fpv := false
var view := 0
const VIEW_NAMES := ["FRONT","REAR","LEFT","RIGHT","UP","DOWN"]
var auxiliary: Control
var recovery = preload("res://recovery.gd").new()
var recovery_message := ""
var recovery_message_for := 0.0
var paused := false
var elapsed := 0.0
var controls = preload("res://controls.gd").new()
var course: Node3D
var session: Node
var setup: Control
var test_mode := false
var held := {}
var wheel_pulses := {}

func material(colour: Color, metal := false) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = colour
 m.metallic = 0.6 if metal else 0.0
 m.roughness = 0.7
 return m

func block(parent: Node3D, pos: Vector3, size: Vector3, colour: Color, solid := true) -> Node3D:
 var holder: Node3D = StaticBody3D.new() if solid else Node3D.new()
 parent.add_child(holder)
 holder.position = pos
 var mesh := MeshInstance3D.new()
 var cube := BoxMesh.new()
 cube.size = size
 mesh.mesh = cube
 mesh.material_override = material(colour)
 holder.add_child(mesh)
 if solid:
  if pos.y+size.y/2>0.05: holder.add_to_group("respawn_obstacles")
  var collision := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  collision.shape = shape
  holder.add_child(collision)
 return holder

func _ready() -> void:
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color(0.08,0.11,0.16)
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(0.7,0.8,1)
 env.ambient_light_energy = 0.65
 world.environment = env
 add_child(world)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-65,-25,0)
 sun.light_energy = 1.2
 sun.shadow_enabled = true
 add_child(sun)
 block(self,Vector3(0,-0.25,0),Vector3(40,0.5,60),Color(0.24,0.28,0.31))
 for x in [-20,20]:
  block(self,Vector3(x,9,0),Vector3(0.4,18,60),Color(0.23,0.31,0.39))
 for z in [-30,30]:
  block(self,Vector3(0,9,z),Vector3(40,18,0.4),Color(0.25,0.32,0.4))
 block(self,Vector3(0,18,0),Vector3(40,0.4,60),Color(0.17,0.21,0.27))
 for z in range(-25,30,10):
  block(self,Vector3(0,16,z),Vector3(40,0.4,0.4),Color(0.4,0.45,0.5))
  for x in [-19,19]:
   block(self,Vector3(x,8,z),Vector3(0.5,16,0.5),Color(0.4,0.45,0.5))
 for x in range(-18,20,2):
  block(self,Vector3(x,0.006,0),Vector3(0.025,0.01,59),Color(0.4,0.45,0.48),false)
 for z in range(-28,30,2):
  block(self,Vector3(0,0.008,z),Vector3(39,0.01,0.025),Color(0.4,0.45,0.48),false)
 course = preload("res://course.gd").new()
 course.game = self
 add_child(course)
 drone = Drone.new()
 add_child(drone)
 block(drone,Vector3.ZERO,Vector3(0.22,0.12,0.3),Color(0.12,0.15,0.2),false)
 for i in range(4):
  var p: Vector3 = Drone.ROTORS[i]
  var arm := block(drone,p*0.5,Vector3(0.045,0.035,p.length()),Color(0.3,0.35,0.4),false)
  arm.rotation.y = atan2(p.x,p.z)
  var rotor := block(drone,p+Vector3(0,0.07,0),Vector3(0.23,0.012,0.035),Color(0.95,0.25,0.15) if i < 2 else Color(0.2,0.7,0.9),false)
  drone.rotor_visuals.append(rotor)
 set_drone_visual_layer(drone)
 drone.spawn_position = course.SPAWN
 drone.reset_drone()
 camera = Camera3D.new()
 camera.fov = 78
 camera.near = 0.025
 add_child(camera)
 camera.position = drone.position + Vector3(0,2,4)
 var layer := CanvasLayer.new()
 add_child(layer)
 hud = Label.new()
 hud.position = Vector2(22,18)
 hud.add_theme_font_size_override("font_size",17)
 hud.add_theme_color_override("font_shadow_color",Color.BLACK)
 hud.add_theme_constant_override("shadow_offset_x",2)
 hud.add_theme_constant_override("shadow_offset_y",2)
 layer.add_child(hud)
 var instruments := preload("res://flight_hud.gd").new()
 instruments.game = self
 layer.add_child(instruments)
 auxiliary=preload("res://auxiliary_views.gd").new()
 auxiliary.game=self
 layer.add_child(auxiliary)
 session = preload("res://session.gd").new()
 session.game = self
 add_child(session)
 course.completed.connect(session.record)
 if not test_mode: controls.load_file("user://bindings.cfg")
 load_settings()
 setup = preload("res://setup.gd").new()
 setup.game = self
 layer.add_child(setup)
 var setup_button := Button.new()
 setup_button.text = "SETUP / Esc"
 setup_button.position = Vector2(1230,20)
 setup_button.pressed.connect(func(): setup.show_panel())
 layer.add_child(setup_button)


func save_settings() -> void:
 if test_mode: return
 var config := ConfigFile.new()
 config.set_value("flight","course",course.selected)
 config.set_value("flight","course_id",course.course_id())
 config.set_value("flight","name",session.player_name)
 config.set_value("flight","hold",drone.altitude_hold)
 config.set_value("flight","path",course.route.visible)
 config.set_value("flight","fov",camera.fov)
 var result := config.save("user://settings.cfg")
 if result!=OK: push_warning("Settings not saved: "+error_string(result))

func load_settings() -> void:
 if test_mode: return
 var config := ConfigFile.new()
 if config.load("user://settings.cfg")!=OK: return
 var index: Variant = config.get_value("flight","course",0)
 var id: Variant = config.get_value("flight","course_id","")
 if id is String and not id.is_empty():
  course.select(course.Catalog.index_of(id))
 elif index is int:
  # Older settings stored display order; translate that order to its original ID.
  course.select(course.Catalog.index_of("hangar-%02d-v1" % (clampi(index,0,9)+1)))
 session.set_player_name(str(config.get_value("flight","name","Pilot")).left(24))
 session.restore_player_times()
 drone.altitude_hold = config.get_value("flight","hold",true)==true
 course.route.visible = config.get_value("flight","path",true)==true
 var fov: Variant = config.get_value("flight","fov",78.0)
 if (fov is int or fov is float) and is_finite(float(fov)): camera.fov=clampf(float(fov),50,110)

func select_course(index: int, from_host := false) -> void:
 if session.net.peer != null and not session.net.is_host and not from_host: return
 course.select(index)
 session.course_changed()
 reset_attempt()
 if setup: setup.refresh_course()
 if not from_host: save_settings()

func reset_attempt() -> void:
 drone.reset_drone()
 course.reset_run()
 recovery_message_for=0
 if not setup or not setup.visible: paused=false
 drone.freeze = paused
 held.clear()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  held.clear()
  if course: course.invalidate("FOCUS LOST — reset")

func axis(positive: String, negative: String) -> float:
 return controls.strength(positive,held)-controls.strength(negative,held)

func _input(event: InputEvent) -> void:
 if setup and setup.visible: return
 var code: int = controls.event_code(event)
 if code==0: return
 if event.is_pressed():
  held[code]=true
  if controls.is_wheel(code): wheel_pulses[code]=true
 else: held.erase(code)
 if not event.is_pressed() or event.is_echo(): return
 if event is InputEventKey and event.keycode==KEY_ESCAPE:
  setup.show_panel()
  get_viewport().set_input_as_handled()
  return
 for i in range(6):
  if controls.matches("view_"+VIEW_NAMES[i].to_lower(),code):
   change_view(i)
   get_viewport().set_input_as_handled()
   return
 for action in ["reset","camera","altitude","pause","setup","network","quit"]:
  if not controls.matches(action,code): continue
  match action:
   "reset": reset_attempt()
   "camera": fpv=not fpv
   "altitude": drone.altitude_hold=not drone.altitude_hold; drone.target_height=drone.position.y; save_settings()
   "pause":
    course.invalidate("PAUSED — reset")
    paused=not paused
    drone.freeze=paused
   "setup": setup.show_panel()
   "network": setup.show_panel(true)
   "quit": get_tree().quit()
  get_viewport().set_input_as_handled()

func _physics_process(dt: float) -> void:
 drone.command = Vector3(axis("pitch_back","pitch_forward"),axis("yaw_left","yaw_right"),axis("roll_right","roll_left")) if not paused else Vector3.ZERO
 drone.climb = axis("climb","descend") if not paused else 0.0
 drone.brake = controls.strength("brake",held)>0 and not paused
 if not paused:
  course.tick(dt,drone.position,drone.linear_velocity,drone.crashed,not drone.get_colliding_bodies().is_empty())
  if drone.crashed: recover_crash()
 for code in wheel_pulses: held.erase(code)
 wheel_pulses.clear()

func _process(dt: float) -> void:
 elapsed += dt
 for i in range(4):
  drone.rotor_visuals[i].rotate_y(drone.rotor_speeds[i]*dt*Drone.SPINS[i])
 recovery_message_for=maxf(0,recovery_message_for-dt)
 update_camera(dt)
 auxiliary.update_views(camera,not setup.visible)
 var status := recovery_message if recovery_message_for>0 else ("PAUSED" if paused else ("ALTITUDE HOLD" if drone.altitude_hold else "MANUAL COLLECTIVE"))
 hud.visible = not setup.visible
 hud.text = "%s | %s\n%s\n\nTIME %.3f s    BEST %s\n\n%s\n%s\nEscape: setup / controls / LAN" % [status,VIEW_NAMES[view] if fpv else "TRAILING",course.title()+" — "+course.state,course.seconds,"%.3f s" % course.best if course.best>0 else "—",session.status,session.leaderboard()]

func set_drone_visual_layer(node: Node) -> void:
 if node is MeshInstance3D: node.layers=2
 for child in node.get_children(): set_drone_visual_layer(child)

func change_view(index: int) -> void:
 view=clampi(index,0,5)
 fpv=true

func update_camera(dt: float) -> void:
 camera.cull_mask=1 if fpv else 3
 if fpv:
  camera.global_transform=Transform3D(drone.global_basis*auxiliary.view_basis(view),drone.to_global(Vector3(0,0.08,0)))
 else:
  var yaw := Basis(Vector3.UP,drone.rotation.y)
  var destination: Vector3=drone.position+yaw*Vector3(0,1.7,3.5)
  destination=destination.clamp(Vector3(-19.5,0.35,-29.5),Vector3(19.5,17.5,29.5))
  camera.position=camera.position.lerp(destination,1-exp(-dt*7))
  camera.look_at(drone.position+Vector3(0,0.15,0))

func recover_crash() -> bool:
 if not drone.crashed: return false
 recovery.collect(self)
 var point: Vector3=recovery.nearest(drone.position)
 if not point.is_finite():
  paused=true
  drone.freeze=true
  recovery_message="No clear ground respawn — reset"
  recovery_message_for=10
  return false
 var penalised: bool=course.state=="FLYING"
 var reason: String=drone.crash_reason
 var yaw := atan2(drone.basis.z.x,drone.basis.z.z)
 course.recover(point)
 drone.reset_at(point,yaw)
 held.clear()
 recovery_message="RECOVERED "+reason+(" — +10 s" if penalised else "")+" — Up to take off"
 recovery_message_for=4
 return true
