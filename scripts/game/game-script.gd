extends Node2D

# Estados do jogo
enum GameState { MENU, PLAYING, PAUSED, GOAL_SCORED }
var current_state := GameState.PLAYING

# Pontuação
var score_player1 := 0
var score_player2 := 0

# Referências
@onready var arena := $Arena
@onready var player := $Player
@onready var ball := $Ball
@onready var camera := $Camera2D
@onready var ui := $UI

# Debug
var debug_mode := true

func _ready():
	# Configurar câmera
	setup_camera()
	
	# Inicializar posições
	reset_positions()
	
	# Debug info
	if debug_mode:
		create_debug_display()

func _process(delta):
	# Atualizar câmera
	update_camera()
	
	# Input global
	handle_global_input()
	
	# Atualizar UI
	update_ui()

func setup_camera():
	# Configurar câmera isométrica fixa
	camera.position = Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2)
	camera.zoom = Vector2(1.0, 1.0)
	
	# Limites da câmera
	camera.limit_left = 0
	camera.limit_right = int(GameConstants.FIELD_WIDTH)
	camera.limit_top = 0
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
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false

func on_goal_scored(team: int):
	current_state = GameState.GOAL_SCORED
	
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
	current_state = GameState.PLAYING

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

func _physics_process(delta):
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
