extends Node

# Campo e Arena
const FIELD_WIDTH := 800.0
const FIELD_HEIGHT := 600.0
const FIELD_DEPTH := 600.0  # Nova dimensão Z para 3D
const GOAL_WIDTH := 120.0
const GOAL_HEIGHT := 80.0  # Altura aumentada para 3D
const GOAL_DEPTH := 40.0   # Profundidade dos gols
const WALL_THICKNESS := 20.0

# Física do Jogador (3D)
const PLAYER_MOVE_SPEED := 200.0
const PLAYER_SPRINT_SPEED := 300.0
const PLAYER_JUMP_VELOCITY := -400.0
const PLAYER_AIR_CONTROL := 0.3
const PLAYER_FRICTION := 10.0
const PLAYER_SIZE_3D := Vector3(30, 40, 30)  # Tamanho 3D do jogador
const PLAYER_HEIGHT := 40.0  # Altura do jogador
const PLAYER_COLLISION_RADIUS := 15.0

# Física da Bola (3D)
const BALL_RADIUS := 10.0  # Raio da bola esférica
const BALL_MASS := 0.5
const BALL_GRAVITY_SCALE := 1.2
const BALL_LINEAR_DAMP := 0.5
const BALL_ANGULAR_DAMP := 1.0
const BALL_BOUNCE := 0.6
const BALL_FRICTION := 0.3
const BALL_MAX_SPEED := 500.0  # Velocidade máxima da bola

# Mecânicas de Chute (3D)
const KICK_FORCE_MIN := 300.0
const KICK_FORCE_MAX := 800.0
const KICK_UPWARD_MODIFIER := 0.3
const KICK_COOLDOWN := 0.2
const KICK_RANGE := 50.0  # Distância máxima para chutar

# Física Geral (3D)
const GRAVITY := 980.0  # Gravidade no eixo Y negativo
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

# Configurações da Câmera 3D
const CAMERA_HEIGHT := 300.0
const CAMERA_DISTANCE := 400.0
const CAMERA_ANGLE := -60.0
const CAMERA_FOV := 45.0
const CAMERA_FOLLOW_SPEED := 0.05

# Configurações de Iluminação
const SUN_ENERGY := 1.0
const AMBIENT_ENERGY := 0.3
const SHADOW_QUALITY := 2  # 0=Low, 1=Medium, 2=High
