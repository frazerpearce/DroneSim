extends RigidBody3D
# Representative 1.2 kg quadcopter. SI units throughout; body forward is -Z.
const MASS := 1.2
const ARM := 0.19
const MAX_THRUST := 7.0 # N per motor; total thrust/weight = 2.38
const YAW_RATIO := 0.018 # reaction torque / thrust, metres
const ROTORS := [Vector3(-ARM,0,-ARM), Vector3(ARM,0,-ARM), Vector3(ARM,0,ARM), Vector3(-ARM,0,ARM)]
const SPINS := [1.0,-1.0,1.0,-1.0]
# Representative parameters; not fitted to a specific commercial airframe.
@export var mass_kg := MASS
@export var body_inertia := Vector3(0.025,0.045,0.025) # kg m², body X/Y/Z
@export var air_density := 1.225 # kg/m³
@export var drag_area := Vector3(0.045,0.08,0.045) # Cd A, m² per body axis
@export var rotor_inplane_drag := 0.12 # N/(m/s) at nominal hover thrust
@export var max_rpm := 9000.0
@export var spool_up_seconds := 0.045
@export var spool_down_seconds := 0.080
@export var rotor_inertia := 0.000003 # kg m² per rotor
var wind_velocity := Vector3.ZERO # world frame, m/s
var rotor_speeds := PackedFloat64Array([0,0,0,0]) # rad/s, unsigned
var motor_targets := PackedFloat64Array([0,0,0,0]) # demanded thrust, N
var stabilised := true
var direct_motor_thrust := PackedFloat64Array([0,0,0,0]) # unassisted physics/testing
var spawn_position := Vector3(0,0.18,8)
var motors := PackedFloat64Array([0,0,0,0])
var command := Vector3.ZERO # pitch, yaw, roll keyboard axes
var climb := 0.0
var brake := false
var altitude_hold := true
var target_height := 0.15
var crashed := false
var motors_armed := false
var last_velocity := Vector3.ZERO
var rotor_visuals: Array[Node3D] = []

func _ready() -> void:
 mass = mass_kg
 inertia = body_inertia
 linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
 angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
 linear_damp = 0.0
 angular_damp = 0.0
 # The flight controller must run even after a long idle on a landing pad.
 can_sleep = false
 continuous_cd = true
 contact_monitor = true
 max_contacts_reported = 8
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(0.58,0.22,0.58)
 shape.shape = box
 add_child(shape)

func reset_drone() -> void:
 freeze = true
 transform = Transform3D(Basis.IDENTITY, spawn_position)
 linear_velocity = Vector3.ZERO
 angular_velocity = Vector3.ZERO
 motors.fill(0.0)
 rotor_speeds.fill(0.0)
 motor_targets.fill(0.0)
 target_height = spawn_position.y
 crashed = false
 motors_armed = false
 last_velocity = Vector3.ZERO
 freeze = false
 sleeping = false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
 var dt := state.step
 if state.get_contact_count() > 0 and (last_velocity - state.linear_velocity).length() > 4.0:
  crashed = true
 last_velocity = state.linear_velocity
 if not motors_armed and not crashed and climb > 0: motors_armed = true
 var basis_now := state.transform.basis.orthonormalized()
 var up := basis_now.y
 var yaw_basis := Basis(Vector3.UP, state.transform.basis.get_euler().y)
 var desired_tilt := Vector3(command.x,0,command.z) * deg_to_rad(25.0)
 if brake:
  var local_v := yaw_basis.transposed() * state.linear_velocity
  desired_tilt = Vector3(clampf(-local_v.z * 0.12,-0.44,0.44),0,clampf(local_v.x * 0.12,-0.44,0.44))
 var desired := yaw_basis * Basis.from_euler(Vector3(desired_tilt.x,0,-desired_tilt.z))
 var error := up.cross(desired.y)
 var desired_omega := (error * 7.0).limit_length(3.0) + Vector3.UP * command.y * 1.6
 var omega_local := basis_now.transposed() * state.angular_velocity
 var alpha_local := basis_now.transposed() * ((desired_omega - state.angular_velocity) * 12.0)
 var torque := alpha_local * inertia + omega_local.cross(inertia * omega_local)
 var collective: float
 if altitude_hold or brake:
  target_height = clampf(target_height + climb * 2.5 * dt,0.15,17.0)
  var vz_target := clampf((target_height - state.transform.origin.y) * 2.0,-3.0,3.0)
  var az := clampf((vz_target - state.linear_velocity.y) * 4.0,-7.0,8.0)
  collective = mass * (9.81 + az) / maxf(up.y,0.35)
 else:
  target_height = state.transform.origin.y
  collective = mass * 9.81 * (1.0 + climb * 0.8)
 motor_targets = mix_thrust(collective,torque)
 if not stabilised: motor_targets = direct_motor_thrust.duplicate()
 if not motors_armed or crashed: motor_targets.fill(0.0)
 var rotor_reaction := advance_motors(motor_targets,dt)
 for i in range(4):
  state.apply_force(up * motors[i],basis_now * ROTORS[i])
 # Propeller drag, motor acceleration reaction, and spinning-rotor gyroscopic torque.
 var momentum := Vector3.ZERO
 for i in range(4): momentum.y -= SPINS[i] * rotor_inertia * rotor_speeds[i]
 var gyroscopic := -omega_local.cross(momentum)
 state.apply_torque(basis_now * (Vector3(0,rotor_reaction,0)+gyroscopic))
 var relative_air := basis_now.transposed() * (state.linear_velocity-wind_velocity)
 state.apply_central_force(basis_now * aerodynamic_force(relative_air))
 state.apply_torque(basis_now * aerodynamic_torque(omega_local))

