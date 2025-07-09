extends Node3D
class_name PlayerAnimationController

# References to body parts for animation
@onready var pelvis: Node3D = get_node_or_null("../PlayerModel/Pelvis")
@onready var left_upper_leg: Node3D = get_node_or_null("../PlayerModel/Pelvis/LeftHip/LeftUpperLeg")
@onready var right_upper_leg: Node3D = get_node_or_null("../PlayerModel/Pelvis/RightHip/RightUpperLeg")
@onready var left_lower_leg: Node3D = get_node_or_null("../PlayerModel/Pelvis/LeftHip/LeftUpperLeg/LeftLowerLeg")
@onready var right_lower_leg: Node3D = get_node_or_null("../PlayerModel/Pelvis/RightHip/RightUpperLeg/RightLowerLeg")
@onready var left_upper_arm: Node3D = get_node_or_null("../PlayerModel/Pelvis/Spine/Chest/LeftShoulder/LeftUpperArm")
@onready var right_upper_arm: Node3D = get_node_or_null("../PlayerModel/Pelvis/Spine/Chest/RightShoulder/RightUpperArm")
@onready var left_lower_arm: Node3D = get_node_or_null("../PlayerModel/Pelvis/Spine/Chest/LeftShoulder/LeftUpperArm/LeftLowerArm")
@onready var right_lower_arm: Node3D = get_node_or_null("../PlayerModel/Pelvis/Spine/Chest/RightShoulder/RightUpperArm/RightLowerArm")

# Animation State Machine
enum AnimationState {
	IDLE,
	WALK,
	RUN,
	KICK,
	TURN
}

var current_state: AnimationState = AnimationState.IDLE
var target_state: AnimationState = AnimationState.IDLE
var state_transition_time: float = 0.0
var transition_duration: float = 0.3

# Animation variables
var walk_time: float = 0.0
var idle_time: float = 0.0
var is_moving: bool = false
var is_kicking: bool = false
var kick_time: float = 0.0
var turn_time: float = 0.0
var movement_speed: float = 0.0
var last_velocity: Vector3 = Vector3.ZERO

# Animation parameters
const WALK_SPEED: float = 8.0
const RUN_SPEED: float = 12.0
const ARM_SWING_AMPLITUDE: float = 30.0
const LEG_SWING_AMPLITUDE: float = 25.0
const KICK_DURATION: float = 0.3
const TURN_DURATION: float = 0.2
const SPEED_THRESHOLD_WALK: float = 3.0
const SPEED_THRESHOLD_RUN: float = 6.0

# Smooth transition variables
var arm_swing_weight: float = 0.0
var leg_swing_weight: float = 0.0
var kick_weight: float = 0.0
var turn_weight: float = 0.0

func _ready():
	# Reset all rotations to neutral position
	reset_pose()
	current_state = AnimationState.IDLE
	target_state = AnimationState.IDLE

func _process(delta: float):
	# Handle state transitions
	handle_state_transitions(delta)
	
	# Update animation based on current state
	match current_state:
		AnimationState.IDLE:
			animate_idle(delta)
		AnimationState.WALK:
			animate_walking(delta)
		AnimationState.RUN:
			animate_running(delta)
		AnimationState.KICK:
			animate_kick(delta)
		AnimationState.TURN:
			animate_turning(delta)
	
	# Apply smooth blending between states
	apply_animation_blending(delta)

func handle_state_transitions(delta: float):
	if current_state != target_state:
		state_transition_time += delta
		if state_transition_time >= transition_duration:
			current_state = target_state
			state_transition_time = 0.0
			on_state_changed()

func on_state_changed():
	# Reset timers and weights when changing states
	match current_state:
		AnimationState.IDLE:
			arm_swing_weight = 0.0
			leg_swing_weight = 0.0
			idle_time = 0.0
		AnimationState.WALK:
			walk_time = 0.0
		AnimationState.RUN:
			walk_time = 0.0
		AnimationState.KICK:
			kick_time = 0.0
		AnimationState.TURN:
			turn_time = 0.0
			turn_weight = 0.0

func set_moving(moving: bool, velocity: Vector3):
	is_moving = moving and velocity.length() > 0.1
	movement_speed = velocity.length()
	
	# Determine target state based on movement
	if not is_moving:
		target_state = AnimationState.IDLE
	elif movement_speed < SPEED_THRESHOLD_WALK:
		target_state = AnimationState.WALK
	elif movement_speed < SPEED_THRESHOLD_RUN:
		target_state = AnimationState.WALK
	else:
		target_state = AnimationState.RUN
	
	# Check for turning
	if is_moving and last_velocity.length() > 0.1:
		var dot_product = velocity.normalized().dot(last_velocity.normalized())
		if dot_product < 0.7:  # Significant direction change
			target_state = AnimationState.TURN
	
	last_velocity = velocity

func trigger_kick(kick_force: float = 1.0):
	if current_state != AnimationState.KICK:
		target_state = AnimationState.KICK
		kick_time = 0.0
		kick_weight = kick_force  # Use kick force to influence animation intensity

