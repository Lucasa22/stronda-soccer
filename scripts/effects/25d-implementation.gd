# Player25D.gd - Jogador com visual 3D mas física 2D
extends CharacterBody2D

# Visual 3D
@onready var sprite_3d := $SubViewport/Camera3D/PlayerModel
@onready var shadow := $Shadow
@export var jump_height_visual := 40.0

# Estado
var visual_height := 0.0
var is_jumping := false
var jump_progress := 0.0

# Referência ao script original
# ... (todo código do Player.gd original) ...

func _ready():
    # Setup do viewport para renderizar o modelo 3D
    setup_3d_viewport()
    
    # Código original do _ready()
    collision_layer = GameConstants.LAYER_PLAYERS
    collision_mask = GameConstants.LAYER_WALLS | GameConstants.LAYER_PLAYERS

func _physics_process(delta):
    # Física 2D original
    handle_input()
    
    if not is_on_floor():
        velocity.y += get_gravity().y * delta
        current_state = State.AIR
    else:
        current_state = State.GROUND
        can_double_jump = true
        is_jumping = false
        jump_progress = 0.0
    
    apply_movement(delta)
    handle_jump()
    
    if kick_cooldown > 0:
        kick_cooldown -= delta
    
    if Input.is_action_just_pressed("kick") and kick_cooldown <= 0:
        kick_ball()
    
    move_and_slide()
    
    # Atualizar visual 3D
    update_3d_visual(delta)
    update_shadow()

func update_3d_visual(delta):
    # Simular altura visual durante o salto
    if current_state == State.AIR:
        # Parábola do salto
        jump_progress = clamp(jump_progress + delta * 2.0, 0.0, 1.0)
        visual_height = sin(jump_progress * PI) * jump_height_visual
    else:
        visual_height = move_toward(visual_height, 0.0, 100.0 * delta)
    
    # Aplicar ao modelo 3D
    if sprite_3d:
        sprite_3d.position.y = visual_height / 10.0 # Escala para o viewport 3D
        
        # Rotação durante movimento
        if velocity.length() > 10:
            sprite_3d.rotation.y = lerp_angle(
                sprite_3d.rotation.y,
                atan2(-velocity.x, velocity.y),
                10.0 * delta
            )

func update_shadow():
    if shadow:
        # Sombra fica maior quando jogador está no ar
        var shadow_scale = 1.0 - (visual_height / jump_height_visual) * 0.3
        shadow.scale = Vector2.ONE * shadow_scale
        shadow.modulate.a = shadow_scale

func setup_3d_viewport():
    # Criar SubViewport para renderizar modelo 3D
    var viewport = SubViewport.new()
    viewport.size = Vector2(128, 128)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg = true
    
    # Camera 3D dentro do viewport
    var camera = Camera3D.new()
    camera.position = Vector3(0, 2, 5)
    camera.look_at(Vector3.ZERO, Vector3.UP)
    camera.fov = 30
    viewport.add_child(camera)
    
    # Luz
    var light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -45, 0)
    viewport.add_child(light)
    
    # Modelo do jogador (placeholder)
    var player_model = CSGCylinder3D.new()
    player_model.height = 1.8
    player_model.radius = 0.4
    player_model.material = StandardMaterial3D.new()
    player_model.material.albedo_color = Color(0.2, 0.2, 0.8)
    camera.add_child(player_model)
    
    add_child(viewport)
    
    # Sprite que mostra o viewport
    var viewport_sprite = Sprite2D.new()
    viewport_sprite.texture = viewport.get_texture()
    viewport_sprite.centered = true
    add_child(viewport_sprite)

# ========================================
# Ball25D.gd - Bola com visual 3D
# ========================================
extends RigidBody2D

@onready var ball_mesh := $BallMesh
@onready var shadow := $Shadow
@export var max_height := 100.0

var height := 0.0
var vertical_velocity := 0.0
var spin_rotation := Vector3.ZERO

func _ready():
    # Setup original
    add_to_group("ball")
    setup_physics()
    
    # Setup visual 3D
    setup_3d_visual()

