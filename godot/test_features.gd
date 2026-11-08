extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
 print("PASS " if ok else "FAIL ",message)
 if not ok: failures += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.drone.freeze = true
 var c = game.course
 c.tick(0.01,c.SPAWN,Vector3.ZERO,false,true)
 c.tick(0.01,c.SPAWN+Vector3(0,0.1,0),Vector3.UP,false,false)
 check(c.state=="FLYING","takeoff starts timer after start-plinth contact")
 var p: Vector3 = c.POINTS[0]
 var n: Vector3 = c.normals[0]
 check(not c.crossed(0,p+n,p-n),"reverse gate crossing rejected")
 check(not c.crossed(0,p-n+Vector3(4,0,0),p+n+Vector3(4,0,0)),"outside aperture rejected")
 for i in range(6):
  p=c.POINTS[i]
  n=c.normals[i]
  c.previous=p-n
  c.tick(1,p+n,Vector3.ZERO,false,false)
 check(c.next_gate==6,"all six gates accepted in sequence")
 for i in range(60): c.tick(0.01,c.FINISH+Vector3(0,0.12,0),Vector3.ZERO,false,true)
 check(c.state=="FINISHED" and c.best>0 and game.session.local_best==c.best,"stable finish landing records result")
 var best: float = c.best
 c.reset_run()
 check(c.best==best and c.seconds==0 and c.next_gate==0,"reset clears attempt and retains best")
 c.state="FLYING"
 c.invalidate("PAUSED")
 c.tick(1,c.FINISH,Vector3.ZERO,false,true)
 check(c.state=="PAUSED" and c.seconds==0,"interrupted attempt cannot finish")
 var keys = game.controls
 keys.path="/tmp/dronesim-test-bindings.cfg"
 check(keys.assign_key("climb",1,KEY_Z),"alternate binding")
 check(not keys.assign_key("descend",1,KEY_Z),"duplicate binding rejected")
 check(keys.assign_key("camera",2,-MOUSE_BUTTON_WHEEL_UP),"mouse wheel binding")
 check(keys.assign_key("climb",1,0),"clear binding")
 check(keys.save()==OK,"bindings save")
 var restored = load("res://controls.gd").new()
 check(restored.load_file(keys.path) and restored.key_at("camera",2)==-MOUSE_BUTTON_WHEEL_UP,"bindings round trip")
 check(not keys.assign_key("setup",0,KEY_ESCAPE),"Escape recovery key reserved")
 game.setup.show_panel()
 check(game.paused and game.drone.freeze,"setup freezes local aircraft")
 game.setup.close()
 check(not game.setup.visible,"setup closes")
 var remote: Dictionary = game.session.local_state()
 remote.name = "Ghost pilot"
 remote.best = 12.5
 game.session.states[2] = remote
 game.session.update_ghosts(0.1)
 check(game.session.ghosts.size()==1,"remote state creates ghost")
 var collision_free := true
 for ghost in game.session.ghosts.values():
  for child in ghost.get_children():
   if child is CollisionObject3D or child is CollisionShape3D: collision_free=false
 check(collision_free,"remote drones have no collision objects")
 check(game.session.leaderboard().contains("12.500 s"),"completed times appear on leaderboard")
 remote.best = -1
 check(not game.session.valid(remote),"negative race time rejected")
 remote.best = 12.5
 remote.protocol = "other-game"
 check(not game.session.valid(remote),"incompatible protocol rejected")
 game.session.states.clear()
 game.session.update_ghosts(0.1)
 check(game.session.ghosts.is_empty(),"departed pilot ghost removed")
 if "--lan" in OS.get_cmdline_user_args(): await lan_check(game)
 else: print("SKIP live ENet check: run with -- --lan on a machine allowing UDP sockets")
 print("Feature checks: ",failures," failures")
 quit(failures)

func lan_check(game: Node) -> void:
 var client_game = load("res://main.tscn").instantiate()
 root.add_child(client_game)
 client_game.drone.freeze = true
 client_game.set_physics_process(false)
 game.session.host(25689)
 if game.session.net.peer==null:
  check(false,"ENet host could not bind UDP 25689")
  return
 client_game.session.join("127.0.0.1",25689)
 for i in range(160): await create_timer(0.01).timeout
 check(client_game.session.net.connected,"ENet client connects to host")
 check(game.session.states.size()==2 and client_game.session.states.size()==2,"two-way pilot state replication")
 check(game.session.ghosts.size()==1 and client_game.session.ghosts.size()==1,"each pilot sees one remote ghost")
 client_game.session.record(12.5)
 for i in range(30): await create_timer(0.01).timeout
 check(game.session.leaderboard().contains("12.500 s"),"completed times replicate to leaderboard")
 client_game.session.offline()
 for i in range(40): await create_timer(0.01).timeout
 check(game.session.ghosts.is_empty(),"disconnect removes ghost")
 game.session.offline()
