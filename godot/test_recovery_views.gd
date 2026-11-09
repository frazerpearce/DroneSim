extends SceneTree
var failures := 0
func check(ok: bool, caption: String) -> void:
 print("PASS " if ok else "FAIL ",caption)
 if not ok: failures+=1
func frames(n: int) -> void:
 for i in range(n): await physics_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 game.test_mode=true
 root.add_child(game)
 game.select_course(0,true)
 var c=game.course
 var p: Vector3=c.POINTS[0]
 var normal: Vector3=c.normals[0]
 var right:=Vector3(normal.z,0,-normal.x)
 var side: Vector3=p+right*(c.gate_width/2-0.30)
 check(c.crossed(0,side-normal,side+normal),"visible opening edge no longer rejected by hidden width margin")
 var high: Vector3=p+Vector3.UP*(c.gate_height/2-0.12)
 check(c.crossed(0,high-normal,high+normal),"visible opening edge no longer rejected by hidden height margin")
 check(c.crossed(0,p-normal,p) and c.crossed(0,p,p+normal),"crossings ending or starting on the gate plane count")
 check(not c.crossed(0,p-right,p+right) and not c.crossed(0,p+normal,p-normal),"parallel motion and reverse gate passage do not count")
 # Real rigid-body passage near the opening's side, not just a geometry unit test.
 var d=game.drone
 d.reset_at(side-normal)
 d.gravity_scale=0
 d.linear_velocity=normal*4
 c.state="FLYING"
 c.previous=d.position
 await frames(80)
 check((d.position-p).dot(normal)>0.2 and c.next_gate==1 and not d.crashed,"physical near-edge gate flight advances progress")
 game.set_physics_process(false)
 d.freeze=true
 # Multiple gate planes crossed in chronological order during a single step.
 c.POINTS=[Vector3(0,3,0),Vector3(0,3,-1),Vector3(0,3,-2)]
 c.normals.assign([Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD])
 c.next_gate=0
 c.previous=Vector3(0,3,1)
 c.state="FLYING"
 c.tick(0.01,Vector3(0,3,-3),Vector3.FORWARD,false,false)
 check(c.next_gate==3,"one fast segment can advance multiple ordered gates")
 game.select_course(0,true)
 d=game.drone
 d.freeze=true
 c.state="FLYING"
 c.seconds=12.5
 c.next_gate=2
 d.position=Vector3(19.7,0.3,29.7)
 d.crashed=true
 d.crash_reason="IMPACT"
 check(game.recover_crash() and absf(c.seconds-22.5)<0.00001 and c.next_gate==2 and c.state=="FLYING","automatic recovery adds exactly ten seconds and preserves progress")
 check(game.recovery.valid(Vector2(d.position.x,d.position.z)) and absf(d.position.y-0.18)<0.00001 and d.basis.y.dot(Vector3.UP)>0.99,"respawn is upright on clear ground")
 check(absf(d.position.x-18.64)<0.001 and absf(d.position.z-28.64)<0.001,"corner crash chooses nearest wall-clear ground point")
 check(c.previous.is_equal_approx(d.position) and not d.motors_armed and not game.recover_crash() and c.seconds==22.5,"teleport cannot pass gates or duplicate penalty; motors reset")
 var obstacle=game.block(game,Vector3(12,1,12),Vector3(1,2,1),Color.GRAY)
 obstacle.rotation.y=PI/4
 game.recovery.collect(game)
 var near: Vector3=game.recovery.nearest(Vector3(12,5,12))
 check(game.recovery.valid(Vector2(near.x,near.z)) and absf(Vector2(near.x-12,near.z-12).length()-1.66)<0.001,"nearest respawn respects rotated obstacle clearance of two body lengths")
 d.freeze=true
 d.recovery_grace=0
 d.last_velocity=Vector3.ZERO
 d.detect_crash(0.8,Vector3.ZERO,Vector3.DOWN,true,false)
 check(d.crashed and d.crash_reason=="INVERTED","upside-down immobilisation counts as crash")
 d.reset_drone()
 d.freeze=true
 d.recovery_grace=0
 d.detect_crash(1.6,Vector3.ZERO,Vector3.UP,true,true)
 check(d.crashed and d.crash_reason=="STUCK","remaining stuck against a wall counts as crash")
 d.reset_drone()
 d.freeze=true
 d.recovery_grace=0
 d.detect_crash(10,Vector3.ZERO,Vector3.UP,true,false)
 check(not d.crashed,"normal upright ground rest is not a crash")
 d.last_velocity=Vector3(5,0,0)
 d.detect_crash(0.01,Vector3.ZERO,Vector3.UP,true,true)
 check(d.crashed and d.crash_reason=="IMPACT","hard contact impact counts as crash")
 # Verify contact classification against the actual solver, not only helper inputs.
 d.reset_at(Vector3(19.48,4,10))
 d.gravity_scale=0
 d.constant_force=Vector3(8,0,0)
 d.recovery_grace=0
 await frames(270)
 check(d.crashed and d.crash_reason=="STUCK","real sustained wall contact is detected as stuck")
 d.constant_force=Vector3.ZERO
 d.reset_at(Vector3(0,0.13,15))
 d.rotation.z=PI
 d.gravity_scale=1
 d.recovery_grace=0
 await frames(130)
 check(d.crashed and d.crash_reason=="INVERTED","real inverted ground contact is detected as crash")
 d.reset_drone()
 await frames(220)
 check(not d.crashed,"real upright plinth rest remains crash-free")
 d.freeze=true
 var directions := [Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT,Vector3.UP,Vector3.DOWN]
 game.controls.restore_defaults()
 for i in range(6):
  var event:=InputEventKey.new()
  event.physical_keycode=KEY_1+i
  event.pressed=true
  game._input(event)
  game.update_camera(0)
  check(game.fpv and game.view==i and (-game.camera.basis.z).dot(directions[i])>0.999,"number key selects correct onboard view %d" % (i+1))
  game.auxiliary.update_views(game.camera,true)
  var correct := true
  for slot in range(5):
   var expected: Basis=game.camera.basis*game.auxiliary.view_basis(game.auxiliary.VIEWS[slot])
   correct=correct and game.auxiliary.cameras[slot].basis.is_equal_approx(expected)
  check(correct,"five relative auxiliary directions follow main view %d" % (i+1))
 check(game.auxiliary.viewports.size()==5 and game.auxiliary.viewports.all(func(v): return v.world_3d==game.get_world_3d()),"five subviews share the existing world")
 check(game.auxiliary.tiles.all(func(tile): return tile.get_child(0).size.is_equal_approx(game.auxiliary.TILE)),"preview images fit their tiles without overlap")
 var rear: Rect2=game.auxiliary.tile_rect(0)
 check(game.auxiliary.tile_rect(1).end.y<rear.position.y and game.auxiliary.tile_rect(2).position.y>rear.end.y and game.auxiliary.tile_rect(3).end.x<rear.position.x and game.auxiliary.tile_rect(4).position.x>rear.end.x,"auxiliary cross matches Dogfight layout")
 game.auxiliary.update_views(game.camera,false)
 check(game.auxiliary.viewports.all(func(v): return v.render_target_update_mode==SubViewport.UPDATE_DISABLED),"hidden setup stops subview rendering")
 var filename: String="/tmp/dronesim-views-%d.cfg" % OS.get_process_id()
 var config:=ConfigFile.new()
 config.set_value("bindings","brake",[KEY_1])
 config.save(filename)
 var keys=load("res://controls.gd").new()
 check(keys.load_file(filename) and keys.matches("brake",KEY_1) and keys.key_at("view_front",0)==0 and keys.matches("view_down",KEY_6),"older bindings gain new camera keys without stealing assigned keys")
 DirAccess.remove_absolute(filename)
 print("Recovery and camera checks: ",failures," failures")
 quit(failures)
