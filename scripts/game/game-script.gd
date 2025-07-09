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
	sun.position = Vector3(field_width / 2, GameConstants.CAMERA_HEIGHT, field_height / 2)
	sun.rotation_degrees = Vector3(-45, -45, 0)
	sun.light_energy = GameConstants.SUN_ENERGY
	sun.shadow_enabled = true
	add_child(sun)
	
	# Luz ambiente (WorldEnvironment)
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.ambient_light_color = Color(0.1, 0.1, 0.1)
	environment.ambient_light_energy = GameConstants.AMBIENT_ENERGY
	env.environment = environment
	add_child(env)

func setup_camera():
	# Posição elevada para visualização do campo em 3D usando constantes
	camera.position = Vector3(GameConstants.FIELD_WIDTH / 2, GameConstants.CAMERA_HEIGHT, GameConstants.FIELD_DEPTH + GameConstants.CAMERA_DISTANCE)
	camera.rotation_degrees = Vector3(GameConstants.CAMERA_ANGLE, 0, 0)
	camera.fov = GameConstants.CAMERA_FOV
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
	
	# Gol esquerdo (Area3D para detecção)
	var left_goal_area = Area3D.new()
	left_goal_area.name = "Goal_Team1" # Identificador para o time 1 (bola entra aqui, time 2 marca)
	left_goal_area.position = Vector3(0, GameConstants.GOAL_HEIGHT / 2, field_height / 2) # Ajustar posição X para o limite do campo
	left_goal_area.collision_layer = 0 # Não colide com nada
	left_goal_area.collision_mask = GameConstants.LAYER_BALL # Detecta apenas a bola
	left_goal_area.add_to_group("goals")

	var left_goal_shape = BoxShape3D.new()
	left_goal_shape.size = Vector3(GameConstants.WALL_THICKNESS, GameConstants.GOAL_HEIGHT, GameConstants.GOAL_WIDTH)

	var left_collision_shape = CollisionShape3D.new()
	left_collision_shape.shape = left_goal_shape
	left_goal_area.add_child(left_collision_shape)
	arena.add_child(left_goal_area)

	# Visualização do Gol Esquerdo (usando CSGBox3D)
	var left_goal_visual = CSGBox3D.new()
	left_goal_visual.size = Vector3(GameConstants.WALL_THICKNESS, GameConstants.GOAL_HEIGHT, GameConstants.GOAL_WIDTH)
	left_goal_visual.position = left_goal_area.position
	left_goal_visual.material = goal_material
	arena.add_child(left_goal_visual)

	# Gol direito (Area3D para detecção)
	var right_goal_area = Area3D.new()
	right_goal_area.name = "Goal_Team2" # Identificador para o time 2 (bola entra aqui, time 1 marca)
	right_goal_area.position = Vector3(field_width, GameConstants.GOAL_HEIGHT / 2, field_height / 2) # Ajustar posição X para o limite do campo
	right_goal_area.collision_layer = 0 # Não colide com nada
	right_goal_area.collision_mask = GameConstants.LAYER_BALL # Detecta apenas a bola
	right_goal_area.add_to_group("goals")

	var right_goal_shape = BoxShape3D.new()
	right_goal_shape.size = Vector3(GameConstants.WALL_THICKNESS, GameConstants.GOAL_HEIGHT, GameConstants.GOAL_WIDTH)

	var right_collision_shape = CollisionShape3D.new()
	right_collision_shape.shape = right_goal_shape
	right_goal_area.add_child(right_collision_shape)
	arena.add_child(right_goal_area)

	# Visualização do Gol Direito (usando CSGBox3D)
	var right_goal_visual = CSGBox3D.new()
	right_goal_visual.size = Vector3(GameConstants.WALL_THICKNESS, GameConstants.GOAL_HEIGHT, GameConstants.GOAL_WIDTH)
	right_goal_visual.position = right_goal_area.position
	right_goal_visual.material = goal_material
	arena.add_child(right_goal_visual)


