extends Node

# Sistema de áudio dinâmico com mixagem adaptativa

class_name AudioSystem

# Buses de áudio
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_AMBIENT := "Ambient"

# Pools de áudio
var sfx_players := []
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var crowd_player: AudioStreamPlayer

# Bibliotecas de sons
var sounds := {
	# Impactos de bola
	"ball_kick_soft": preload("res://assets/audio/ball_kick_soft.ogg"),
	"ball_kick_medium": preload("res://assets/audio/ball_kick_medium.ogg"),
	"ball_kick_hard": preload("res://assets/audio/ball_kick_hard.ogg"),
	"ball_bounce": preload("res://assets/audio/ball_bounce.ogg"),
	"ball_roll": preload("res://assets/audio/ball_roll.ogg"),
	
	# Jogador
	"footstep_grass": preload("res://assets/audio/footstep_grass.ogg"),
	"player_jump": preload("res://assets/audio/player_jump.ogg"),
	"player_land": preload("res://assets/audio/player_land.ogg"),
	"player_slide": preload("res://assets/audio/player_slide.ogg"),
	"player_collision": preload("res://assets/audio/player_collision.ogg"),
	
	# Gol e celebração
	"goal_net": preload("res://assets/audio/goal_net.ogg"),
	"goal_celebration": preload("res://assets/audio/goal_celebration.ogg"),
	"whistle_goal": preload("res://assets/audio/whistle_goal.ogg"),
	
	# UI
	"ui_select": preload("res://assets/audio/ui_select.ogg"),
	"ui_back": preload("res://assets/audio/ui_back.ogg"),
	"ui_start": preload("res://assets/audio/ui_start.ogg"),
	
	# Ambiente
	"crowd_idle": preload("res://assets/audio/crowd_idle.ogg"),
	"crowd_excitement": preload("res://assets/audio/crowd_excitement.ogg"),
	"crowd_goal": preload("res://assets/audio/crowd_goal.ogg")
}

# Estado do áudio
var crowd_excitement := 0.0
var music_intensity := 0.0

func _ready():
	# Criar buses de áudio se não existirem
	setup_audio_buses()
	
	# Criar pool de players
	create_sfx_pool(20)
	
	# Configurar música e ambiente
	setup_music_player()
	setup_ambient_players()

func setup_audio_buses():
	# Configurar volumes padrão
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), -6.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), -12.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), -9.0)

func create_sfx_pool(size: int):
	for i in range(size):
		var player = AudioStreamPlayer2D.new()
		player.bus = BUS_SFX
		player.max_distance = 1000.0
		player.attenuation = 2.0
		add_child(player)
		sfx_players.append(player)

func setup_music_player():
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	music_player.volume_db = -80.0 # Começar mudo para fade in
	add_child(music_player)

func setup_ambient_players():
	# Ambiente geral
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = BUS_AMBIENT
	add_child(ambient_player)
	
	# Som da torcida
	crowd_player = AudioStreamPlayer.new()
	crowd_player.bus = BUS_AMBIENT
	crowd_player.volume_db = -20.0
	add_child(crowd_player)
	
	if sounds.has("crowd_idle"):
		crowd_player.stream = sounds["crowd_idle"]
		crowd_player.play()

