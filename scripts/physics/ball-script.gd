extends RigidBody2D

# Configurações da física
@export var max_velocity := 1000.0
@export var velocity_damping := 0.98

# Estado da bola
var last_touched_by : Node2D = null
var is_in_play := true

# Referências
@onready var sprite := $Sprite2D
@onready var collision := $CollisionShape2D
@onready var trail := $Trail

func _ready():
	# Adicionar ao grupo para detecção
	add_to_group("ball")
	
	# Configurar física
	mass = GameConstants.BALL_MASS
	gravity_scale = GameConstants.BALL_GRAVITY_SCALE
	linear_damp = GameConstants.BALL_LINEAR_DAMP
	angular_damp = GameConstants.BALL_ANGULAR_DAMP
	
	# Configurar material de física
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = GameConstants.BALL_BOUNCE
	physics_material.friction = GameConstants.BALL_FRICTION
	physics_material_override = physics_material
	
	# Configurar camadas de colisão
	collision_layer = GameConstants.LAYER_BALL
	collision_mask = GameConstants.LAYER_PLAYERS | GameConstants.LAYER_WALLS | GameConstants.LAYER_GOALS
	
	# Habilitar monitoramento de contatos
	contact_monitor = true
	max_contacts_reported = 10
	
	# Conectar sinais
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Limitar velocidade máxima
	if linear_velocity.length() > max_velocity:
		linear_velocity = linear_velocity.normalized() * max_velocity
	
	# Aplicar damping adicional
	linear_velocity *= velocity_damping
	
	# Atualizar visual baseado na velocidade
	update_visual()

func receive_kick(force: Vector2, kick_position: Vector2):
	# Aplicar impulso no ponto de contato
	apply_impulse(force, kick_position - global_position)
	
	# Adicionar rotação baseada no ponto de contato
	var offset = (kick_position - global_position).normalized()
	var spin = offset.cross(force.normalized()) * 2.0
	apply_torque_impulse(spin)
	
	# Feedback visual
	sprite.modulate = Color(1.2, 1.2, 1.0)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Partículas ou efeitos (placeholder)
	create_kick_effect(kick_position)

func _on_body_entered(body):
	# Detectar colisões com jogadores
	if body.is_in_group("players"):
		last_touched_by = body
		
		# Aplicar pequeno impulso baseado na velocidade do jogador
		var player_velocity = body.velocity if body.has_property("velocity") else Vector2.ZERO
		if player_velocity.length() > 50:
			var impulse = player_velocity * 0.1
			apply_central_impulse(impulse)
	
	# Som de colisão (placeholder)
	play_collision_sound()

func update_visual():
	# Rotacionar sprite baseado no movimento
	if linear_velocity.length() > 10:
		sprite.rotation += linear_velocity.length() * 0.01
	
	# Escala baseada na altura (simulação 3D simples)
	var height_scale = remap(global_position.y, 0, GameConstants.FIELD_HEIGHT, 1.1, 0.9)
	sprite.scale = Vector2.ONE * height_scale
	
	# Trail effect (placeholder)
	if linear_velocity.length() > 300:
		if trail:
			trail.emitting = true
	else:
		if trail:
			trail.emitting = false

func create_kick_effect(pos: Vector2):
	# Placeholder para efeito visual de chute
	var effect = Sprite2D.new()
	effect.modulate = Color(1, 1, 0, 0.5)
	effect.scale = Vector2(2, 2)
	get_parent().add_child(effect)
	effect.global_position = pos
	
	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(4, 4), 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func play_collision_sound():
	# Placeholder para som
	pass

func reset_position():
	# Resetar para o centro do campo
	global_position = Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	is_in_play = true
