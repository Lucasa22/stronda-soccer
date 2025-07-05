extends Node2D

# Estados do jogo
enum GameState { MENU, TEAM_SELECT, PLAYING, PAUSED, GOAL_SCORED, GAME_OVER }
enum GameMode { VERSUS_1V1, VERSUS_2V2, COOP_2V2 }

var current_state := GameState.MENU
var current_mode := GameMode.VERSUS_1V1

# Pontuação e configurações
var score_team_1 := 0
var score_team_2 := 0
var max_score := 5
var match_time := 300.0 # 5 minutos
var time_remaining := 0.0

# Referências
@onready var arena := $Arena
@onready var ball := $Ball
@onready var camera := $Camera2D
@onready var ui := $UI
@onready var player_manager := $PlayerManager

# UI Elements
@onready var score_label := $UI/HUD/ScoreLabel
@onready var time_label := $UI/HUD/TimeLabel
@onready var goal_notification := $UI/GoalNotification
@onready var menu_container := $UI/Menu
@onready var team_select := $UI/TeamSelect
@onready var pause_menu := $UI/PauseMenu

# Players
var players := []

func _ready():
	# Configurar câmera
	setup_camera()
	
	# Iniciar no menu
	show_menu()
	
	# Conectar sinais
	if player_manager:
		player_manager.player_joined.connect(_on_player_joined)
		player_manager.player_left.connect(_on_player_left)

func _process(delta):
	match current_state:
		GameState.MENU:
			handle_menu_input()
		GameState.TEAM_SELECT:
			handle_team_select_input()
		GameState.PLAYING:
			update_match_time(delta)
			update_camera()
			handle_game_input()
		GameState.PAUSED:
			handle_pause_input()

func show_menu():
	current_state = GameState.MENU
	get_tree().paused = false
	
	if menu_container:
		menu_container.visible = true
		team_select.visible = false
		pause_menu.visible = false

func handle_menu_input():
	if Input.is_action_just_pressed("ui_accept"):
		# Detectar modo baseado em quantos controles estão ativos
		var keyboard_players = 2 # Sempre disponível
		var gamepad_count = Input.get_connected_joypads().size()
		
		if keyboard_players + gamepad_count >= 4:
			show_mode_selection()
		else:
			start_game(GameMode.VERSUS_1V1)

func show_mode_selection():
	current_state = GameState.TEAM_SELECT
	menu_container.visible = false
	team_select.visible = true
	
	# Mostrar opções de modo
	update_mode_display()

func handle_team_select_input():
	if Input.is_action_just_pressed("ui_up"):
		current_mode = wrap(current_mode - 1, 0, GameMode.size())
		update_mode_display()
	elif Input.is_action_just_pressed("ui_down"):
		current_mode = wrap(current_mode + 1, 0, GameMode.size())
		update_mode_display()
	elif Input.is_action_just_pressed("ui_accept"):
		start_game(current_mode)
	elif Input.is_action_just_pressed("ui_cancel"):
		show_menu()

func update_mode_display():
	# Atualizar UI com modo selecionado
	var mode_text = ""
	match current_mode:
		GameMode.VERSUS_1V1:
			mode_text = "1 vs 1"
		GameMode.VERSUS_2V2:
			mode_text = "2 vs 2"
		GameMode.COOP_2V2:
			mode_text = "2 vs AI"
	
	if team_select.has_node("ModeLabel"):
		team_select.get_node("ModeLabel").text = mode_text

func start_game(mode: GameMode):
	current_state = GameState.PLAYING
	current_mode = mode
	
	# Esconder menus
	menu_container.visible = false
	team_select.visible = false
	
	# Resetar jogo
	score_team_1 = 0
	score_team_2 = 0
	time_remaining = match_time
	
	# Criar jogadores baseado no modo
	spawn_players()
	
	# Resetar bola
	reset_ball()
	
	# Atualizar UI
	update_ui()

func spawn_players():
	# Limpar jogadores existentes
	for player in players:
		player.queue_free()
	players.clear()
	
	match current_mode:
		GameMode.VERSUS_1V1:
			# Player 1 (Teclado WASD) - Time 1
			var p1 = player_manager.add_player(0, 0)
			get_tree().current_scene.add_child(p1)
			p1.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.25, GameConstants.FIELD_HEIGHT * 0.5)
			players.append(p1)
			
			# Player 2 (Teclado Setas) - Time 2
			var p2 = player_manager.add_player(1, 1)
			get_tree().current_scene.add_child(p2)
			p2.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.75, GameConstants.FIELD_HEIGHT * 0.5)
			players.append(p2)
			
		GameMode.VERSUS_2V2:
			# Time 1
			var p1 = player_manager.add_player(0, 0)
			get_tree().current_scene.add_child(p1)
			p1.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.25, GameConstants.FIELD_HEIGHT * 0.35)
			players.append(p1)
			
			var p2 = player_manager.add_player(2, 0) # Gamepad 1
			get_tree().current_scene.add_child(p2)
			p2.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.25, GameConstants.FIELD_HEIGHT * 0.65)
			players.append(p2)
			
			# Time 2
			var p3 = player_manager.add_player(1, 1)
			get_tree().current_scene.add_child(p3)
			p3.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.75, GameConstants.FIELD_HEIGHT * 0.35)
			players.append(p3)
			
			var p4 = player_manager.add_player(3, 1) # Gamepad 2
			get_tree().current_scene.add_child(p4)
			p4.global_position = Vector2(GameConstants.FIELD_WIDTH * 0.75, GameConstants.FIELD_HEIGHT * 0.65)
			players.append(p4)
			
		GameMode.COOP_2V2:
			# Implementar depois com IA
			pass

