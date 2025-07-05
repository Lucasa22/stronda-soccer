extends Node3D

# Importa as constantes do jogo
const GameConstants = preload("res://scripts/globals/game-constants.gd")

# Cena simples para testar o jogo
@onready var arena := $Arena
@onready var players := $Players
@onready var ball := $Ball
@onready var ui := $UI
@onready var camera := $Camera3D

# Variáveis do jogo
var field_width := 800.0
var field_height := 600.0
var player = null  # Referência ao jogador controlado pelo usuário
var score_player1 := 0
var score_player2 := 0
var debug_mode := false
var current_state = GameConstants.GameState.PLAYING

func _ready():
	print("Jogo iniciado!")
	
	# Configurar câmera
	setup_camera()
	
	# Configurar iluminação 3D
	setup_lighting()
	
	# Criar campo visual
	create_field()
	
	# Criar jogadores
	create_players()
	
	# Criar bola
	create_ball()
	
	# Criar UI básica
	create_ui()

func setup_lighting():
	# Luz direcional principal (sol)
	var sun = DirectionalLight3D.new()
	sun.position = Vector3(field_width / 2, 300, field_height / 2)
	sun.rotation_degrees = Vector3(-45, -45, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	
	# Luz ambiente (WorldEnvironment)
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.1, 0.1, 0.1)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)

func setup_camera():
	# Posição elevada para visualização do campo em 3D
	camera.position = Vector3(field_width / 2, 300, field_height)
	camera.rotation_degrees = Vector3(-60, 0, 0)
	camera.fov = 45
	camera.current = true

func create_field():
	# Criar fundo do campo (plano 3D)
	var field_mesh = CSGBox3D.new()
	field_mesh.size = Vector3(field_width, 1, field_height)
	field_mesh.position = Vector3(field_width / 2, -0.5, field_height / 2)
	
	# Material verde para o campo
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.2, 0.8, 0.2, 1.0)  # Verde
	field_mesh.material = field_material
	arena.add_child(field_mesh)
	
	# Linha central
	var center_line = CSGBox3D.new()
	center_line.size = Vector3(4, 0.5, field_height)
	center_line.position = Vector3(field_width / 2, 0.1, field_height / 2)
	
	# Material branco para linhas
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color.WHITE
	center_line.material = line_material
	arena.add_child(center_line)
	
	# Círculo central
	var center_circle = create_circle_3d(Vector3(field_width / 2, 0.1, field_height / 2), 50, line_material)
	arena.add_child(center_circle)
	
	# Gols
	create_goals()

func create_circle_3d(pos: Vector3, radius: float, material: Material) -> Node3D:
	var circle = Node3D.new()
	circle.position = pos
	
	# Criar círculo em 3D usando vários segmentos
	var segments = 32
	var angle_step = 2 * PI / segments
	
	for i in range(segments):
		var segment = CSGBox3D.new()
		var angle = i * angle_step
		var next_angle = (i + 1) * angle_step
		
		var start_pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var end_pos = Vector3(cos(next_angle) * radius, 0, sin(next_angle) * radius)
		var center_pos = (start_pos + end_pos) / 2
		
		# Calcular tamanho e rotação do segmento
		var length = start_pos.distance_to(end_pos)
		var width = 3  # largura da linha
		
		segment.size = Vector3(length, 0.2, width)
		segment.position = center_pos
		
		# Rotacionar para alinhar com o ângulo
		segment.look_at_from_position(center_pos, center_pos + Vector3(0, 1, 0), Vector3(0, 0, 1))
		segment.rotate_object_local(Vector3(0, 1, 0), angle + PI/2)
		
		segment.material = material
		circle.add_child(segment)
	
	return circle

# Mantém a função original para compatibilidade temporária
func create_circle(pos: Vector2, radius: float, color: Color) -> Node2D:
	var circle = Node2D.new()
	circle.position = pos
	
	# Criar círculo usando Line2D
	var line = Line2D.new()
	line.width = 3
	line.default_color = color
	
	var points = []
	for i in range(33):  # 32 pontos + 1 para fechar
		var angle = i * TAU / 32
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	line.points = PackedVector2Array(points)
	circle.add_child(line)
	
	return circle

