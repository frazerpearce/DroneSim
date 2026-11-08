extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
 print("PASS " if ok else "FAIL ",message)
 if not ok: failures += 1
func step_frames(n: int) -> void:
 for i in range(n): await physics_frame
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var scene = load("res://main.tscn").instantiate()
 scene.test_mode=true
 root.add_child(scene)
 scene.select_course(0,true)
 scene.set_physics_process(false)
 var d = scene.drone
 d.motors_armed = true
 d.target_height = 3.0
 await step_frames(1200)
 check(abs(d.position.y-3.0)<0.15 and d.linear_velocity.length()<0.15,"settles into 3 m hover")
 check(abs(d.motors[0]+d.motors[1]+d.motors[2]+d.motors[3]-1.2*9.81)<0.3,"hover thrust balances weight")
 d.command.x = -1.0
 await step_frames(120)
 check(d.linear_velocity.z < -0.5,"forward pitch accelerates forwards")
 d.command = Vector3.ZERO
 d.brake = true
 await step_frames(600)
 check(Vector2(d.linear_velocity.x,d.linear_velocity.z).length()<0.25,"braking arrests horizontal motion")
 d.brake = false
 d.command.z = 1.0
 await step_frames(120)
 check(d.linear_velocity.x > 0.5,"right roll accelerates right")
 d.reset_drone()
 d.position = Vector3(0,4,10)
 d.crashed = true
 await step_frames(240)
 check(d.position.y < 0.5 and d.position.y > 0,"gravity and floor collision")
 d.reset_drone()
 await step_frames(30)
 check(not d.crashed and d.position.distance_to(d.spawn_position)<0.2,"reset restores aircraft")
 print("Flight checks: ",failures," failures")
 quit(failures)
