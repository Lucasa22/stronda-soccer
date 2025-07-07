extends Node3D
class_name PlayerAnimationController

# References to body parts for animation
@onready var pelvis: Node3D = $../PlayerModel/Pelvis
@onready var left_upper_leg: Node3D = $../PlayerModel/Pelvis/LeftHip/LeftUpperLeg
@onready var right_upper_leg: Node3D = $../PlayerModel/Pelvis/RightHip/RightUpperLeg
@onready var left_lower_leg: Node3D = $../PlayerModel/Pelvis/LeftHip/LeftUpperLeg/LeftLowerLeg
@onready var right_lower_leg: Node3D = $../PlayerModel/Pelvis/RightHip/RightUpperLeg/RightLowerLeg
@onready var left_upper_arm: Node3D = $../PlayerModel/Pelvis/Spine/Chest/LeftShoulder/LeftUpperArm
@onready var right_upper_arm: Node3D = $../PlayerModel/Pelvis/Spine/Chest/RightShoulder/RightUpperArm
@onready var left_lower_arm: Node3D = $../PlayerModel/Pelvis/Spine/Chest/LeftShoulder/LeftUpperArm/LeftLowerArm
@onready var right_lower_arm: Node3D = $../PlayerModel/Pelvis/Spine/Chest/RightShoulder/RightUpperArm/RightLowerArm

# Animation variables
var walk_time: float = 0.0
var is_moving: bool = false
var is_kicking: bool = false
var kick_time: float = 0.0

# Animation parameters
const WALK_SPEED: float = 8.0
const ARM_SWING_AMPLITUDE: float = 30.0
const LEG_SWING_AMPLITUDE: float = 25.0
const KICK_DURATION: float = 0.3

func _ready():
	# Reset all rotations to neutral position
	reset_pose()

func _process(delta: float):
	if is_moving and not is_kicking:
		animate_walking(delta)
	elif is_kicking:
		animate_kick(delta)
	else:
		animate_idle(delta)

func set_moving(moving: bool, velocity: Vector3):
	is_moving = moving and velocity.length() > 0.1

func trigger_kick():
	if not is_kicking:
		is_kicking = true
		kick_time = 0.0

func animate_walking(delta: float):
	walk_time += delta * WALK_SPEED
	
	# Leg animations - alternating walk cycle
	var leg_swing = sin(walk_time) * deg_to_rad(LEG_SWING_AMPLITUDE)
	if left_upper_leg: left_upper_leg.rotation.x = leg_swing
	if right_upper_leg: right_upper_leg.rotation.x = -leg_swing
	
	# Slight knee bend during walk
	var knee_bend = abs(sin(walk_time * 2)) * deg_to_rad(15)
	if left_lower_leg: left_lower_leg.rotation.x = -knee_bend
	if right_lower_leg: right_lower_leg.rotation.x = -knee_bend
	
	# Arm swing - opposite to legs
	var arm_swing = sin(walk_time) * deg_to_rad(ARM_SWING_AMPLITUDE)
	if left_upper_arm: left_upper_arm.rotation.x = -arm_swing * 0.6  # Arms swing less than legs
	if right_upper_arm: right_upper_arm.rotation.x = arm_swing * 0.6
	
	# Slight elbow movement
	var elbow_swing = sin(walk_time * 1.5) * deg_to_rad(10)
	if left_lower_arm: left_lower_arm.rotation.x = -abs(elbow_swing)
	if right_lower_arm: right_lower_arm.rotation.x = -abs(elbow_swing)

func animate_kick(delta: float):
	kick_time += delta
	
	# Kick animation curve (0 to 1 over kick duration)
	var kick_progress = kick_time / KICK_DURATION
	
	if kick_progress < 1.0:
		# Swing right leg forward for kick
		var kick_angle = ease_in_out_sine(kick_progress) * deg_to_rad(60)
		if right_upper_leg: right_upper_leg.rotation.x = -kick_angle
		
		# Bend knee during kick
		var knee_angle = ease_in_out_sine(kick_progress) * deg_to_rad(30)
		if right_lower_leg: right_lower_leg.rotation.x = -knee_angle
		
		# Lean body slightly
		if pelvis: pelvis.rotation.x = ease_in_out_sine(kick_progress) * deg_to_rad(5)
		
		# Counter-balance with arms
		if left_upper_arm: left_upper_arm.rotation.x = kick_angle * 0.3
		if right_upper_arm: right_upper_arm.rotation.x = -kick_angle * 0.3
	else:
		# Kick finished, return to idle
		is_kicking = false
		reset_pose()

func animate_idle(delta: float):
	# Gentle breathing animation
	var breath_time = Time.get_time_dict_from_system()["second"] as float
	var breath_factor = sin(breath_time * 2) * 0.02
	
	# Slight chest movement
	if pelvis:
		pelvis.rotation.x = lerp(pelvis.rotation.x, breath_factor, delta * 2.0)
	
	# Return limbs to neutral position
	reset_limbs_to_neutral(delta)

func reset_pose():
	if left_upper_leg: left_upper_leg.rotation = Vector3.ZERO
	if right_upper_leg: right_upper_leg.rotation = Vector3.ZERO
	if left_lower_leg: left_lower_leg.rotation = Vector3.ZERO
	if right_lower_leg: right_lower_leg.rotation = Vector3.ZERO
	if left_upper_arm: left_upper_arm.rotation = Vector3.ZERO
	if right_upper_arm: right_upper_arm.rotation = Vector3.ZERO
	if left_lower_arm: left_lower_arm.rotation = Vector3.ZERO
	if right_lower_arm: right_lower_arm.rotation = Vector3.ZERO
	if pelvis: pelvis.rotation = Vector3.ZERO

func reset_limbs_to_neutral(delta: float):
	var reset_speed = delta * 5.0
	
	if left_upper_leg: left_upper_leg.rotation.x = lerp(left_upper_leg.rotation.x, 0.0, reset_speed)
	if right_upper_leg: right_upper_leg.rotation.x = lerp(right_upper_leg.rotation.x, 0.0, reset_speed)
	if left_lower_leg: left_lower_leg.rotation.x = lerp(left_lower_leg.rotation.x, 0.0, reset_speed)
	if right_lower_leg: right_lower_leg.rotation.x = lerp(right_lower_leg.rotation.x, 0.0, reset_speed)
	if left_upper_arm: left_upper_arm.rotation.x = lerp(left_upper_arm.rotation.x, 0.0, reset_speed)
	if right_upper_arm: right_upper_arm.rotation.x = lerp(right_upper_arm.rotation.x, 0.0, reset_speed)
	if left_lower_arm: left_lower_arm.rotation.x = lerp(left_lower_arm.rotation.x, 0.0, reset_speed)
	if right_lower_arm: right_lower_arm.rotation.x = lerp(right_lower_arm.rotation.x, 0.0, reset_speed)

# Custom easing function
func ease_in_out_sine(x: float) -> float:
	return -(cos(PI * x) - 1) / 2
