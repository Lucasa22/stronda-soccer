class_name GameConstants
extends Resource

# Campo e Arena
const FIELD_WIDTH := 800.0
const FIELD_HEIGHT := 600.0
const GOAL_WIDTH := 120.0
const GOAL_HEIGHT := 20.0
const WALL_THICKNESS := 20.0

# Física do Jogador
const PLAYER_MOVE_SPEED := 200.0
const PLAYER_SPRINT_SPEED := 300.0
const PLAYER_JUMP_VELOCITY := -400.0
const PLAYER_AIR_CONTROL := 0.3
const PLAYER_FRICTION := 10.0
const PLAYER_SIZE := Vector2(30, 40)

# Física da Bola
const BALL_SIZE := 20
const BALL_MASS := 0.5
const BALL_GRAVITY_SCALE := 1.2
const BALL_LINEAR_DAMP := 0.5
const BALL_ANGULAR_DAMP := 1.0
const BALL_BOUNCE := 0.6
const BALL_FRICTION := 0.3

# Mecânicas de Chute
const KICK_FORCE_MIN := 300.0
const KICK_FORCE_MAX := 800.0
const KICK_UPWARD_MODIFIER := 0.3
const KICK_COOLDOWN := 0.2

# Física Geral
const GRAVITY := 980

# Camadas de colisão
const LAYER_PLAYERS := 1
const LAYER_BALL := 2
const LAYER_WALLS := 4
const LAYER_GOALS := 8

# Cores
const TEAM_1_COLOR := Color.BLUE
const TEAM_2_COLOR := Color.RED
const BALL_COLOR := Color.WHITE
const FIELD_COLOR := Color(0.2, 0.8, 0.2, 1.0)

# Estados
enum GameState { MENU, PLAYING, PAUSED, GOAL_SCORED }
enum PlayerState { IDLE, MOVING, JUMPING, KICKING }

# Camadas de Física
const LAYER_PLAYERS := 1
const LAYER_BALL := 2
const LAYER_WALLS := 4
const LAYER_GOALS := 8
