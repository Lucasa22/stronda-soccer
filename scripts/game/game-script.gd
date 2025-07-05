extends Node2D

# Importa as constantes do jogo
const GameConstants = preload("res://scripts/globals/game-constants.gd")

# Cena simples para testar o jogo
@onready var arena := $Arena
@onready var players := $Players
@onready var ball := $Ball
@onready var ui := $UI
@onready var camera := $Camera2D

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
	
	# Criar campo visual
	create_field()
	
	# Criar jogadores
	create_players()
	
	# Criar bola
	create_ball()
	
	# Criar UI básica
	create_ui()

func setup_camera():
	camera.position = Vector2(field_width / 2, field_height / 2)
	camera.zoom = Vector2(0.8, 0.8)

func create_field():
	# Criar fundo do campo
	var field_bg = ColorRect.new()
	field_bg.color = Color(0.2, 0.8, 0.2, 1.0)  # Verde
	field_bg.size = Vector2(field_width, field_height)
	field_bg.position = Vector2(0, 0)
	arena.add_child(field_bg)
	
	# Linha central
	var center_line = ColorRect.new()
	center_line.color = Color.WHITE
	center_line.size = Vector2(4, field_height)
	center_line.position = Vector2(field_width / 2 - 2, 0)
	arena.add_child(center_line)
	
	# Círculo central
	var center_circle = create_circle(Vector2(field_width / 2, field_height / 2), 50, Color.WHITE)
	arena.add_child(center_circle)
	
	# Gols
	create_goals()

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
	
	# Gol esquerdo
	var left_goal = ColorRect.new()
	left_goal.color = Color.YELLOW
	left_goal.size = Vector2(goal_width, goal_height)
	left_goal.position = Vector2(-goal_width, field_height / 2 - goal_height / 2)
	arena.add_child(left_goal)
	
	# Gol direito
	var right_goal = ColorRect.new()
	right_goal.color = Color.YELLOW
	right_goal.size = Vector2(goal_width, goal_height)
	right_goal.position = Vector2(field_width, field_height / 2 - goal_height / 2)
	arena.add_child(right_goal)

func create_players():
	# Jogador 1 (Azul)
	var player1 = create_player(Vector2(field_width / 4, field_height / 2), Color.BLUE, "P1")
	players.add_child(player1)
	
	# Jogador 2 (Vermelho)
	var player2 = create_player(Vector2(3 * field_width / 4, field_height / 2), Color.RED, "P2")
	players.add_child(player2)

func create_player(pos: Vector2, color: Color, player_name: String) -> Node2D:
	var player_node = Node2D.new()
	player_node.position = pos
	
	# Sprite do jogador
	var sprite = ColorRect.new()
	sprite.color = color
	sprite.size = Vector2(30, 40)
	sprite.position = Vector2(-15, -20)
	player_node.add_child(sprite)
	
	# Nome do jogador
	var label = Label.new()
	label.text = player_name
	label.position = Vector2(-10, -35)
	label.add_theme_color_override("font_color", Color.WHITE)
	player_node.add_child(label)
	
	return player_node

func create_ball():
	var ball_sprite = ColorRect.new()
	ball_sprite.color = Color.WHITE
	ball_sprite.size = Vector2(20, 20)
	ball_sprite.position = Vector2(field_width / 2 - 10, field_height / 2 - 10)
	ball.add_child(ball_sprite)

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
	if ball:
		var target_pos = Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2)
		target_pos += (ball.global_position - target_pos) * 0.1
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
		player.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.3, GameConstants.FIELD_HEIGHT / 2)
		player.velocity = Vector2.ZERO
	
	# Resetar bola
	if ball:
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
	# Placeholder para celebração de gol
	var label = Label.new()
	label.text = "GOOOOOL!"
	label.add_theme_font_size_override("font_size", 64)
	label.modulate = Color(1, 1, 0)
	label.position = Vector2(GameConstants.FIELD_WIDTH / 2 - 100, GameConstants.FIELD_HEIGHT / 2)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(2, 2), 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

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