func create_goals():
	var goal_width = 120.0
	var goal_height = 20.0
	var _goal_depth = 40.0  # Profundidade para 3D (será usado no futuro)
	
	# Material amarelo para os gols
	var goal_material = StandardMaterial3D.new()
	goal_material.albedo_color = Color.YELLOW
	
	# Gol esquerdo (estrutura 3D)
	var left_goal = Node3D.new()
	left_goal.position = Vector3(-goal_width/2, 0, field_height / 2)
	arena.add_child(left_goal)
	
	# Base do gol
	var left_base = CSGBox3D.new()
	left_base.size = Vector3(goal_width, 1, goal_height)
	left_base.position = Vector3(0, 0, 0)
	left_base.material = goal_material
	left_goal.add_child(left_base)
	
	# Barra superior
	var left_top = CSGBox3D.new()
	left_top.size = Vector3(goal_width, 1, 1)
	left_top.position = Vector3(0, goal_height, 0)
	left_top.material = goal_material
	left_goal.add_child(left_top)
	
	# Postes laterais
	var left_post1 = CSGBox3D.new()
	left_post1.size = Vector3(1, goal_height, 1)
	left_post1.position = Vector3(-goal_width/2, goal_height/2, 0)
	left_post1.material = goal_material
	left_goal.add_child(left_post1)
	
	var left_post2 = CSGBox3D.new()
	left_post2.size = Vector3(1, goal_height, 1)
	left_post2.position = Vector3(goal_width/2, goal_height/2, 0)
	left_post2.material = goal_material
	left_goal.add_child(left_post2)
	
	# Gol direito (estrutura 3D)
	var right_goal = Node3D.new()
	right_goal.position = Vector3(field_width + goal_width/2, 0, field_height / 2)
	arena.add_child(right_goal)
	
	# Base do gol
	var right_base = CSGBox3D.new()
	right_base.size = Vector3(goal_width, 1, goal_height)
	right_base.position = Vector3(0, 0, 0)
	right_base.material = goal_material
	right_goal.add_child(right_base)
	
	# Barra superior
	var right_top = CSGBox3D.new()
	right_top.size = Vector3(goal_width, 1, 1)
	right_top.position = Vector3(0, goal_height, 0)
	right_top.material = goal_material
	right_goal.add_child(right_top)
	
	# Postes laterais
	var right_post1 = CSGBox3D.new()
	right_post1.size = Vector3(1, goal_height, 1)
	right_post1.position = Vector3(-goal_width/2, goal_height/2, 0)
	right_post1.material = goal_material
	right_goal.add_child(right_post1)
	
	var right_post2 = CSGBox3D.new()
	right_post2.size = Vector3(1, goal_height, 1)
	right_post2.position = Vector3(goal_width/2, goal_height/2, 0)
	right_post2.material = goal_material
	right_goal.add_child(right_post2)

func create_players():
	# Jogador 1 (Azul)
	var player1 = create_player(Vector3(field_width / 4, 0, field_height / 2), Color.BLUE, "P1")
	players.add_child(player1)
	
	# Jogador 2 (Vermelho)
	var player2 = create_player(Vector3(3 * field_width / 4, 0, field_height / 2), Color.RED, "P2")
	players.add_child(player2)

func create_player(pos: Vector3, color: Color, player_name: String) -> Node3D:
	var player_node = Node3D.new()
	player_node.position = pos
	
	# Modelo do jogador (usando CSG por enquanto)
	var player_body = CSGBox3D.new()
	player_body.size = Vector3(30, 40, 30)
	player_body.position = Vector3(0, 20, 0) # Metade da altura para ficar sobre o chão
	
	# Material colorido para o jogador
	var player_material = StandardMaterial3D.new()
	player_material.albedo_color = color
	player_body.material = player_material
	player_node.add_child(player_body)
	
	# Nome do jogador (utilizando label 3D)
	var label_3d = Label3D.new()
	label_3d.text = player_name
	label_3d.position = Vector3(0, 50, 0)
	label_3d.font_size = 24
	label_3d.modulate = Color.WHITE
	player_node.add_child(label_3d)
	
	return player_node

func create_ball():
	# Criar bola 3D usando CSGSphere
	var ball_mesh = CSGSphere3D.new()
	ball_mesh.radius = 10.0
	ball_mesh.position = Vector3(field_width / 2, 10, field_height / 2) # Posição inicial
	
	# Material branco para a bola
	var ball_material = StandardMaterial3D.new()
	ball_material.albedo_color = Color.WHITE
	ball_mesh.material = ball_material
	
	ball.add_child(ball_mesh)

