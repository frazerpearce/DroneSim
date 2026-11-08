extends SceneTree
var failures := 0
func check(ok: bool, caption: String) -> void:
 print("PASS " if ok else "FAIL ",caption)
 if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 game.test_mode=true
 root.add_child(game)
 game.set_physics_process(false)
 game.drone.freeze=true
 var zone=game.course.geometry.get_node("LandingZone")
 var plate=zone.get_child(0).get_child(0)
 check(is_equal_approx(plate.mesh.size.x,2*game.course.FINISH_HALF_WIDTH) and is_equal_approx(plate.mesh.size.z,2*game.course.FINISH_HALF_WIDTH),"painted landing square matches timer dimensions")
 check(game.course.inside_finish_zone(game.course.FINISH+Vector3(1.149,0,0)) and not game.course.inside_finish_zone(game.course.FINISH+Vector3(1.151,0,0)),"landing test uses drone centre inside painted boundary")
 check(game.course.Catalog.COURSES.size()==10,"ten selectable courses")
 for index in range(10):
  game.select_course(index,true)
  var c=game.course
  var valid: bool = c.frames.size()==c.POINTS.size() and c.gate_width>1 and c.gate_height>1
  c.tick(0.01,c.SPAWN,Vector3.ZERO,false,true)
  c.tick(0.01,c.SPAWN+Vector3(0,0.1,0),Vector3.UP,false,false)
  for i in range(c.POINTS.size()):
   var p: Vector3=c.POINTS[i]
   var n: Vector3=c.normals[i]
   valid=valid and absf(p.x)+c.gate_width/2<19 and p.y-c.gate_height/2>0 and p.y+c.gate_height/2<15.5 and absf(p.z)<27
   valid=valid and not c.crossed(i,p+n,p-n)
   c.previous=p-n
   c.tick(1,p+n,Vector3.ZERO,false,false)
  for i in range(60): c.tick(0.01,c.FINISH+Vector3(0,0.12,0),Vector3.ZERO,false,true)
  valid=valid and c.state=="FINISHED" and c.next_gate==c.POINTS.size()
  check(valid,"%s: geometry, ordered gates and finish" % c.title())
 game.select_course(0,true)
 check(game.course.best>0 and game.session.local_best>0,"course-specific best restored")
 game.select_course(9,true)
 var state: Dictionary=game.session.local_state()
 state.gate=10
 check(game.session.valid(state),"LAN accepts ten-gate course progress")
 state.gate=11
 check(not game.session.valid(state),"LAN rejects progress beyond selected course length")
 game.setup.show_panel()
 game.setup.course_picker.item_selected.emit(1)
 check(game.course.selected==1 and game.drone.freeze and game.course.state=="READY","Escape selector changes course and resets frozen drone")
 game.setup.close()
 check(not game.paused and not game.drone.freeze,"closing selector resumes selected course")
 var snap := {"protocol":game.session.PROTOCOL,"course":8,"serial":1,"pilots":{}}
 check(game.session.accept_snapshot(snap) and game.course.selected==8,"host snapshot synchronises client course")
 snap.course=0
 snap.serial=0
 check(not game.session.accept_snapshot(snap) and game.course.selected==8,"stale snapshots cannot revert course selection")
 snap.course=99
 snap.serial=2
 check(not game.session.accept_snapshot(snap) and game.course.selected==8,"invalid network course rejected")
 print("Course checks: ",failures," failures")
 quit(failures)
