# Plano de Testes Manuais - Stronda Soccer 3D

Este arquivo serve como um guia para os testes manuais das funcionalidades implementadas. Por favor, adicione seus feedbacks e observações aqui após cada sessão de teste.

## Fase Atual: IA Básica e Mecânicas de Drible

**Cena de Teste Principal:** `scenes/game/TrainingMode3D.tscn`

### 1. Configuração Inicial do Jogador IA (AIPlayer1)
*   [ ] **Verificar:** Abrir `TrainingMode3D.tscn`.
*   [ ] **Ação:** Selecionar o nó `Players/AIPlayer1`.
*   [ ] **Ação:** No Inspector, no script `Player 3d Controller`:
	*   [ ] Marcar `Is Ai Controlled`.
	*   [ ] Definir `Ai Goal To Defend Pos` para o centro do gol que a IA deve defender (ex: se o `GoalPlaceholder1` está em Z=-28, usar `(0, 0, -30)` ou similar. Se for o `GoalPlaceholder2` em Z=28, usar `(0,0,30)`).
	*   [ ] (Opcional) Mudar a cor do `AIPlayer1` para fácil distinção. Pode ser via `set_player_color` no `_ready` do script (adicionando uma condição para `is_ai_controlled`) ou alterando o material do `PlayerMesh` diretamente para esta instância.
*   **Feedback:**

### 2. Testes da IA Básica (AIPlayer1)
*   **Observar após configuração acima e ao executar a cena:**
*   [ ] **Posicionamento Defensivo:** O `AIPlayer1` tenta se posicionar entre a bola e o gol que você definiu para ele?
	*   **Feedback:**
*   [ ] **Aproximação da Bola:** Quando você (Player1) move a bola para perto do `AIPlayer1` (dentro do `ai_approach_ball_radius`, padrão 8 unidades), ele muda de comportamento e tenta se aproximar da bola?
	*   **Feedback:**
*   [ ] **Tentativa de Chute da IA:** Se a bola estiver muito perto do `AIPlayer1` (dentro do `ai_kick_ball_radius`, padrão 1.5 unidades), ele tenta realizar um chute na direção do gol oposto?
	*   **Feedback:**
*   [ ] **Movimentação Geral da IA:** A movimentação do `AIPlayer1` parece minimamente funcional? Ele não fica preso em paredes ou treme excessivamente?
	*   **Feedback:**
*   [ ] **Problemas Gerais da IA:** Algum erro no console relacionado à IA ou comportamento completamente inesperado?
	*   **Feedback:**

### 3. Testes de Movimentação do Jogador (Player1 - Humano)
*   [ ] **Responsividade:** Os comandos WASD para movimento são responsivos?
	*   **Feedback:**
*   [ ] **Aceleração/Desaceleração:** A sensação de aceleração ao iniciar o movimento e desaceleração ao parar é agradável? (Valores atuais: `acceleration = 60`, `deceleration = 80`).
	*   **Feedback:**
*   [ ] **Velocidade Máxima:** A `SPEED` (5.0) parece adequada?
	*   **Feedback:**
*   [ ] **Rotação:** A rotação do jogador ao mudar de direção (`turn_speed = 15.0`) é suave e responsiva?
	*   **Feedback:**
*   [ ] **Pulo:** O pulo (`JUMP_VELOCITY = 6.5`) tem altura e sensação adequadas?
	*   **Feedback:**

### 4. Testes da Física da Bola
*   [ ] **Peso Percebido:** A bola (`mass = 0.43`) parece ter um peso adequado em chutes e colisões?
	*   **Feedback:**
*   [ ] **Quique (Bounce):** O ricochete da bola no chão (`bounce = 0.65` no PhysicsMaterial) parece natural/divertido?
	*   **Feedback:**
*   [ ] **Atrito (Friction):** O atrito da bola com o campo (`friction = 0.35` no PhysicsMaterial) faz com que ela pare de rolar de forma realista?
	*   **Feedback:**
*   [ ] **Amortecimento (Damping):** A bola perde velocidade no ar (`linear_damp = 0.05` padrão, `air_resistance_factor = 0.015` em `_integrate_forces`) e rotação (`angular_damp = 0.1`) de forma apropriada?
	*   **Feedback:**
*   [ ] **Velocidade Máxima da Bola:** A `max_linear_velocity` (60.0) da bola parece um limite razoável para chutes fortes?
	*   **Feedback:**

### 5. Testes da Mecânica de Chute (Player1 - Humano)
*   [ ] **Carga do Chute:** Segurar 'F' carrega o chute? A força varia visivelmente com o tempo de carga?
	*   **Feedback:**
