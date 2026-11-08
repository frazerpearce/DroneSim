extends SceneTree
var failures := 0
func check(ok: bool, title: String) -> void:
 print("PASS " if ok else "FAIL ",title)
 if not ok: failures+=1
func frames(n: int) -> void:
 for i in range(n): await physics_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var world := Node3D.new()
 root.add_child(world)
 var d = load("res://drone.gd").new()
 world.add_child(d)
 d.freeze=true
 var targets := PackedFloat64Array([7,7,7,7])
 d.advance_motors(targets,d.spool_up_seconds)
 var fraction: float = d.rotor_speeds[0]/(d.max_rpm*TAU/60)
 check(abs(fraction-(1-exp(-1.0)))<0.00001,"motor speed follows first-order response")
 check(abs(d.motors[0]/7-pow(1-exp(-1.0),2))<0.00001,"thrust follows squared rotor speed")
 var old: float = d.rotor_speeds[0]
 d.advance_motors(PackedFloat64Array([0,0,0,0]),d.spool_down_seconds)
 check(abs(d.rotor_speeds[0]/old-exp(-1.0))<0.00001,"disarm spins motors down rather than removing thrust instantly")
 d.motors.fill(0.0)
 var f1: Vector3 = d.aerodynamic_force(Vector3(2,0,0))
 var f2: Vector3 = d.aerodynamic_force(Vector3(4,0,0))
 check(abs(f2.x/f1.x-4)<0.00001,"body drag scales as airspeed squared")
 check(d.aerodynamic_force(Vector3(2,-3,4)).dot(Vector3(2,-3,4))<0,"drag dissipates relative-air kinetic energy")
 check(abs(d.aerodynamic_force(Vector3(0,2,0)).y)>abs(f1.x),"body-axis projected areas give anisotropic drag")
 var requested := Vector3(0.05,0.01,-0.04)
 var mixed: PackedFloat64Array = d.mix_thrust(1.2*9.81,requested)
 var torque := Vector3.ZERO
 var force := 0.0
 for i in range(4):
  force+=mixed[i]
  torque+=d.ROTORS[i].cross(Vector3.UP*mixed[i])+Vector3.UP*d.SPINS[i]*d.YAW_RATIO*mixed[i]
 check(abs(force-1.2*9.81)<0.00001 and torque.distance_to(requested)<0.00001,"mixer reconstructs requested force and three-axis torque")
 mixed=d.mix_thrust(20,Vector3(100,30,-50))
 var bounded := true
 for value in mixed: bounded=bounded and value>=0 and value<=7
 check(bounded,"motor saturation respects physical thrust bounds")
 # Isolate the rigid body from controller, contact and gravity for angular dynamics.
 d.position=Vector3(0,10,0)
 d.stabilised=false
 d.motors_armed=true
 d.gravity_scale=0
 d.direct_motor_thrust=d.mix_thrust(1.2*9.81,Vector3(0.02,0,0))
 d.advance_motors(d.direct_motor_thrust,10.0)
 d.freeze=false
 await frames(25)
 check(d.angular_velocity.x>0.10 and d.angular_velocity.x<0.23,"unassisted roll responds to torque/inertia")
 # Free fall with motors stopped: controller cannot secretly cancel gravity.
 d.freeze=true
 d.transform=Transform3D(Basis.IDENTITY,Vector3(0,10,0))
 d.linear_velocity=Vector3.ZERO
 d.angular_velocity=Vector3.ZERO
 d.motors_armed=false
 d.rotor_speeds.fill(0.0)
 d.motors.fill(0.0)
 d.direct_motor_thrust.fill(0.0)
 d.gravity_scale=1
 d.freeze=false
 await frames(61)
 check(d.linear_velocity.y < -4.4 and d.linear_velocity.y > -5.1,"motors-off free fall approximates g with aerodynamic drag")
 print("Dynamics checks: ",failures," failures")
 quit(failures)