func mix_thrust(collective: float, torque: Vector3) -> PackedFloat64Array:
 # X-layout inverse mixer. Scale differentials together on saturation rather
 # than clipping each motor separately and changing the requested torque axis.
 var delta := PackedFloat64Array([0,0,0,0])
 var span := 0.0
 for i in range(4):
  var p: Vector3 = ROTORS[i]
  delta[i] = (-p.z*torque.x+p.x*torque.z)/(4.0*ARM*ARM)+SPINS[i]*torque.y/(4.0*YAW_RATIO)
  span = maxf(span,absf(delta[i]))
 var capacity := MAX_THRUST * air_density/1.225
 var centre := clampf(collective/4.0,0,capacity)
 var room := minf(centre,capacity-centre)
 var scale := minf(1.0,room/span) if span>0 else 1.0
 var result := PackedFloat64Array([0,0,0,0])
 for i in range(4): result[i]=centre+delta[i]*scale
 return result

func advance_motors(targets: PackedFloat64Array, dt: float) -> float:
 # T=kT Ω² and Q=kQ Ω²; first-order lag acts on speed, not thrust.
 var max_speed := max_rpm*TAU/60.0
 var kt := MAX_THRUST/(max_speed*max_speed)*air_density/1.225
 var reaction := 0.0
 for i in range(4):
  var requested := sqrt(clampf(targets[i]/kt,0,max_speed*max_speed))
  var old := rotor_speeds[i]
  var tau := spool_up_seconds if requested>old else spool_down_seconds
  rotor_speeds[i] = lerpf(old,requested,1.0-exp(-dt/tau))
  motors[i] = kt*rotor_speeds[i]*rotor_speeds[i]
  reaction += SPINS[i]*(YAW_RATIO*motors[i]+rotor_inertia*(rotor_speeds[i]-old)/dt)
 return reaction

func aerodynamic_force(air_body: Vector3) -> Vector3:
 var quadratic := -0.5*air_density*drag_area*air_body*air_body.abs()
 var total := 0.0
 for force in motors: total += force
 # Rotor in-plane drag scales with sqrt(thrust); no fictitious rotor drag with motors off.
 var rotor_drag := -rotor_inplane_drag*sqrt(maxf(total,0)/(mass*9.81))*Vector3(air_body.x,0,air_body.z)
 return quadratic+rotor_drag

func aerodynamic_torque(rates: Vector3) -> Vector3:
 return -Vector3(0.004,0.006,0.004)*rates-Vector3(0.001,0.002,0.001)*rates*rates.abs()