func reset_ball():
	if ball:
		ball.reset_position()

func reset_positions():
	# Resetar jogadores para posições iniciais
	var positions = player_manager.get_spawn_positions(players.size())
	for i in range(players.size()):
		if i < positions.size():
			players[i].global_position = positions[i]
			players[i].velocity = Vector2.ZERO

func handle_game_input():
	# Pause
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
	
	# Reset rápido (debug)
	if Input.is_action_just_pressed("ui_text_submit"):
		reset_positions()
		reset_ball()

func toggle_pause():
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		pause_menu.visible = true
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		pause_menu.visible = false

func handle_pause_input():
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
	elif Input.is_action_just_pressed("ui_accept"):
		# Voltar ao menu
		get_tree().paused = false
		show_menu()

func update_match_time(delta):
	if time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			end_match()

func on_goal_scored(scoring_team: int):
	if current_state != GameState.PLAYING:
		return
	
	current_state = GameState.GOAL_SCORED
	
	# Atualizar pontuação
	if scoring_team == 0:
		score_team_1 += 1
	else:
		score_team_2 += 1
	
	# Mostrar notificação de gol
	show_goal_notification(scoring_team)
	
	# Celebração dos jogadores
	for player in players:
		if player.team == scoring_team:
			player.celebrate_goal()
	
	# Verificar fim de jogo
	if score_team_1 >= max_score or score_team_2 >= max_score:
		await get_tree().create_timer(3.0).timeout
		end_match()
	else:
		# Reset após delay
		await get_tree().create_timer(2.0).timeout
		reset_positions()
		reset_ball()
		current_state = GameState.PLAYING
	
	update_ui()

func show_goal_notification(team: int):
	if goal_notification:
		goal_notification.visible = true
		var team_name = "Time Azul" if team == 0 else "Time Vermelho"
		goal_notification.get_node("Label").text = "GOL DO %s!" % team_name
		goal_notification.modulate = PLAYER_COLORS[team * 2]
		
		# Animação
		var tween = create_tween()
		tween.tween_property(goal_notification, "scale", Vector2(1.5, 1.5), 0.5)
		tween.parallel().tween_property(goal_notification, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): goal_notification.visible = false)

func end_match():
	current_state = GameState.GAME_OVER
	
	# Mostrar resultado
	var winner = "Time Azul" if score_team_1 > score_team_2 else "Time Vermelho"
	if score_team_1 == score_team_2:
		winner = "Empate"
	
	# Mostrar tela de fim de jogo
	show_game_over(winner)

func show_game_over(winner: String):
	# Implementar tela de fim de jogo
	print("Fim de jogo! Vencedor: %s" % winner)
	
	# Voltar ao menu após delay
	await get_tree().create_timer(5.0).timeout
	show_menu()

func update_ui():
	# Pontuação
	if score_label:
		score_label.text = "%d - %d" % [score_team_1, score_team_2]
	
	# Tempo
	if time_label:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

func setup_camera():
	# Câmera isométrica fixa
	camera.position = Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2)
	camera.zoom = Vector2(1.0, 1.0)
	
	# Limites
	camera.limit_left = 0
	camera.limit_right = int(GameConstants.FIELD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = int(GameConstants.FIELD_HEIGHT)

func update_camera():
	# Pequeno movimento seguindo a bola
	if ball and camera:
		var target_pos = Vector2(GameConstants.FIELD_WIDTH / 2, GameConstants.FIELD_HEIGHT / 2)
		target_pos += (ball.global_position - target_pos) * 0.1
		camera.position = camera.position.lerp(target_pos, 0.05)

func _on_player_joined(player_id: int):
	print("Player %d joined!" % player_id)

func _on_player_left(player_id: int):
	print("Player %d left!" % player_id)

# Constantes de cores dos times
const PLAYER_COLORS := [
	Color(0.2, 0.2, 0.8), # Time 1 - Azul
	Color(0.8, 0.2, 0.2), # Time 2 - Vermelho
]