func animate_walking(delta: float):
	walk_time += delta * WALK_SPEED
	
	# Smooth transition into walking animation
	arm_swing_weight = lerp(arm_swing_weight, 0.7, delta * 5.0)
	leg_swing_weight = lerp(leg_swing_weight, 0.8, delta * 5.0)
	
	# Leg animations - alternating walk cycle
	var left_leg_angle = sin(walk_time) * LEG_SWING_AMPLITUDE * leg_swing_weight
	var right_leg_angle = sin(walk_time + PI) * LEG_SWING_AMPLITUDE * leg_swing_weight
	
	if left_upper_leg:
		left_upper_leg.rotation_degrees.x = left_leg_angle
	if right_upper_leg:
		right_upper_leg.rotation_degrees.x = right_leg_angle
	
	# Lower leg follow-through
	if left_lower_leg:
		left_lower_leg.rotation_degrees.x = max(0, left_leg_angle * 0.5)
	if right_lower_leg:
		right_lower_leg.rotation_degrees.x = max(0, right_leg_angle * 0.5)
	
	# Arm animations - opposite to legs for natural movement
	var left_arm_angle = sin(walk_time + PI) * ARM_SWING_AMPLITUDE * 0.6 * arm_swing_weight
	var right_arm_angle = sin(walk_time) * ARM_SWING_AMPLITUDE * 0.6 * arm_swing_weight
	
	if left_upper_arm:
		left_upper_arm.rotation_degrees.x = left_arm_angle
	if right_upper_arm:
		right_upper_arm.rotation_degrees.x = right_arm_angle
	
	# Pelvis subtle bob
	if pelvis:
		pelvis.position.y = sin(walk_time * 2.0) * 0.05 * leg_swing_weight

func animate_running(delta: float):
	walk_time += delta * RUN_SPEED
	
	# More intense movement for running
	arm_swing_weight = lerp(arm_swing_weight, 1.2, delta * 6.0)
	leg_swing_weight = lerp(leg_swing_weight, 1.1, delta * 6.0)
	
	# Leg animations - more pronounced for running
	var left_leg_angle = sin(walk_time) * LEG_SWING_AMPLITUDE * 1.3 * leg_swing_weight
	var right_leg_angle = sin(walk_time + PI) * LEG_SWING_AMPLITUDE * 1.3 * leg_swing_weight
	
	if left_upper_leg:
		left_upper_leg.rotation_degrees.x = left_leg_angle
	if right_upper_leg:
		right_upper_leg.rotation_degrees.x = right_leg_angle
	
	# More pronounced lower leg movement
	if left_lower_leg:
		left_lower_leg.rotation_degrees.x = max(0, left_leg_angle * 0.8)
	if right_lower_leg:
		right_lower_leg.rotation_degrees.x = max(0, right_leg_angle * 0.8)
	
	# Stronger arm swing for running
	var left_arm_angle = sin(walk_time + PI) * ARM_SWING_AMPLITUDE * 0.9 * arm_swing_weight
	var right_arm_angle = sin(walk_time) * ARM_SWING_AMPLITUDE * 0.9 * arm_swing_weight
	
	if left_upper_arm:
		left_upper_arm.rotation_degrees.x = left_arm_angle
	if right_upper_arm:
		right_upper_arm.rotation_degrees.x = right_arm_angle
	
	# More pronounced pelvis movement
	if pelvis:
		pelvis.position.y = sin(walk_time * 2.0) * 0.1 * leg_swing_weight

func animate_turning(delta: float):
	turn_time += delta * 8.0
	turn_weight = lerp(turn_weight, 1.0, delta * 10.0)
	
	# Leaning animation for turning
	if pelvis:
		pelvis.rotation_degrees.z = sin(turn_time) * 10.0 * turn_weight
	
	# Arm positioning for balance during turns
	if left_upper_arm:
		left_upper_arm.rotation_degrees.z = sin(turn_time) * 15.0 * turn_weight
	if right_upper_arm:
		right_upper_arm.rotation_degrees.z = -sin(turn_time) * 15.0 * turn_weight
	
	# Transition back to movement after turn
	if turn_time > PI:
		if is_moving:
			target_state = AnimationState.WALK if movement_speed < SPEED_THRESHOLD_RUN else AnimationState.RUN
		else:
			target_state = AnimationState.IDLE

