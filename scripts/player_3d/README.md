# 🎮⚽ PlayerAnimationController

Sistema de animação avançado para jogadores de futebol em Godot 4, criado com ginga brasileira!

## 🚀 O que é?

O **PlayerAnimationController** é um sistema completo de animação que traz vida aos jogadores do Stronda Soccer. Com 10 estados diferentes, transições suaves e animações contextuais, seu jogador vai ter movimentos dignos de craque!

## ✨ Features Principais

- 🎯 **10 Estados de Animação**: Idle, Running, Sprinting, Jumping, Falling, Landing, Kicking, Celebrating, Sliding, Turning
- 🌊 **Transições Suaves**: Blend automático entre animações
- ⚽ **Chutes Contextuais**: Diferentes animações para cada situação
- 🦘 **Sistema de Pulo**: Detecção automática de aéreo/pouso
- 🏃 **Sprint Inteligente**: Animação varia com velocidade
- 🎉 **Comemorações**: 3 tipos diferentes de celebração
- 📊 **Sistema de Prioridades**: Animações importantes não são interrompidas
- 🔄 **Animações Procedurais**: Inclinação e bounce naturais

## 📁 Arquivos do Sistema

```
scripts/player_3d/
├── player_animation_controller.gd     # Controlador principal
└── player_3d_controller_modular.gd    # Player integrado

docs/
├── player-animation-controller-guide.md    # Guia completo
└── animation-setup-quick-guide.md          # Setup rápido

tools/
└── create_placeholder_animations.gd        # Criador de animações
```

## 🎯 Quick Start

### 1. Adicionar à Cena
```
Player3D_Modular
├── PlayerModel
├── AnimationPlayer
├── PlayerAnimationController ← Adicione este nó!
└── ...
```

### 2. Configurar Script
- Selecione PlayerAnimationController
- Attach script: `scripts/player_3d/player_animation_controller.gd`

### 3. Criar Animações
Use o tool script para criar placeholders:
- Tools > Execute Script
- Selecione `tools/create_placeholder_animations.gd`

### 4. Testar
- Run a cena
- Use WASD + Shift + Space
- Veja as animações funcionando!

## 🎮 Controles

| Input | Ação | Animação |
|-------|------|----------|
| WASD | Movimento | idle → run → sprint |
| Shift + WASD | Sprint | sprint animation |
| Space | Chute | kick variants |
| Pulo (se physics) | Pular | jump → fall → land |

## 🛠️ API Rápida

```gdscript
# No seu player controller:
animation_controller.set_moving(true, velocity)
animation_controller.set_sprinting(is_sprinting)
animation_controller.trigger_kick(power)
animation_controller.trigger_celebration(type)
```

## 📊 Estados Disponíveis

| Estado | Quando Ativa | Animação |
|--------|--------------|----------|
| IDLE | Parado | idle |
| RUNNING | Velocidade > 0.5 | run |
| SPRINTING | Velocidade > 4.0 + sprint | sprint |
| JUMPING | No ar + velocidade Y > 0 | jump_start → jump_loop |
| FALLING | No ar + velocidade Y < 0 | fall_loop |
| LANDING | Acabou de pousar | landing_soft/hard |
| KICKING | Trigger de chute | kick variants |
| CELEBRATING | Trigger manual | celebration_* |
| SLIDING | Trigger manual | slide |
| TURNING | Rotação rápida | turn |
w
## 🎨 Customização

### Thresholds (Inspector)
- `run_speed_threshold`: 0.5 - Velocidade mínima para run
- `sprint_speed_threshold`: 4.0 - Velocidade mínima para sprint  
- `landing_impact_threshold`: 5.0 - Impacto para landing_hard
- `animation_blend_speed`: 10.0 - Velocidade de transição

### Animações Esperadas
**Essenciais:** idle, run, kick  
**Recomendadas:** sprint, jump_start, jump_loop, fall_loop, landing_soft  
**Avançadas:** kick_*, celebration_*, slide, turn, recovery

## 🐛 Debug

```gdscript
# Ver estado atual
print(animation_controller.get_current_state_name())

# Info completa
print(animation_controller.get_animation_debug_info())
```

## 🎯 Roadmap

- [ ] 🎵 Integração com sistema de áudio
- [ ] ✨ Efeitos de partícula automáticos  
- [ ] 🤖 IA com animações específicas
- [ ] 🎮 Animações de gamepad/touch
- [ ] 📱 Otimizações mobile

## 🏆 Resultado

Com este sistema, seus jogadores terão:

✅ Movimentos fluidos e naturais  
✅ Feedback visual rico  
✅ Transições cinematográficas  
✅ Sistema extensível  
✅ Performance otimizada  

## 🤝 Contribuição

Encontrou um bug? Quer uma feature nova? 
- Abra uma issue
- Faça um PR
- Mande sugestões!

---

**Feito com ❤️ e ⚽ pela equipe Stronda Soccer**  
*"Transformando código em gols desde 2024!"* 🇧🇷

## 📖 Links Úteis

- [Guia Completo](player-animation-controller-guide.md)
- [Setup Rápido](animation-setup-quick-guide.md)  
- [Godot Animation Docs](https://docs.godotengine.org/en/stable/tutorials/animation/)
