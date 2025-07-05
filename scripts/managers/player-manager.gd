extends Node

# Gerencia múltiplos jogadores locais e seus inputs

signal player_joined(player_id: int)
signal player_left(player_id: int)

# Configurações de jogadores
const MAX_PLAYERS := 4
const PLAYER_COLORS := [
	Color(0.2, 0.2, 0.8), # Azul
	Color(0.8, 0.2, 0.2), # Vermelho
	Color(0.2, 0.8, 0.2), # Verde
	Color(0.8, 0.8, 0.2)  # Amarelo
]

# Mapeamento de controles
var player_inputs := {
	0: { # Player 1 - Teclado WASD
		"move_left": "p1_move_left",
		"move_right": "p1_move_right", 
		"move_up": "p1_move_up",
		"move_down": "p1_move_down",
		"jump": "p1_jump",
		"kick": "p1_kick",
		"sprint": "p1_sprint"
	},
	1: { # Player 2 - Teclado Setas
		"move_left": "p2_move_left",
		"move_right": "p2_move_right",
		"move_up": "p2_move_up", 
		"move_down": "p2_move_down",
		"jump": "p2_jump",
		"kick": "p2_kick",
		"sprint": "p2_sprint"
	},
	2: { # Player 3 - Gamepad 1
		"device": 0,
		"move_left": "gamepad_move_left",
		"move_right": "gamepad_move_right",
		"move_up": "gamepad_move_up",
		"move_down": "gamepad_move_down", 
		"jump": "gamepad_jump",
		"kick": "gamepad_kick",
		"sprint": "gamepad_sprint"
	},
	3: { # Player 4 - Gamepad 2
		"device": 1,
		"move_left": "gamepad_move_left",
		"move_right": "gamepad_move_right",
		"move_up": "gamepad_move_up",
		"move_down": "gamepad_move_down",
		"jump": "gamepad_jump", 
		"kick": "gamepad_kick",
		"sprint": "gamepad_sprint"
	}
}

# Jogadores ativos
var active_players := {}
var player_scene := preload("res://scenes/player/Player.tscn")

func _ready():
	# Detectar gamepads
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func add_player(player_id: int, team: int = 0) -> Node:
	if player_id in active_players:
		return active_players[player_id]
	
	if player_id >= MAX_PLAYERS:
		return null
	
	# Instanciar jogador
	var player = player_scene.instantiate()
	player.name = "Player%d" % (player_id + 1)
	player.player_id = player_id
	player.team = team
	player.player_color = PLAYER_COLORS[player_id]
	
	# Configurar inputs
	if player_id in player_inputs:
		player.input_map = player_inputs[player_id]
	
	active_players[player_id] = player
	player_joined.emit(player_id)
	
	return player

func remove_player(player_id: int):
	if player_id in active_players:
		active_players[player_id].queue_free()
		active_players.erase(player_id)
		player_left.emit(player_id)

func get_player(player_id: int) -> Node:
	return active_players.get(player_id)

func get_all_players() -> Array:
	return active_players.values()

func get_team_players(team: int) -> Array:
	var team_players = []
	for player in active_players.values():
		if player.team == team:
			team_players.append(player)
	return team_players

func _on_joy_connection_changed(device: int, connected: bool):
	print("Gamepad %d %s" % [device, "connected" if connected else "disconnected"])

# Spawn positions baseadas no número de jogadores
func get_spawn_positions(team_count: int) -> Array:
	var positions = []
	
	match team_count:
		2: # 1v1
			positions = [
				Vector2(GameConstants.FIELD_WIDTH * 0.25, GameConstants.FIELD_HEIGHT * 0.5),
				Vector2(GameConstants.FIELD_WIDTH * 0.75, GameConstants.FIELD_HEIGHT * 0.5)
			]
		4: # 2v2
			positions = [
				Vector2(GameConstants.FIELD_WIDTH * 0.25, GameConstants.FIELD_HEIGHT * 0.35),
				Vector2(GameConstants.FIELD_WIDTH * 0.25, GameConstants.FIELD_HEIGHT * 0.65),
				Vector2(GameConstants.FIELD_WIDTH * 0.75, GameConstants.FIELD_HEIGHT * 0.35),
				Vector2(GameConstants.FIELD_WIDTH * 0.75, GameConstants.FIELD_HEIGHT * 0.65)
			]
	
	return positions
