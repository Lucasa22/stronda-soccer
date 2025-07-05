extends Node

# Gerenciador central de networking P2P

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded()
signal connection_failed()
signal server_created()

# Configurações de rede
const DEFAULT_PORT := 7000
const MAX_CLIENTS := 3

# Estado da rede
var peer: ENetMultiplayerPeer = null
var is_host := false
var connected_peers := {}
var local_player_info := {}

# Informações dos jogadores
var players_info := {}

func _ready():
	# Conectar sinais do multiplayer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT,