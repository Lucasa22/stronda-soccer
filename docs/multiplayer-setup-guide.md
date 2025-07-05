# 🎮 Guia de Setup - Marco 2: Multiplayer Local

## 📋 Checklist de Implementação

### 1. Atualizar project.godot
- [ ] Adicione todos os novos inputs do arquivo `Inputs Multiplayer`
- [ ] Mantenha os inputs originais para compatibilidade

### 2. Criar PlayerManager
- [ ] Crie `PlayerManager.gd` em `res://scripts/`
- [ ] Adicione como Autoload: Project → Project Settings → Autoload
- [ ] Nome: PlayerManager, Path: res://scripts/PlayerManager.gd

### 3. Atualizar Player.tscn
- [ ] Faça backup do Player.gd original
- [ ] Substitua pelo novo `PlayerMultiplayer.gd`
- [ ] Adicione os novos nós filhos:
  - `Label` chamado "NameLabel" (posição Y: -60)
  - `Sprite2D` chamado "ArrowIndicator" (seta apontando para baixo)
  - `Sprite2D` chamado "Shadow" (círculo escuro, posição Y: 24)

### 4. Criar Nova Cena Game
- [ ] Duplique Game.tscn como GameMultiplayer.tscn
- [ ] Substitua o script por `GameMultiplayer.gd`
- [ ] Remova o Player único da cena (será spawnado dinamicamente)

### 5. Estrutura da UI
Adicione à CanvasLayer "UI":
```
UI/
├── HUD/
│   ├── ScoreLabel
│   ├── TimeLabel
│   └── PlayerIndicators
├── Menu/
│   ├── TitleLabel ("Futebol 2v2 Arcade")
│   ├── PlayButton
│   └── InstructionsLabel
├── TeamSelect/
│   ├── ModeLabel
│   └── InstructionsLabel ("↑↓ Mudar Modo, Enter Confirmar")
├── PauseMenu/
│   ├── PausedLabel
│   └── ResumeButton
└── GoalNotification/
    └── Label
```

### 6. Testar Controles

#### Controles Player 1 (WASD):
- **Movimento**: W, A, S, D
- **Salto**: Espaço
- **Chute**: E
- **Sprint**: Shift

#### Controles Player 2 (Setas):
- **Movimento**: ↑, ←, ↓, →
- **Salto**: Enter (numpad)
- **Chute**: Shift Direito
- **Sprint**: Ctrl Direito

#### Controles Gamepad:
- **Movimento**: Analógico Esquerdo
- **Salto**: A/X (PlayStation)
- **Chute**: X/□ (PlayStation)
- **Sprint**: R1/RB

## 🔧 Ajustes Rápidos

### Cores dos Times
Em `PlayerManager.gd`, ajuste PLAYER_COLORS:
```gdscript
const PLAYER_COLORS := [
    Color(0.2, 0.2, 0.8), # Azul
    Color(0.8, 0.2, 0.2), # Vermelho
    Color(0.2, 0.8, 0.2), # Verde
    Color(0.8, 0.8, 0.2)  # Amarelo
]
```

### Configurações de Partida
Em `GameMultiplayer.gd`:
```gdscript
var max_score := 5        # Gols para vencer
var match_time := 300.0   # Tempo em segundos
```

### Posições de Spawn
Em `PlayerManager.gd`, função `get_spawn_positions()`

## 🎯 Fluxo do Jogo

1. **Menu Principal** → Detecta controles disponíveis
2. **Seleção de Modo** (se 3+ controles detectados):
   - 1v1: 2 jogadores
   - 2v2: 4 jogadores
   - 2vAI: 2 jogadores vs 2 IAs (futuro)
3. **Partida** com HUD mostrando:
   - Placar
   - Tempo restante
   - Indicadores de jogador
4. **Pause** (ESC) durante a partida
5. **Fim de Jogo** quando:
   - Um time atinge max_score
   - Tempo acaba

## 🐛 Troubleshooting

### "Controle não responde"
- Verifique se o gamepad está conectado antes de iniciar o Godot
- Teste em Input Map (Project Settings → Input Map)

### "Jogadores se sobrepõem"
- Ajuste as posições de spawn em `get_spawn_positions()`
- Aumente a collision layer dos jogadores

### "Lag com 4 jogadores"
- Desative sombras ou partículas temporariamente
- Reduza a resolução do viewport

## ✅ Critérios de Sucesso - Marco 2

- [ ] 2 jogadores podem jogar com teclado (WASD vs Setas)
- [ ] Suporte para até 4 jogadores (2 teclado + 2 gamepad)
- [ ] Sistema de pontuação funcionando
- [ ] UI mostra placar e tempo
- [ ] Menu de seleção de modo
- [ ] Pause funcional
- [ ] Jogadores têm cores distintas
- [ ] Celebração de gol
- [ ] Reset correto após gols

## 🚀 Próximos Passos

Com o Marco 2 completo:
1. **Teste extensivamente** com amigos
2. **Ajuste o game feel** baseado no feedback
3. **Prossiga para Marco 3** (Networking P2P)

### Dicas para Testes
- Organize uma "sessão de playtest" com amigos
- Anote o que é divertido e o que frustra
- Ajuste física e velocidades conforme necessário
- O jogo deve ser divertido ANTES de adicionar rede!