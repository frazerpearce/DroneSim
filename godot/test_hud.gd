extends SceneTree
const Instruments=preload("res://flight_hud.gd")
func _initialize() -> void:
 var ok := true
 ok = ok and absf(Instruments.heading_of(Basis.IDENTITY))<0.00001
 ok = ok and absf(Instruments.heading_of(Basis(Vector3.UP,-PI/2))-PI/2)<0.00001
 var pitched := Instruments.attitude_of(Basis(Vector3.RIGHT,0.2))
 ok = ok and absf(pitched.x-0.2)<0.00001 and absf(pitched.y)<0.00001
 var banked := Instruments.attitude_of(Basis(Vector3.FORWARD,0.3))
 ok = ok and absf(banked.y+0.3)<0.00001
 print("PASS compass heading and pitch/bank signs" if ok else "FAIL instrument axes")
 quit(0 if ok else 1)