func create_ui():
	# Placar
	var score_label = Label.new()
	score_label.text = "PLACAR: 0 - 0"
	score_label.position = Vector2(10, 10)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_font_size_override("font_size", 24)
	ui.add_child(score_label)
	
	# Instruções
	var instructions = Label.new()
	instructions.text = "Use WASD para mover - Pressione ESC para sair"
	instructions.position = Vector2(10, 50)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(instructions)

func _process(_delta):
	# Input básico
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_R:
				get_tree().reload_current_scene()
			KEY_P:
				print("Jogo pausado/despausado")
	camera.limit_bottom = int(GameConstants.FIELD_HEIGHT)

func update_camera():
	# Pequeno movimento da câmera seguindo a bola (sutil)
	if ball and ball.get_child_count() > 0:
		var ball_mesh = ball.get_child(0)
		var target_pos = Vector3(GameConstants.FIELD_WIDTH / 2, 300, GameConstants.FIELD_HEIGHT / 2)
		target_pos += (ball_mesh.global_position - target_pos) * Vector3(0.1, 0, 0.1)
		camera.position = camera.position.lerp(target_pos, 0.05)

func handle_global_input():
	# Reset (R)
	if Input.is_action_just_pressed("ui_text_submit"):
		reset_positions()
	
	# Pause (ESC)
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func reset_positions():
	# Resetar jogador
	if player:
		player.global_position = Vector3(GameConstants.FIELD_WIDTH * 0.3, 0, GameConstants.FIELD_HEIGHT / 2)
		# Assumindo que velocity está disponível e é Vector3 no novo controlador
		if player.has_method("set_velocity"):
			player.velocity = Vector3.ZERO
	
	# Resetar bola
	if ball and ball.get_child_count() > 0:
		var ball_mesh = ball.get_child(0)
		ball_mesh.global_position = Vector3(field_width / 2, 10, field_height / 2)
		# Se a bola tiver física, resetar movimento
		if ball.has_method("reset_position"):
			ball.reset_position()

func toggle_pause():
	if current_state == GameConstants.GameState.PLAYING:
		current_state = GameConstants.GameState.PAUSED
		get_tree().paused = true
	elif current_state == GameConstants.GameState.PAUSED:
		current_state = GameConstants.GameState.PLAYING
		get_tree().paused = false

func on_goal_scored(team: int):
	current_state = GameConstants.GameState.GOAL_SCORED
	
	# Atualizar pontuação
	if team == 1:
		score_player1 += 1
	else:
		score_player2 += 1
	
	# Feedback visual
	create_goal_celebration()
	
	# Reset após delay
	await get_tree().create_timer(2.0).timeout
	reset_positions()
	current_state = GameConstants.GameState.PLAYING

func create_goal_celebration():
	# Placeholder para celebração de gol em 3D
	var label_3d = Label3D.new()
	label_3d.text = "GOOOOOL!"
	label_3d.font_size = 64
	label_3d.modulate = Color(1, 1, 0)
	label_3d.position = Vector3(GameConstants.FIELD_WIDTH / 2, 100, GameConstants.FIELD_HEIGHT / 2)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Sempre olha para a câmera
	add_child(label_3d)
	
	var tween = create_tween()
	tween.tween_property(label_3d, "scale", Vector3(2, 2, 2), 0.5)
	tween.parallel().tween_property(label_3d, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label_3d.queue_free)

func update_ui():
	# Atualizar pontuação na UI
	if ui and ui.has_node("ScoreLabel"):
		ui.get_node("ScoreLabel").text = "%d - %d" % [score_player1, score_player2]

func create_debug_display():
	var debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(10, 10)
	debug_label.add_theme_font_size_override("font_size", 14)
	ui.add_child(debug_label)
	
	# Atualizar debug info a cada frame
	set_process(true)

func _physics_process(_delta):
	if debug_mode and ui.has_node("DebugLabel"):
		var debug_label = ui.get_node("DebugLabel")
		var debug_text = ""
		
		if player:
			debug_text += "Player Pos: %s\n" % player.global_position.round()
			debug_text += "Player Vel: %s\n" % player.velocity.round()
		
		if ball:
			debug_text += "Ball Pos: %s\n" % ball.global_position.round()
			debug_text += "Ball Vel: %s\n" % ball.linear_velocity.round()
		
		debug_text += "FPS: %d" % Engine.get_frames_per_second()
		
		debug_label.text = debug_text
