extends Control
# Instruments use world north (-Z), body attitude and world vertical velocity.
var game: Node3D
const INK := Color(0.87,0.94,1)
const AMBER := Color(1,0.76,0.25)
const CYAN := Color(0.25,0.88,1)
var font := ThemeDB.fallback_font

static func heading_of(basis_now: Basis) -> float:
 var forward := -basis_now.z
 return atan2(forward.x,-forward.z)

static func attitude_of(basis_now: Basis) -> Vector2:
 var forward := -basis_now.z
 return Vector2(atan2(forward.y,Vector2(forward.x,forward.z).length()),atan2(basis_now.x.y,basis_now.y.y))

func text_at(pos: Vector2, caption: String, colour := INK, point_size := 16) -> void:
 var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x
 draw_string(font,pos-Vector2(width/2,0),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,colour)

func arrow(origin: Vector2, vector: Vector2, colour: Color, weight := 3.0) -> void:
 if vector.length()<1: return
 var end := origin+vector
 var back := -vector.normalized()*9
 draw_line(origin,end,colour,weight,true)
 draw_line(end,end+back.rotated(0.5),colour,weight,true)
 draw_line(end,end+back.rotated(-0.5),colour,weight,true)

func panel(centre: Vector2, title: String) -> void:
 draw_style_box(panel_style(),Rect2(centre-Vector2(100,91),Vector2(200,190)))
 text_at(centre+Vector2(0,-70),title)

func panel_style() -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color=Color(0.02,0.04,0.065,0.9)
 style.set_corner_radius_all(12)
 return style

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_dt: float) -> void:
 visible=not game.setup.visible if game.setup else true
 queue_redraw()

func _draw() -> void:
 if not game or not game.drone: return
 var screen := get_viewport_rect().size
 var centre := Vector2(screen.x/2,screen.y-115)
 var heading := heading_of(game.drone.basis)
 compass(centre-Vector2(225,0),heading)
 attitude(centre,attitude_of(game.drone.basis))
 vertical(centre+Vector2(225,0),game.drone.linear_velocity.y)
 # Course completion is shown as a row of lamps, without gate counters.
 for i in range(game.course.POINTS.size()):
  var colour := Color(0.28,0.33,0.38)
  if i<game.course.next_gate: colour=Color(0.3,1,0.4)
  elif i==game.course.next_gate: colour=CYAN
  draw_circle(Vector2(screen.x/2+(i-2.5)*22,28),6,colour,true,-1,true)

func compass(c: Vector2, heading: float) -> void:
 panel(c,"DIRECTION")
 draw_arc(c,57,0,TAU,64,Color(0.3,0.45,0.55),2,true)
 var names := ["N","E","S","W"]
 for i in range(16):
  var angle := i*TAU/16-heading
  var ray := Vector2(sin(angle),-cos(angle))
  draw_line(c+ray*49,c+ray*55,INK,1,true)
  if i%4==0: text_at(c+ray*39+Vector2(0,5),names[i/4],INK,14)
 # Fixed aircraft nose; white arrow shows actual horizontal travel, not tilt.
 draw_colored_polygon(PackedVector2Array([c+Vector2(0,-57),c+Vector2(-6,-66),c+Vector2(6,-66)]),AMBER)
 var velocity: Vector3=game.drone.linear_velocity
 var travel := Vector2(velocity.x,velocity.z)
 if travel.length()>0.08:
  var angle := atan2(travel.x,-travel.y)-heading
  arrow(c,Vector2(sin(angle),-cos(angle))*clampf(travel.length()*5,10,30),INK,2)
 else: draw_circle(c,3,INK)
 var target: Vector3 = game.course.POINTS[game.course.next_gate] if game.course.next_gate<game.course.POINTS.size() else game.course.FINISH
 var delta: Vector3=target-game.drone.position
 if Vector2(delta.x,delta.z).length()>0.1:
  var bearing := atan2(delta.x,-delta.z)-heading
  arrow(c,Vector2(sin(bearing),-cos(bearing))*47,CYAN,3)
 text_at(c+Vector2(0,82),"WHITE: TRAVEL  •  BLUE: ROUTE",INK,11)

func attitude(c: Vector2, angles: Vector2) -> void:
 panel(c,"TILT")
 var radius := 57.0
 var shift := clampf(angles.x/deg_to_rad(50)*radius,-radius,radius)
 var normal := Vector2.DOWN.rotated(angles.y)
 var circle := PackedVector2Array()
 for i in range(96): circle.append(Vector2(cos(i*TAU/96),sin(i*TAU/96))*radius)
 draw_circle(c,radius,Color(0.15,0.36,0.52),true,-1,true)
 # Clip the ground half-plane against the circular instrument aperture.
 var ground := PackedVector2Array()
 for i in range(circle.size()):
  var a := circle[i]
  var b := circle[(i+1)%circle.size()]
  var da := a.dot(normal)-shift
  var db := b.dot(normal)-shift
  if da>=0: ground.append(c+a)
  if (da>=0)!=(db>=0): ground.append(c+a.lerp(b,da/(da-db)))
 if ground.size()>=3: draw_colored_polygon(ground,Color(0.35,0.24,0.15))
 var tangent := Vector2.RIGHT.rotated(angles.y)
 var half := sqrt(maxf(radius*radius-shift*shift,0))
 draw_line(c+normal*shift-tangent*half,c+normal*shift+tangent*half,INK,2,true)
 draw_arc(c,radius,0,TAU,96,INK,1,true)
 # The aircraft reference stays fixed while the horizon moves oppositely.
 draw_line(c+Vector2(-32,0),c+Vector2(-9,0),AMBER,3,true)
 draw_line(c+Vector2(9,0),c+Vector2(32,0),AMBER,3,true)
 draw_circle(c,3,AMBER)
 for angle in [-0.6,-0.3,0.0,0.3,0.6]:
  var ray := Vector2(sin(angle),-cos(angle))
  draw_line(c+ray*60,c+ray*65,INK,1,true)
 text_at(c+Vector2(0,82),"WINGS LEVEL = FLAT HORIZON",INK,11)

func vertical(c: Vector2, speed: float) -> void:
 panel(c,"RISE / FALL")
 draw_line(c+Vector2(0,-48),c+Vector2(0,48),Color(0.35,0.45,0.5),2,true)
 for i in range(-3,4):
  var y := i*16.0
  draw_line(c+Vector2(-7,y),c+Vector2(7,y),INK,1,true)
 draw_line(c+Vector2(-28,0),c+Vector2(28,0),INK,1,true)
 if absf(speed)>0.08:
  arrow(c,Vector2(0,-clampf(speed/3.0,-1,1)*48),Color(0.3,1,0.55) if speed>0 else AMBER,4)
 else: draw_circle(c,5,Color(0.3,1,0.55))
 text_at(c+Vector2(0,-52),"RISE",INK,11)
 text_at(c+Vector2(0,64),"FALL",INK,11)
 text_at(c+Vector2(0,82),"CENTRED = HOLDING HEIGHT",INK,11)
