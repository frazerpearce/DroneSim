extends SceneTree
const Results=preload("res://results.gd")
var failures := 0
func check(ok: bool, caption: String) -> void:
 print("PASS " if ok else "FAIL ",caption)
 if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var path := "/tmp/dronesim-results-%d.json" % OS.get_process_id()
 var scores=Results.new()
 scores.path=path
 check(scores.load_file(),"missing score file starts empty")
 check(scores.record("Alice","hangar-01-v1",12.5),"first completed score saved")
 check(not scores.record("ALICE","hangar-01-v1",14),"slower score does not overwrite best")
 scores.record(" alice ","hangar-02-v1",18.25)
 scores.record("Bob","hangar-01-v1",11.0)
 var loaded=Results.new()
 loaded.path=path
 check(loaded.load_file() and loaded.best("Alice","hangar-01-v1")==12.5 and loaded.best("ALICE","hangar-02-v1")==18.25,"saved times survive reload and normalise names")
 check(loaded.best("Bob","hangar-01-v1")==11.0 and loaded.best("Bob","hangar-02-v1")==0,"players and courses remain separate")
 check(not loaded.record("Bob","hangar-01-v1",NAN) and not loaded.record("Bob","hangar-01-v1",-2),"invalid times rejected")
 var game=load("res://main.tscn").instantiate()
 game.test_mode=true
 root.add_child(game)
 game.set_physics_process(false)
 game.drone.freeze=true
 game.session.results=loaded
 game.session.set_player_name("Alice")
 check(game.session.local_best==12.5 and game.course.best==12.5,"name selection restores current-course time")
 game.select_course(1,true)
 check(game.session.local_best==18.25,"course selection restores named player's other time")
 game.session.set_player_name("Bob")
 check(game.session.local_best==0 and game.course.best==0,"changing player clears previous player's displayed time")
 game.select_course(0,true)
 check(game.session.local_best==11.0,"changing course restores new player's correct time")
 game.session.offline()
 check(game.session.local_best==11.0,"disconnect retains saved personal best")
 game.setup.refresh_times()
 check(game.setup.times_table.get_root().get_child_count()==2,"compact table includes both saved players")
 check(loaded.total("Alice")==0,"total withheld when any course is missing")
 for i in range(10): loaded.record("Charlie","hangar-%02d-v1" % (i+1),float(i+1))
 check(loaded.total("Charlie")==55.0,"total sums all ten personal bests")
 loaded.record("Charlie","unrelated-course",999)
 check(loaded.total("Charlie")==55.0,"unrelated saved courses do not affect total")
 game.session.results=loaded
 game.setup.refresh_times()
 var row=game.setup.times_table.get_root().get_first_child()
 while row and row.get_text(0)!="Charlie": row=row.get_next()
 check(row!=null and row.get_text(9)=="10.000 s" and row.get_text(10)=="9.000 s" and row.get_text(11)=="55.000 s","chart swaps old route scores and shows completed total")
 var file := FileAccess.open(path,FileAccess.WRITE)
 file.store_string("broken JSON")
 file.close()
 var broken=Results.new()
 broken.path=path
 check(not broken.load_file() and not broken.save() and FileAccess.get_file_as_string(path)=="broken JSON","malformed original is preserved")
 DirAccess.remove_absolute(path)
 print("Saved results checks: ",failures," failures")
 quit(failures)