func animate_kick(delta: float):
	kick_time += delta * 3.0  # Faster kick animation
	
	# Kick animation phases
	var kick_phase = kick_time / KICK_DURATION
	var kick_intensity = kick_weight * 2.0  # Use kick force for intensity
	
	if kick_phase < 0.3:  # Wind-up phase
		# Pull back right leg for kick
		if right_upper_leg:
			right_upper_leg.rotation_degrees.x = lerp(0.0, -45.0 * kick_intensity, kick_phase / 0.3)
		if right_lower_leg:
			right_lower_leg.rotation_degrees.x = lerp(0.0, 60.0 * kick_intensity, kick_phase / 0.3)
		# Lean back slightly
		if pelvis:
			pelvis.rotation_degrees.x = lerp(0.0, -10.0 * kick_intensity, kick_phase / 0.3)
	elif kick_phase < 0.7:  # Strike phase
		# Forward kick motion
		var strike_progress = (kick_phase - 0.3) / 0.4
		if right_upper_leg:
			right_upper_leg.rotation_degrees.x = lerp(-45.0 * kick_intensity, 30.0 * kick_intensity, strike_progress)
		if right_lower_leg:
			right_lower_leg.rotation_degrees.x = lerp(60.0 * kick_intensity, 0.0, strike_progress)
		# Forward lean
		if pelvis:
			pelvis.rotation_degrees.x = lerp(-10.0 * kick_intensity, 5.0 * kick_intensity, strike_progress)
	else:  # Follow-through phase
		# Return to neutral
		var return_progress = (kick_phase - 0.7) / 0.3
		if right_upper_leg:
			right_upper_leg.rotation_degrees.x = lerp(30.0 * kick_intensity, 0.0, return_progress)
		if right_lower_leg:
			right_lower_leg.rotation_degrees.x = lerp(0.0, 0.0, return_progress)
		if pelvis:
			pelvis.rotation_degrees.x = lerp(5.0 * kick_intensity, 0.0, return_progress)
	
	# Arms for balance during kick
	if left_upper_arm:
		left_upper_arm.rotation_degrees.x = sin(kick_time * 2.0) * 20.0 * kick_intensity
	if right_upper_arm:
		right_upper_arm.rotation_degrees.x = sin(kick_time * 2.0 + PI) * 20.0 * kick_intensity
	
	# End kick animation
	if kick_time >= KICK_DURATION:
		target_state = AnimationState.IDLE if not is_moving else AnimationState.WALK

func animate_idle(delta: float):
	# Update idle timer
	idle_time += delta
	
	# Gentle breathing animation
	var breathing_time = idle_time * 0.5
	
	# Gradually reduce animation weights to idle
	arm_swing_weight = lerp(arm_swing_weight, 0.0, delta * 3.0)
	leg_swing_weight = lerp(leg_swing_weight, 0.0, delta * 3.0)
	
	# Subtle idle movements
	if pelvis:
		pelvis.position.y = sin(breathing_time) * 0.01
		pelvis.rotation_degrees.x = lerp(pelvis.rotation_degrees.x, 0.0, delta * 5.0)
		pelvis.rotation_degrees.z = lerp(pelvis.rotation_degrees.z, 0.0, delta * 5.0)
	
	# Return limbs to neutral position
	if left_upper_leg:
		left_upper_leg.rotation_degrees.x = lerp(left_upper_leg.rotation_degrees.x, 0.0, delta * 4.0)
	if right_upper_leg:
		right_upper_leg.rotation_degrees.x = lerp(right_upper_leg.rotation_degrees.x, 0.0, delta * 4.0)
	if left_lower_leg:
		left_lower_leg.rotation_degrees.x = lerp(left_lower_leg.rotation_degrees.x, 0.0, delta * 4.0)
	if right_lower_leg:
		right_lower_leg.rotation_degrees.x = lerp(right_lower_leg.rotation_degrees.x, 0.0, delta * 4.0)
	if left_upper_arm:
		left_upper_arm.rotation_degrees.x = lerp(left_upper_arm.rotation_degrees.x, 0.0, delta * 4.0)
		left_upper_arm.rotation_degrees.z = lerp(left_upper_arm.rotation_degrees.z, 0.0, delta * 4.0)
	if right_upper_arm:
		right_upper_arm.rotation_degrees.x = lerp(right_upper_arm.rotation_degrees.x, 0.0, delta * 4.0)
		right_upper_arm.rotation_degrees.z = lerp(right_upper_arm.rotation_degrees.z, 0.0, delta * 4.0)

func apply_animation_blending(_delta: float):
	# Smooth blending between different animation states
	var blend_factor = state_transition_time / transition_duration
	
	# Apply transition blending if needed
	if current_state != target_state and blend_factor < 1.0:
		# Blend between current and target state rotations
		var _blend_weight = smoothstep(0.0, 1.0, blend_factor)
		
		# TODO: Implement more sophisticated blending between specific states
		# For now, we rely on the lerp functions in individual animation functions

func reset_pose():
	# Reset all body parts to neutral position
	if pelvis:
		pelvis.rotation_degrees = Vector3.ZERO
		pelvis.position = Vector3.ZERO
	
	var body_parts = [
		left_upper_leg, right_upper_leg, left_lower_leg, right_lower_leg,
		left_upper_arm, right_upper_arm, left_lower_arm, right_lower_arm
	]
	
	for part in body_parts:
		if part:
			part.rotation_degrees = Vector3.ZERO
