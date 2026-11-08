extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.controls.restore_defaults()
 for i in range(240): await physics_frame
 var idle_height: float = game.drone.position.y
 var remained_grounded: bool = not game.drone.motors_armed and idle_height<0.8
 var key := InputEventKey.new()
 key.physical_keycode=KEY_UP
 key.keycode=KEY_UP
 key.pressed=true
 Input.parse_input_event(key)
 for i in range(240): await physics_frame
 var lifted: bool = game.drone.motors_armed and game.drone.position.y>2 and game.course.state=="FLYING"
 key.pressed=false
 Input.parse_input_event(key)
 print("PASS idle stays on plinth" if remained_grounded else "FAIL uncommanded takeoff")
 print("PASS keyboard Up takes off after idle and starts timer" if lifted else "FAIL idle takeoff")
 quit(0 if remained_grounded and lifted else 1)