*   [ ] **Força Mín/Máx do Chute:** `min_kick_force` (7.0) e `max_kick_force` (18.0) estão bem balanceados? O `kick_hold_time_for_max_force` (0.6s) é um bom tempo?
	*   **Feedback:**
*   [ ] **Direção do Chute (Horizontal):** O chute vai na direção em que a câmera está apontando?
	*   **Feedback:**
*   [ ] **Elevação do Chute (Vertical):** O chute tem uma leve elevação padrão? Pressionar Shift+F (`aim_high`) resulta em um chute visivelmente mais alto? A variação de elevação com a carga do chute é boa?
	*   **Feedback:**
*   [ ] **Detecção da Bola para Chute:** A condição para o chute conectar (jogador virado para a bola) é intuitiva e não muito restritiva/permissiva?
	*   **Feedback:**

### 6. Testes das Mecânicas de Drible (Player1 - Humano)
*   [ ] **Condução da Bola (Stickiness):** Ao andar/correr lentamente, a bola permanece próxima aos pés de forma controlável? A `dribble_force_strength` (15.0) parece adequada?
	*   **Feedback:**
*   [ ] **Perda de Controle no Drible:** A bola se desgarra de forma realista ao virar bruscamente ou parar de repente?
	*   **Feedback:**
*   [ ] **Influência Lateral no Drible:** O input lateral (A/D enquanto move W/S) afeta o posicionamento da bola durante o drible (`dribble_side_offset_factor`)? É útil?
	*   **Feedback:**
*   [ ] **Velocidade Máxima de Drible:** A `dribble_max_speed` (4.0) é um bom limite para manter o controle?
	*   **Feedback:**
*   [ ] **Toque para Adiantar (Knock-on - Left Shift):** Adianta a bola de forma eficaz? A força (`knock_on_force_multiplier = 2.5`) e o cooldown (0.5s) são adequados?
	*   **Feedback:**
*   [ ] **Transição Drible-Chute:** É fácil chutar após um drible? Tocar 'F' enquanto dribla resulta em um toque/passe fraco?
	*   **Feedback:**
*   [ ] **Física da Bola no Drible:** A redução do damping da bola quando `is_being_dribbled` é ativado torna a bola mais responsiva? Ela volta ao normal quando o drible cessa?
	*   **Feedback:**

### 7. Testes da Câmera (GameCamera3D)
*   [ ] **Suavidade:** A câmera segue o jogador (Player1) suavemente? (`smoothness = 7.0`).
	*   **Feedback:**
*   [ ] **Offset e Ângulo:** O `offset` (0, 12, 9) e `look_at_offset` (0, 1.2, 0) fornecem uma boa visão do jogo?
	*   **Feedback:**
*   [ ] **Prevenção de Colisão da Câmera:** A câmera evita atravessar o campo ou os gols placeholders de forma eficaz? A `collision_push_margin` (0.3) é adequada?
	*   **Feedback:**

### 8. Testes do Modo de Treinamento (Funcionalidades)
*   [ ] **Reset da Bola:** Pressionar 'R' reseta a bola para o centro do campo?
	*   **Feedback:**
*   [ ] **Reset do Jogador:** Pressionar Shift+R reseta o jogador (Player1) para sua posição inicial?
	*   **Feedback:**
*   [ ] **Gols Placeholders:** Os gols estão visíveis e servem como referência?
	*   **Feedback:**
*   [ ] **Label Informativo:** O texto na UI está correto e visível?
	*   **Feedback:**

### 9. Feedback Sonoro (Requer adição manual dos arquivos de áudio)
*   [ ] **Som de Chute:** (Se áudio atribuído a `Player1/KickSound`) O som é reproduzido ao chutar?
	*   **Feedback:**
*   [ ] **Som de Colisão da Bola:** (Se áudio atribuído a `Ball/CollisionSound`) O som é reproduzido quando a bola colide? A variação de volume/pitch com a força do impacto é perceptível?
	*   **Feedback:**

### 10. Observações Gerais e Bugs
*   [ ] Anote quaisquer outros problemas, comportamentos inesperados, sugestões de melhoria ou erros no console.
	*   **Feedback:**

---
**Template para Feedback:**
**Data do Teste:** DD/MM/AAAA
**Versão/Commit Testado:** (Se aplicável)
**Testador:** Seu Nome/Apelido

**[Nome da Seção de Teste - ex: 2. Testes da IA Básica]**
*   **[Nome do Item de Teste - ex: Posicionamento Defensivo]**
	*   **Observações:** [O que você viu, como se comportou]
	*   **Problemas:** [Se houve algum problema]
	*   **Sugestões:** [Como poderia melhorar]
---