# Sistema principal de reprodução
func play_sound(sound_name: String, position: Vector2 = Vector2.ZERO, volume: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer2D:
	if not sounds.has(sound_name):
		push_warning("Som não encontrado: " + sound_name)
		return null
	
	var player = get_free_sfx_player()
	if not player:
		return null
	
	player.stream = sounds[sound_name]
	player.global_position = position
	player.volume_db = volume
	player.pitch_scale = pitch
	player.play()
	
	return player

func get_free_sfx_player() -> AudioStreamPlayer2D:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

# Sons específicos do jogo com variações
func play_kick_sound(force: float, position: Vector2):
	var sound_name = "ball_kick_soft"
	var pitch = 1.0
	var volume = 0.0
	
	# Selecionar som baseado na força
	if force > GameConstants.KICK_FORCE_MAX * 0.8:
		sound_name = "ball_kick_hard"
		pitch = randf_range(0.9, 1.1)
		volume = 3.0
	elif force > GameConstants.KICK_FORCE_MAX * 0.5:
		sound_name = "ball_kick_medium"
		pitch = randf_range(0.95, 1.05)
		volume = 0.0
	else:
		pitch = randf_range(1.0, 1.2)
		volume = -3.0
	
	play_sound(sound_name, position, volume, pitch)
	
	# Aumentar excitação da torcida
	increase_crowd_excitement(0.1)

func play_footstep(position: Vector2, velocity: float):
	if velocity < 50:
		return
		
	var volume = remap(velocity, 50, GameConstants.PLAYER_SPRINT_SPEED, -20, -5)
	var pitch = randf_range(0.9, 1.1)
	
	play_sound("footstep_grass", position, volume, pitch)

func play_ball_bounce(position: Vector2, impact_velocity: float):
	var volume = remap(impact_velocity, 0, 500, -15, 5)
	var pitch = remap(impact_velocity, 0, 500, 1.2, 0.8)
	
	play_sound("ball_bounce", position, volume, pitch)

func play_goal_sounds(scoring_team: int, goal_position: Vector2):
	# Som da rede
	play_sound("goal_net", goal_position, 5.0, randf_range(0.9, 1.1))
	
	# Apito do juiz
	await get_tree().create_timer(0.2).timeout
	play_sound("whistle_goal", goal_position, 10.0, 1.0)
	
	# Celebração
	await get_tree().create_timer(0.5).timeout
	play_sound("goal_celebration", Vector2.ZERO, 5.0, 1.0)
	
	# Torcida explode
	play_crowd_reaction("goal", 1.0)

# Sistema de torcida dinâmica
func update_crowd_excitement(delta: float, ball_position: Vector2, game_intensity: float):
	# Decaimento natural
	crowd_excitement = move_toward(crowd_excitement, 0.3, delta * 0.1)
	
	# Aumentar baseado em eventos
	crowd_excitement = clamp(crowd_excitement + game_intensity * delta * 0.2, 0.0, 1.0)
	
	# Ajustar volume da torcida
	if crowd_player:
		var target_volume = remap(crowd_excitement, 0.0, 1.0, -20.0, -5.0)
		crowd_player.volume_db = move_toward(crowd_player.volume_db, target_volume, delta * 10.0)

func increase_crowd_excitement(amount: float):
	crowd_excitement = clamp(crowd_excitement + amount, 0.0, 1.0)

func play_crowd_reaction(reaction_type: String, intensity: float = 1.0):
	match reaction_type:
		"goal":
			if sounds.has("crowd_goal"):
				var temp_player = AudioStreamPlayer.new()
				temp_player.bus = BUS_AMBIENT
				temp_player.stream = sounds["crowd_goal"]
				temp_player.volume_db = remap(intensity, 0.0, 1.0, -10.0, 5.0)
				add_child(temp_player)
				temp_player.play()
				temp_player.finished.connect(temp_player.queue_free)
				
		"excitement":
			if sounds.has("crowd_excitement"):
				crowd_player.stream = sounds["crowd_excitement"]
				crowd_player.play()

# Música dinâmica
func set_music_intensity(intensity: float, transition_time: float = 2.0):
	music_intensity = clamp(intensity, 0.0, 1.0)
	
	if music_player:
		var target_volume = remap(intensity, 0.0, 1.0, -20.0, 0.0)
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", target_volume, transition_time)

func play_music(stream: AudioStream, fade_in: float = 2.0):
	if not music_player:
		return
		
	if music_player.playing:
		# Fade out atual
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, 1.0)
		tween.tween_callback(func():
			music_player.stop()
			music_player.stream = stream
			music_player.play()
		)
		tween.tween_property(music_player, "volume_db", -12.0, fade_in)
	else:
		music_player.stream = stream
		music_player.play()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -12.0, fade_in)

# Efeitos especiais de áudio
func create_doppler_effect(source: Node2D, listener: Node2D, base_pitch: float = 1.0) -> float:
	if not source or not listener:
		return base_pitch
		
	var relative_velocity = source.velocity - listener.velocity if source.has_property("velocity") else Vector2.ZERO
	var to_listener = (listener.global_position - source.global_position).normalized()
	var doppler_shift = relative_velocity.dot(to_listener) / 1000.0 # Normalizar
	
	return base_pitch + doppler_shift * 0.2

func apply_reverb(player: AudioStreamPlayer2D, room_size: float):
	# Criar efeito de reverb
	var reverb = AudioEffectReverb.new()
	reverb.room_size = room_size
	reverb.damping = 0.5
	reverb.spread = 0.5
	reverb.dry = 0.7
	reverb.wet = 0.3
	
	# Aplicar ao bus do player
	var bus_idx = AudioServer.get_bus_index(player.bus)
	AudioServer.add_bus_effect(bus_idx, reverb)

# Sistema de feedback háptico (para gamepads)
func play_haptic_feedback(device: int, weak: float, strong: float, duration: float):
	Input.start_joy_vibration(device, weak, strong, duration)

func play_impact_haptic(device: int, strength: float):
	var weak = strength * 0.3
	var strong = strength * 0.7
	play_haptic_feedback(device, weak, strong, 0.1)

# Mixagem adaptativa baseada no estado do jogo
func update_audio_mix(game_state: String):
	match game_state:
		"menu":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), -12.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), -80.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), -6.0)
			
		"playing":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), -18.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), -9.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), -3.0)
			
		"goal_scored":
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), -25.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), -3.0)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), 0.0)
			
		"paused":
			# Aplicar lowpass filter
			var lowpass = AudioEffectLowPassFilter.new()
			lowpass.cutoff_hz = 500
			AudioServer.add_bus_effect(AudioServer.get_bus_index(BUS_MASTER), lowpass)