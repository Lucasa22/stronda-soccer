# Guia de Setup Rápido - Futebol 2v2 Arcade

## 1. Criar o Projeto no Godot

1. Abra o Godot 4.2+
2. Crie um novo projeto com o nome "Futebol 2v2 Arcade"
3. Escolha o renderer "Compatibility" para melhor performance

## 2. Estrutura de Pastas

Crie a seguinte estrutura de pastas no FileSystem:

```
res://
├── scenes/
│   ├── game/
│   ├── player/
│   ├── ball/
│   └── arena/
├── scripts/
│   └── globals/
└── assets/
    ├── sprites/
    ├── sounds/
    └── fonts/
```

## 3. Configurar o Projeto

1. Copie o conteúdo do `project.godot` fornecido
2. Vá em Project → Project Settings
3. Cole as configurações (ou configure manualmente os inputs e physics layers)

## 4. Criar o Script Global

1. Crie `GameConstants.gd` em `res://scripts/globals/`
2. Vá em Project → Project Settings → Autoload
3. Adicione GameConstants.gd (não precisa ser singleton, apenas para referência)

## 5. Criar as Cenas Principais

### Player.tscn
1. Crie uma nova cena com root `CharacterBody2D`
2. Adicione:
   - `Sprite2D` (use um placeholder ColorRect de 32x48 pixels, cor azul)
   - `CollisionShape2D` (RectangleShape2D de 32x48)
   - `Area2D` chamada "KickArea" com CollisionShape2D (CircleShape2D raio 40)
3. Anexe o script `Player.gd`
4. Salve como `res://scenes/player/Player.tscn`

### Ball.tscn
1. Crie uma nova cena com root `RigidBody2D`
2. Adicione:
   - `Sprite2D` (use um placeholder ColorRect de 24x24 pixels, cor branca)
   - `CollisionShape2D` (CircleShape2D raio 12)
   - `GPUParticles2D` chamada "Trail" (opcional, para efeito visual)
3. Anexe o script `Ball.gd`
4. Configure o RigidBody2D:
   - Lock Rotation: OFF
   - Continuous CD: ON
5. Salve como `res://scenes/ball/Ball.tscn`

### Arena.tscn
1. Crie uma nova cena com root `Node2D`
2. Anexe o script `ArenaBuilder.gd`
3. Salve como `res://scenes/arena/Arena.tscn`

### Game.tscn
1. Crie uma nova cena com root `Node2D`
2. Adicione:
   - Instance de `Arena.tscn`
   - Instance de `Player.tscn`
   - Instance de `Ball.tscn`
   - `Camera2D`
   - `CanvasLayer` chamada "UI" com um `Label` chamado "ScoreLabel"
3. Anexe o script `Game.gd`
4. Salve como `res://scenes/game/Game.tscn`

## 6. Configurar como Cena Principal

1. Vá em Project → Project Settings → Application → Run
2. Defina Main Scene como `res://scenes/game/Game.tscn`

## 7. Testar o Jogo

Pressione F5 ou clique em Play. Você deve poder:
- Mover com WASD
- Saltar com Espaço
- Chutar com E
- Sprint com Shift
- Resetar com Enter

## 8. Ajustes Rápidos de Física

Se o jogo parecer muito rápido/lento, ajuste em `GameConstants.gd`:
- `PLAYER_MOVE_SPEED`: Velocidade base do jogador
- `KICK_FORCE_MIN/MAX`: Força do chute
- `BALL_BOUNCE`: Quão quicante é a bola (0-1)
- `BALL_LINEAR_DAMP`: Fricção do ar na bola

## Próximos Passos

Com o Marco 1 completo, você pode:
1. Ajustar a física até ficar divertida
2. Adicionar sprites e animações reais
3. Implementar sons básicos
4. Prosseguir para o Marco 2 (multiplayer local)