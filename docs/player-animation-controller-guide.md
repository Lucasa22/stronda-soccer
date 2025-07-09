# PlayerAnimationController - Sistema de Animação Avançado

E aí, meu craque! 🎮⚽ Aqui está o guia completo do **PlayerAnimationController** que vai deixar seu jogador com movimentos dignos de Ronaldinho Gaúcho!

## 🌟 Principais Features

### 1. **Sistema de Estados**
- **10 estados de animação**: Idle, Running, Sprinting, Jumping, Falling, Landing, Kicking, Celebrating, Sliding e Turning
- Transições suaves entre estados com blend automático
- Sistema de prioridades para animações importantes

### 2. **Animações Contextuais**
- **Chute variado**: Animações diferentes para chute parado, correndo, no ar ou power shot
- **Pouso dinâmico**: Animação suave ou pesada dependendo do impacto
- **Velocidade adaptativa**: A velocidade da animação de corrida se ajusta à velocidade real do jogador

### 3. **Sistema de Blend**
- Mistura suave entre animações (ex: idle → run)
- Pesos de blend configuráveis
- Suporte automático para AnimationTree

### 4. **Animações Procedurais**
- **Inclinação lateral**: O jogador inclina ao fazer curvas
- **Bounce sutil**: Movimento vertical natural durante a corrida

### 5. **Sistema de Prioridades**
- Fila de animações com duração específica
- Garante que animações importantes não sejam cortadas

## 🎯 Como Integrar ao Projeto

### 1. **Estrutura de Nós**
Adicione o `PlayerAnimationController` como filho do seu Player3D:

```
Player3D_Modular
├── PlayerModel (Node3D)
├── AnimationPlayer
├── PlayerAnimationController (Node3D com script)
└── ... outros nós
```

### 2. **Configuração das Animações**
O sistema espera as seguintes animações no AnimationPlayer:

#### Animações Básicas:
- `idle` - Jogador parado
- `run` - Corrida normal
- `sprint` - Corrida em alta velocidade

#### Animações de Pulo:
- `jump_start` - Início do pulo
- `jump_loop` - No ar (loop)
- `fall_loop` - Caindo (loop)
- `landing_soft` - Pouso suave
- `landing_hard` - Pouso pesado
- `recovery` - Recuperação após impacto

#### Animações de Chute:
- `kick` - Chute básico (parado)
- `kick_running` - Chute em movimento
- `kick_air` - Chute no ar
- `kick_power` - Chute de força

#### Animações Especiais:
- `celebration_fist_pump` - Comemoração 1
- `celebration_slide` - Comemoração 2
- `celebration_backflip` - Comemoração 3
- `slide` - Deslizamento
- `turn` - Virada rápida

### 3. **Configuração no Inspector**
Ajuste estes valores no PlayerAnimationController:

- `run_speed_threshold`: 0.5 (velocidade mínima para corrida)
- `sprint_speed_threshold`: 4.0 (velocidade mínima para sprint)
- `turn_speed_threshold`: 2.0 (velocidade de rotação para virada)
- `landing_impact_threshold`: 5.0 (impacto mínimo para pouso pesado)
- `animation_blend_speed`: 10.0 (velocidade de transição)

## 🎮 API do Sistema

### Métodos Principais:
```gdscript
# Movimento básico
animation_controller.set_moving(true, velocity)
animation_controller.set_sprinting(Input.is_action_pressed("sprint"))

# Triggers especiais
animation_controller.trigger_kick(kick_power)  # 0.0 a 1.0
animation_controller.trigger_celebration(0)   # 0, 1 ou 2
animation_controller.trigger_slide()

# Debug
print(animation_controller.get_current_state_name())
print(animation_controller.get_animation_debug_info())
```

### Estados Disponíveis:
- `IDLE` - Parado
- `RUNNING` - Correndo
- `SPRINTING` - Correndo rápido
- `JUMPING` - Pulando
- `FALLING` - Caindo
- `LANDING` - Pousando
- `KICKING` - Chutando
- `CELEBRATING` - Comemorando
- `SLIDING` - Deslizando
- `TURNING` - Virando

## ⚙️ Integração Automática

O sistema já está integrado ao `Player3D_Modular`:

1. **Movimento**: Detecta automaticamente velocidade e direção
2. **Sprint**: Detecta input de sprint (tecla configurada)
3. **Chute**: Integrado ao sistema de chute existente
4. **Pulo**: Detecta quando o jogador está no ar
5. **Pouso**: Calcula impacto baseado na velocidade de queda

## 🔧 Próximos Passos

### 1. Criar Animações
Use o AnimationPlayer do Godot para criar as animações necessárias:
- Pode usar animações simples com keyframes
- Para resultados profissionais, importe de software 3D (Blender, etc.)

### 2. Configurar Input Map
Certifique-se que está configurado:
- `move_left`, `move_right`, `move_forward`, `move_backward`
- `sprint` (ex: Shift)
- `kick` (ex: Espaço)

### 3. Adicionar Efeitos Visuais
- Partículas de poeira ao correr
- Efeitos de impacto no pouso
- Rastro de movimento no sprint

### 4. Som
- Sons de passos variados por velocidade
- Sons de chute diferentes por força
- Sons de pouso por impacto

## 🎨 Customização Avançada

### AnimationTree (Opcional)
Para blends mais complexos, o sistema cria automaticamente um AnimationTree. Você pode customizar:

```gdscript
# Acessar o AnimationTree criado automaticamente
var anim_tree = animation_controller.animation_tree
```

### Animações Procedurais
O sistema inclui:
- **Inclinação lateral**: Durante curvas
- **Bounce vertical**: Durante corrida

Customize no código se necessário.

### Sistema de Prioridades
Animações importantes (como chute) têm prioridade sobre outras:

```gdscript
# Exemplo interno - o sistema cuida disso automaticamente
_add_to_priority_queue({
    "animation": "kick_power",
    "duration": 0.8,
    "elapsed": 0.0
})
```

## 🐛 Troubleshooting

### Problema: "Animation não encontrada"
- Verifique se a animação existe no AnimationPlayer
- Nome deve corresponder exatamente (case-sensitive)

### Problema: Transições bruscas
- Aumente `animation_blend_speed`
- Verifique se AnimationPlayer tem blend configurado

### Problema: Estados não mudam
- Verifique os thresholds de velocidade
- Debug com `get_animation_debug_info()`

### Problema: Performance
- Reduza frequency do `_physics_process` se necessário
- Otimize animações procedurais

## 🏆 Resultado Final

Com este sistema, seu jogador terá:
- ✅ Movimentos fluidos e naturais
- ✅ Animações contextuais inteligentes
- ✅ Transições suaves entre estados
- ✅ Feedback visual rico
- ✅ Sistema extensível para mais animações

Agora é só criar as animações e ver seu jogador ganhando vida! ⚽🎮

---

*Criado por Stronda Soccer Team - Fazendo jogos de futebol com ginga brasileira! 🇧🇷*