func create_players():
	# Instanciar cena do jogador 3D
	var player_scene = preload("res://scenes/player/Player3D_Modular.tscn")
	
	# Jogador 1 (Azul)
	var player1 = player_scene.instantiate()
	player1.position = Vector3(GameConstants.FIELD_WIDTH / 4, 0, GameConstants.FIELD_DEPTH / 2)
	player1.player_id = 1
	player1.team = 1
	player1.player_name = "P1"
	player1.set_team_color(GameConstants.TEAM_1_COLOR)
	players.add_child(player1)
	
	# Jogador 2 (Vermelho)
	var player2 = player_scene.instantiate()
	player2.position = Vector3(3 * GameConstants.FIELD_WIDTH / 4, 0, GameConstants.FIELD_DEPTH / 2)
	player2.player_id = 2
	player2.team = 2
	player2.player_name = "P2"
	player2.set_team_color(GameConstants.TEAM_2_COLOR)
	players.add_child(player2)
	
	# Definir player como referência ao primeiro jogador
	player = player1

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
	# Instanciar cena da bola 3D
	var ball_scene = preload("res://scenes/ball/Ball3D_Simple.tscn")
	var ball_instance = ball_scene.instantiate()
	ball_instance.position = Vector3(field_width / 2, GameConstants.BALL_RADIUS + 5, field_height / 2)
	ball.add_child(ball_instance)
	
	# Definir referência da bola para os jogadores
	for child in players.get_children():
		if child.has_method("set_ball_reference"):
			child.set_ball_reference(ball_instance)

	# Conectar sinal de gol da bola
	if not ball_instance.is_connected("goal_scored_signal", Callable(self, "_on_ball_goal_scored")):
		ball_instance.connect("goal_scored_signal", Callable(self, "_on_ball_goal_scored"))

func create_ui():
	# Placar
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "PLACAR: 0 - 0"
	score_label.position = Vector2(10, 10)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_font_size_override("font_size", 24)
	ui.add_child(score_label)
	
	# Instruções
	var instructions = Label.new()
	instructions.text = "WASD: Mover | Shift: Correr | Espaço: Pular | E: Chutar | ESC: Sair | R: Reiniciar"
	instructions.position = Vector2(10, 50)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(instructions)

func _process(_delta):
	# Input básico
	if Input.is_action_just_pressed("ui_cancel"): # Geralmente ESC
		get_tree().quit() # Sair do jogo
	
	# Processar inputs dos jogadores
	handle_players_input()

func handle_player_input():
	# Esta função está obsoleta e seu conteúdo foi movido/integrado para handle_players_input()
	# Pode ser removida ou deixada vazia.
	pass

func handle_players_input():
	for p_node in players.get_children():
		if not p_node is Player3D:
			continue

		var input_dir = Vector3()
		var sprint = false
		var jump = false
		var kick = false

		if p_node.player_id == 1:
			if Input.is_action_pressed("ui_left"): input_dir.x -= 1
			if Input.is_action_pressed("ui_right"): input_dir.x += 1
			if Input.is_action_pressed("ui_up"): input_dir.z -= 1
			if Input.is_action_pressed("ui_down"): input_dir.z += 1

			# Assumindo que você criou ações de input chamadas "sprint", "kick"
			# Se não, substitua por Input.is_key_pressed(KEY_SHIFT), Input.is_key_pressed(KEY_E) etc.
			sprint = Input.is_action_pressed("sprint_p1")
			jump = Input.is_action_just_pressed("jump_p1")
			kick = Input.is_action_pressed("kick_p1")

		elif p_node.player_id == 2:
			if Input.is_action_pressed("p2_move_left"): input_dir.x -= 1
			if Input.is_action_pressed("p2_move_right"): input_dir.x += 1
			if Input.is_action_pressed("p2_move_forward"): input_dir.z -= 1
			if Input.is_action_pressed("p2_move_back"): input_dir.z += 1

			sprint = Input.is_action_pressed("p2_sprint")
			jump = Input.is_action_just_pressed("p2_jump")
			kick = Input.is_action_pressed("p2_kick")

		# Normalizar direção de movimento (apenas X e Z)
		var horizontal_input = Vector2(input_dir.x, input_dir.z)
		if horizontal_input.length_squared() > 0:
			horizontal_input = horizontal_input.normalized()
			input_dir.x = horizontal_input.x
			input_dir.z = horizontal_input.y # Lembre-se que o Z é invertido para o input

		# O componente Y do input_dir é usado pelo player_controller para o pulo
		# Não é parte da direção normalizada de movimento horizontal.
		# Ele é definido como 1 se jump for true, 0 caso contrário, dentro do player.set_input

		if p_node.has_method("set_input"):
			p_node.set_input(input_dir, sprint, jump, kick)


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

func _on_ball_goal_scored(goal_name: String):
	print("game-script.gd recebeu sinal de gol: ", goal_name)
	var team_scored_against = -1
	if "1" in goal_name: # Assumindo que o gol do time 1 se chama "Goal_Team1" ou similar
		team_scored_against = 1
		score_player2 += 1 # Time 2 marcou
		on_goal_scored_event(2) # Evento para time 2
	elif "2" in goal_name: # Assumindo que o gol do time 2 se chama "Goal_Team2" ou similar
		team_scored_against = 2
		score_player1 += 1 # Time 1 marcou
		on_goal_scored_event(1) # Evento para time 1
	else:
		print("Nome do gol não reconhecido: ", goal_name)
		return

	update_ui()

func on_goal_scored_event(team_that_scored: int):
	current_state = GameConstants.GameState.GOAL_SCORED
	print("Time %d marcou!" % team_that_scored)
	
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
