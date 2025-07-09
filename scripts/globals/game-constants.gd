extends Node

# Campo e Arena (valores em metros para 3D)
const FIELD_WIDTH := 40.0  # 40 metros de largura
const FIELD_HEIGHT := 25.0  # 25 metros de altura (Z)
const FIELD_DEPTH := 25.0  # 25 metros de profundidade
const GOAL_WIDTH := 7.32  # Largura oficial do gol FIFA
const GOAL_HEIGHT := 2.44  # Altura oficial do gol FIFA
const GOAL_DEPTH := 1.5   # Profundidade dos gols
const WALL_THICKNESS := 0.5

# Física do Jogador (3D) - valores realistas em metros
const PLAYER_MOVE_SPEED := 5.0  # 5 m/s velocidade normal
const PLAYER_SPRINT_SPEED := 8.0  # 8 m/s velocidade máxima
const PLAYER_JUMP_VELOCITY := 6.0  # 6 m/s para cima (positivo em Godot 4)
const PLAYER_AIR_CONTROL := 0.3
const PLAYER_FRICTION := 10.0
const PLAYER_SIZE_3D := Vector3(0.7, 1.75, 0.7)  # Tamanho realista do jogador
const PLAYER_HEIGHT := 1.75  # Altura do jogador em metros
const PLAYER_COLLISION_RADIUS := 0.35

# Física da Bola (3D) - valores realistas
const BALL_RADIUS := 0.11  # Raio oficial da bola de futebol (11cm)
const BALL_MASS := 0.45  # Massa oficial da bola de futebol FIFA
const BALL_GRAVITY_SCALE := 1.0
const BALL_LINEAR_DAMP := 0.1
const BALL_ANGULAR_DAMP := 0.1
const BALL_BOUNCE := 0.6
const BALL_FRICTION := 0.3
const BALL_MAX_SPEED := 30.0  # Velocidade máxima da bola em m/s

# Mecânicas de Chute (3D) - valores ajustados
const KICK_FORCE_MIN := 5.0  # Força mínima em m/s
const KICK_FORCE_MAX := 20.0  # Força máxima em m/s
const KICK_UPWARD_MODIFIER := 0.3
const KICK_COOLDOWN := 0.2
const KICK_RANGE := 1.5  # Distância máxima para chutar em metros

# Física Geral (3D) - valores realistas
const GRAVITY := 9.8  # Gravidade terrestre padrão
const GROUND_LEVEL := 0.0  # Nível do chão

# Camadas de colisão (3D)
const LAYER_PLAYERS := 1
const LAYER_BALL := 2
const LAYER_WALLS := 4
const LAYER_GOALS := 8
const LAYER_GROUND := 16
const LAYER_CEILING := 32

# Máscaras de colisão para facilitar uso
const MASK_PLAYER := LAYER_BALL | LAYER_WALLS | LAYER_GOALS | LAYER_GROUND
const MASK_BALL := LAYER_PLAYERS | LAYER_WALLS | LAYER_GOALS | LAYER_GROUND
const MASK_WALLS := LAYER_PLAYERS | LAYER_BALL

# Cores
const TEAM_1_COLOR := Color.BLUE
const TEAM_2_COLOR := Color.RED
const BALL_COLOR := Color.WHITE
const FIELD_COLOR := Color(0.2, 0.8, 0.2, 1.0)

# Estados
enum GameState { MENU, PLAYING, PAUSED, GOAL_SCORED }
enum PlayerState { IDLE, MOVING, JUMPING, KICKING }

# Configurações da Câmera 3D - valores ajustados
const CAMERA_HEIGHT := 8.0  # 8 metros de altura
const CAMERA_DISTANCE := 12.0  # 12 metros de distância
const CAMERA_ANGLE := -30.0  # Ângulo mais suave
const CAMERA_FOV := 60.0  # Campo de visão mais amplo
const CAMERA_FOLLOW_SPEED := 0.05

# Configurações de Iluminação
const SUN_ENERGY := 1.0
const AMBIENT_ENERGY := 0.3
const SHADOW_QUALITY := 2  # 0=Low, 1=Medium, 2=High
