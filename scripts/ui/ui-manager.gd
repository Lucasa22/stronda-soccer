extends CanvasLayer

# Script auxiliar para gerenciar a UI do jogo multiplayer

# Referências aos containers
@onready var hud := $HUD
@onready var menu := $Menu  
@onready var team_select := $TeamSelect
@onready var pause_menu := $PauseMenu
@onready var goal_notification := $GoalNotification
@onready var game_over_screen := $GameOverScreen

# HUD Elements
@onready var score_label := $HUD/ScoreLabel
@onready var time_label := $HUD/TimeLabel
@onready var player_indicators := $HUD/PlayerIndicators

# Cores dos times
const TEAM_COLORS = [Color.BLUE, Color.RED]

func _ready():
	# Configurar UI inicial
	setup_ui()
	
	# Esconder tudo exceto menu
	show_only_menu()

func setup_ui():
	# Estilo do Score
	if score_label:
		score_label.add_theme_font_size_override("font_size", 48)
		score_label.add_theme_color_override("font_color", Color.WHITE)
		score_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		score_label.position = Vector2(640, 30)
	
	# Estilo do Timer
	if time_label:
		time_label.add_theme_font_size_override("font_size", 32)
		time_label.position = Vector2(640, 80)
	
	# Configurar notificação de gol
	if goal_notification:
		goal_notification.visible = false
		goal_notification.position = Vector2(640, 360)
		var label = goal_notification.get_node_or_null("Label")
		if label:
			label.add_theme_font_size_override("font_size", 64)

func show_only_menu():
	menu.visible = true
	team_select.visible = false
	pause_menu.visible = false
	goal_notification.visible = false
	hud.visible = false
	if game_over_screen:
		game_over_screen.visible = false

func show_team_select():
	menu.visible = false
	team_select.visible = true

func show_hud():
	hud.visible = true
	menu.visible = false
	team_select.visible = false

func show_pause():
	pause_menu.visible = true

func hide_pause():
	pause_menu.visible = false

func update_score(team1: int, team2: int):
	if score_label:
		score_label.text = "%d - %d" % [team1, team2]
		
		# Animar mudança de placar
		var tween = create_tween()
		tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)

func update_time(seconds: float):
	if time_label:
		var minutes = int(seconds) / 60
		var secs = int(seconds) % 60
		time_label.text = "%02d:%02d" % [minutes, secs]
		
		# Piscar quando resta pouco tempo
		if seconds < 30 and int(seconds * 2) % 2 == 0:
			time_label.modulate = Color.RED
		else:
			time_label.modulate = Color.WHITE

func show_goal_animation(scoring_team: int, scorer_name: String = ""):
	if not goal_notification:
		return
		
	goal_notification.visible = true
	goal_notification.scale = Vector2(0.5, 0.5)
	goal_notification.modulate.a = 0.0
	
	# Texto do gol
	var label = goal_notification.get_node_or_null("Label")
	if label:
		var team_name = "AZUL" if scoring_team == 0 else "VERMELHO"
		label.text = "GOL DO TIME %s!" % team_name
		label.modulate = TEAM_COLORS[scoring_team]
	
	# Animação
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(goal_notification, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(goal_notification, "modulate:a", 1.0, 0.2)
	tween.chain()
	tween.tween_interval(1.5)
	tween.tween_property(goal_notification, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): goal_notification.visible = false)

func update_player_indicators(players: Array):
	if not player_indicators:
		return
		
	# Limpar indicadores existentes
	for child in player_indicators.get_children():
		child.queue_free()
	
	# Criar novo indicador para cada jogador
	var spacing = 150
	var start_x = 640 - (players.size() - 1) * spacing / 2
	
	for i in range(players.size()):
		var player = players[i]
		var indicator = create_player_indicator(player)
		player_indicators.add_child(indicator)
		indicator.position = Vector2(start_x + i * spacing, 680)

func create_player_indicator(player) -> Control:
	var container = HBoxContainer.new()
	
	# Ícone do jogador
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.color = player.player_color
	container.add_child(icon)
	
	# Nome do jogador
	var label = Label.new()
	label.text = " P%d" % (player.player_id + 1)
	label.modulate = player.player_color
	container.add_child(label)
	
	return container

func show_game_over(winner_team: int, final_score: Vector2):
	if not game_over_screen:
		# Criar tela de game over se não existir
		game_over_screen = Control.new()
		game_over_screen.name = "GameOverScreen"
		game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(game_over_screen)
		
		# Background escuro
		var bg = ColorRect.new()
		bg.color = Color(0, 0, 0, 0.8)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		game_over_screen.add_child(bg)
		
		# Container central
		var center = VBoxContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		center.alignment = BoxContainer.ALIGNMENT_CENTER
		game_over_screen.add_child(center)
		
		# Título
		var title = Label.new()
		title.name = "Title"
		title.add_theme_font_size_override("font_size", 64)
		center.add_child(title)
		
		# Placar final
		var score = Label.new()
		score.name = "FinalScore"
		score.add_theme_font_size_override("font_size", 48)
		center.add_child(score)
		
		# Instruções
		var instructions = Label.new()
		instructions.text = "\nPressione ENTER para continuar"
		instructions.add_theme_font_size_override("font_size", 24)
		instructions.modulate = Color(0.8, 0.8, 0.8)
		center.add_child(instructions)
	
	# Atualizar textos
	var title = game_over_screen.get_node("VBoxContainer/Title")
	var score = game_over_screen.get_node("VBoxContainer/FinalScore")
	
	if winner_team >= 0:
		title.text = "TIME %s VENCEU!" % ["AZUL", "VERMELHO"][winner_team]
		title.modulate = TEAM_COLORS[winner_team]
	else:
		title.text = "EMPATE!"
		title.modulate = Color.WHITE
	
	score.text = "%d - %d" % [int(final_score.x), int(final_score.y)]
	
	# Mostrar com animação
	game_over_screen.visible = true
	game_over_screen.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(game_over_screen, "modulate:a", 1.0, 0.5)

func hide_game_over():
	if game_over_screen:
		var tween = create_tween()
		tween.tween_property(game_over_screen, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): game_over_screen.visible = false)