func _physics_process(delta):
    # Física 2D original
    if linear_velocity.length() > max_velocity:
        linear_velocity = linear_velocity.normalized() * max_velocity
    
    linear_velocity *= velocity_damping
    
    # Simular altura (bouncing)
    update_height_simulation(delta)
    
    # Atualizar visual 3D
    update_3d_visual(delta)

func update_height_simulation(delta):
    # Gravidade para altura visual
    vertical_velocity -= 500.0 * delta
    height += vertical_velocity * delta
    
    # Quicar quando toca o "chão"
    if height <= 0:
        height = 0
        if abs(vertical_velocity) > 50:
            vertical_velocity = -vertical_velocity * 0.7 # Bounce
        else:
            vertical_velocity = 0
    
    # Adicionar impulso vertical em colisões
    if get_contact_count() > 0:
        vertical_velocity = abs(linear_velocity.length()) * 0.3

func update_3d_visual(delta):
    # Rotação baseada no movimento
    if linear_velocity.length() > 10:
        var roll_speed = linear_velocity.length() / 50.0
        spin_rotation.x += roll_speed * delta * sign(linear_velocity.x)
        spin_rotation.z += roll_speed * delta * sign(linear_velocity.y)
    
    # Aplicar ao mesh
    if ball_mesh:
        ball_mesh.position.y = height / 50.0
        ball_mesh.rotation = spin_rotation
    
    # Sombra
    if shadow:
        var shadow_scale = 1.0 - (height / max_height) * 0.5
        shadow.scale = Vector2.ONE * shadow_scale
        shadow.modulate.a = shadow_scale * 0.7

func receive_kick(force: Vector2, kick_position: Vector2):
    # Física 2D original
    apply_impulse(force, kick_position - global_position)
    
    # Adicionar componente vertical para chutes
    vertical_velocity = force.length() * 0.4
    
    # Spin extra
    var offset = (kick_position - global_position).normalized()
    spin_rotation.y += offset.cross(force.normalized()) * 0.1

# ========================================
# Arena25D.gd - Arena com profundidade visual
# ========================================
extends Node2D

@export var use_perspective := true
@export var field_texture: Texture2D

func _ready():
    if use_perspective:
        create_perspective_field()
    else:
        create_flat_field()
    
    create_3d_walls()
    create_depth_markers()

func create_perspective_field():
    # Campo com perspectiva usando Polygon2D
    var field = Polygon2D.new()
    
    # Trapézio para simular perspectiva
    var points = PackedVector2Array([
        Vector2(200, 100),  # Top-left
        Vector2(1080, 100), # Top-right  
        Vector2(1180, 620), # Bottom-right
        Vector2(100, 620)   # Bottom-left
    ])
    
    field.polygon = points
    field.color = Color(0.2, 0.6, 0.2)
    field.texture = field_texture
    
    # UV mapping para perspectiva correta
    field.uv = PackedVector2Array([
        Vector2(0, 0),
        Vector2(1, 0),
        Vector2(1, 1),
        Vector2(0, 1)
    ])
    
    add_child(field)

func create_3d_walls():
    # Paredes com altura visual
    var wall_height = 40
    
    # Parede superior (mais fina por perspectiva)
    var top_wall = Polygon2D.new()
    top_wall.polygon = PackedVector2Array([
        Vector2(200, 60),
        Vector2(1080, 60),
        Vector2(1080, 100),
        Vector2(200, 100)
    ])
    top_wall.color = Color(0.3, 0.3, 0.3)
    add_child(top_wall)
    
    # Paredes laterais com perspectiva
    create_side_wall(true)  # Esquerda
    create_side_wall(false) # Direita

func create_side_wall(left_side: bool):
    var wall = Line2D.new()
    wall.width = 4.0
    wall.default_color = Color(0.4, 0.4, 0.4)
    wall.add_point(Vector2(200 if left_side else 1080, 100))
    wall.add_point(Vector2(100 if left_side else 1180, 620))
    
    # Gradiente para profundidade
    var gradient = Gradient.new()
    gradient.add_point(0.0, Color(0.6, 0.6, 0.6))
    gradient.add_point(1.0, Color(0.3, 0.3, 0.3))
    wall.gradient = gradient
    
    add_child(wall)