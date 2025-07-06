# Plano de Melhorias Stronda Soccer

Este arquivo documenta o plano de desenvolvimento e melhorias para o jogo Stronda Soccer, gerenciado por agentes de IA. Ele será atualizado continuamente à medida que as tarefas forem concluídas e novas metas forem definidas.

## Objetivos Gerais

Melhorar os seguintes aspectos do jogo:
- Movimentação dos jogadores
- Física do jogo
- Gameplay geral
- Mecânica de chutes
- Implementação de sistema de faltas
- Gerenciamento do tempo de jogo
- Criação e manutenção de testes automatizados

## Plano Detalhado

### 1. Movimentação dos Jogadores
- **Análise Atual:** O `README.md` indica "Sistema básico de movimento" como concluído. Os scripts relevantes parecem ser `scripts/player/enhanced-player-controller-v2.gd` e `scripts/player/player-script.gd`. O `docs/setup-guide.md` também menciona o `Player.tscn` e `Player.gd`.
- **Melhorias Propostas:**
    - Investigar a responsividade dos controles (teclado e gamepad).
    - Avaliar a implementação de diferentes tipos de movimento (ex: dribles, movimentos laterais mais fluidos).
    - Considerar a física do jogador ao correr, parar e mudar de direção.
    - Melhorar a IA de movimentação para jogadores não controlados (relacionado ao item "IA dos jogadores" pendente no `README.md`).
- **Arquivos Potenciais:** `scripts/player/`, `scenes/player/Player.tscn`.

### 2. Física
- **Análise Atual:** "Física Avançada" é uma característica e "Física da bola" está concluída (`README.md`). `docs/setup-guide.md` menciona `GameConstants.gd` para ajustes de física da bola (`BALL_BOUNCE`, `BALL_LINEAR_DAMP`). Scripts em `scripts/physics/` (`advanced-physics-controller.gd`, `ball-script.gd`) são relevantes. O guia de migração 3D discute física 3D, mas o projeto atual é 2.5D, então manteremos o foco na física 2D/2.5D.
- **Melhorias Propostas:**
    - Revisar e ajustar os parâmetros de física da bola para um comportamento mais realista e satisfatório (peso, quique, atrito com o campo e jogadores).
    - Avaliar a interação física entre jogadores (colisões, disputas de bola).
    - Investigar a física de redes e traves.
- **Arquivos Potenciais:** `scripts/physics/`, `scripts/globals/game-constants.gd`, `scenes/ball/Ball.tscn`.

### 3. Gameplay
- **Análise Atual:** O `README.md` tem um roadmap com "IA dos jogadores", "Sistema de times", "Efeitos visuais avançados", "Sistema de torneios" como pendentes. `docs/multiplayer-setup-guide.md` detalha o fluxo do jogo multiplayer local.
- **Melhorias Propostas:**
    - **IA dos Jogadores:**
        - Implementar comportamento básico para jogadores controlados pela IA (posicionamento defensivo e ofensivo, tentativa de passe/chute).
        - Desenvolver diferentes níveis de dificuldade para a IA.
    - **Sistema de Times:**
        - Permitir a formação de times (além das cores básicas definidas em `PlayerManager.gd`).
        - Implementar táticas de time simples.
    - **Efeitos Visuais:**
        - Adicionar/melhorar efeitos de chute, corrida, colisões.
        - Melhorar a interface do usuário (UI) e notificações (ex: gol, início/fim de partida).
    - **Sistema de Torneios/Ligas:** (Pode ser um objetivo de longo prazo)
        - Planejar a estrutura para modos de jogo mais longos.
- **Arquivos Potenciais:** `scripts/game/`, `scripts/player/`, `scripts/managers/`, `scenes/ui/`.

### 4. Chutes
- **Análise Atual:** "Sistema de chutes" está concluído (`README.md`). `docs/setup-guide.md` aponta para `KICK_FORCE_MIN/MAX` em `GameConstants.gd`. A `KickArea` está definida em `Player.tscn`.
- **Melhorias Propostas:**
    - Implementar diferentes tipos de chute (ex: chute colocado, chute forte, cobertura).
    - Adicionar a capacidade de controlar a direção e a elevação do chute com mais precisão.
    - Melhorar o feedback visual e sonoro dos chutes.
    - Investigar a física do chute em relação à posição do jogador e da bola.
- **Arquivos Potenciais:** `scripts/player/`, `scripts/ball/`, `scripts/globals/game-constants.gd`.

### 5. Faltas
- **Análise Atual:** Não há menção a um sistema de faltas nos documentos.
- **Melhorias Propostas:**
    - **Definição:** Determinar o que constitui uma falta (carrinhos por trás, colisões muito fortes sem disputa de bola).
    - **Detecção:** Implementar a lógica para detectar faltas.
    - **Consequências:** Definir as consequências das faltas (tiro livre, pênalti, cartões - escopo a definir).
    - **IA e Faltas:** Ensinar a IA a cometer e evitar faltas.
- **Arquivos Potenciais:** Novos scripts para sistema de faltas, modificações em `scripts/player/` e `scripts/physics/`.

### 6. Tempo de Jogo
- **Análise Atual:** `docs/multiplayer-setup-guide.md` menciona `match_time` em `GameMultiplayer.gd`.
- **Melhorias Propostas:**
    - Revisar a lógica de contagem e exibição do tempo.
    - Considerar opções de configuração de tempo de partida (ex: permitir que os jogadores escolham a duração).
    - Implementar lógica para acréscimos (se desejado).
    - Pausar o cronômetro em interrupções (ex: gol, falta).
- **Arquivos Potenciais:** `scripts/game/game-multiplayer.gd`, `scripts/ui/ui-manager.gd`.

### 7. Testes
- **Análise Atual:** Não há estrutura de testes automatizados mencionada.
- **Melhorias Propostas:**
    - **Configuração do Framework:** Escolher e configurar um framework de testes para Godot (ex: GUT - Godot Unit Test).
    - **Testes Unitários:**
        - Criar testes para funções críticas em `scripts/physics/`, `scripts/player/`, `scripts/ball/`.
        - Testar a lógica de `GameConstants.gd`.
    - **Testes de Integração:**
        - Testar interações entre jogador e bola.
        - Testar o sistema de pontuação e tempo.
    - **Testes de Gameplay (se possível):**
        - Definir cenários de gameplay para verificar o comportamento esperado (pode ser mais manual ou com scripts de automação de cena).
- **Arquivos Potenciais:** Nova pasta `tests/` com subdiretórios para unit, integration, etc.

### 8. Migração para 3D (Nova Solicitação)
- **Análise Atual:** O projeto é atualmente 2.5D. O arquivo `docs/3d-migration-guide.md` detalha os desafios e desvantagens de uma migração completa para 3D, recomendando 2.5D ou 3D simplificado.
- **Considerações:**
    - **Complexidade:** A migração para 3D aumentará significativamente a complexidade do projeto (Nodes 3D, física 3D, controles 3D, câmera 3D, assets 3D).
    - **Assets:** Necessidade de modelos 3D para jogadores, bola, campo, gols, etc.
    - **Tempo:** A migração consumirá um tempo considerável de desenvolvimento, potencialmente adiando outras funcionalidades.
    - **Escopo do `docs/3d-migration-guide.md`:** O guia alerta sobre o aumento de complexidade e tempo, sugerindo que pode "atrasar o projeto em meses".
- **Passos Potenciais (Alto Nível):**
    - Converter nós principais para suas contrapartes 3D (`CharacterBody3D`, `RigidBody3D`, `Camera3D`, etc.).
    - Implementar controle de jogador em 3D (movimento em X, Z; pulo em Y).
    - Configurar física 3D para a bola.
    - Criar ou obter assets 3D básicos (placeholders inicialmente).
    - Desenvolver um sistema de câmera 3D adequado para o jogo.
- **Status Atual da Migração 3D (Fase Inicial):**
    - :heavy_check_mark: **Configuração Inicial do Ambiente 3D:** Cena `Game3D.tscn` criada com iluminação, campo placeholder e câmera inicial.
    - :heavy_check_mark: **Criação do Jogador 3D Básico:** Cena `Player3D.tscn` com `CharacterBody3D`, mesh placeholder, colisão e script `player_3d_controller.gd` para movimento (WASD), pulo (Espaço) e rotação. Inputs configurados.
    - :heavy_check_mark: **Criação da Bola 3D Básica:** Cena `Ball3D.tscn` com `RigidBody3D`, mesh, colisão e script `ball_3d_controller.gd`. Propriedades físicas básicas definidas.
    - :heavy_check_mark: **Integração Inicial na Cena 3D:** `Player3D` e `Ball3D` instanciados em `Game3D.tscn`.
    - :heavy_check_mark: **Testes Iniciais e Iteração:** Instruções para testes manuais fornecidas ao usuário.
    - :heavy_check_mark: **Implementar Chute Básico em 3D:** Lógica de chute adicionada ao `player_3d_controller.gd` usando `Area3D` para detecção.
- **Status da Fase Atual (Refinamentos):**
    - :heavy_check_mark: **Refinamento da Câmera 3D:** Script `camera_controller.gd` criado e aplicado, com seguimento suave e offsets configuráveis.
    - :heavy_check_mark: **Desenvolvimento do Modo de Treinamento (Fase 2 - Funcionalidades):** Script `training_mode_logic.gd` criado e integrado, permitindo reset da bola (R) e jogador (Shift+R). Gols placeholders adicionados. Inputs configurados.
    - :heavy_check_mark: **Melhorias na Mecânica de Chute:** Implementada carga de chute (segurar 'F'), variação de força, e influência na elevação com `aim_high` (Shift+F). Movimento do jogador relativo à câmera. Valores de força e tempo de carga ajustados. Lógica de detecção de chute refinada.
    - :heavy_check_mark: **Feedback Visual e Sonoro Básico (Lógica):** Nós `AudioStreamPlayer3D` adicionados ao jogador (chute) e bola (colisão). Scripts atualizados para tocar sons (arquivos de áudio a serem adicionados pelo usuário). Som de colisão da bola agora varia com a intensidade.
    - :white_check_mark: **Testes e Ajustes:** Usuário indicou satisfação com os ajustes proativos e adiou testes detalhados. Consideramos esta rodada de ajustes concluída com base no feedback.
- **Arquivos Criados/Modificados (Refinamentos - Rodada 2):**
    - `scripts/ball_3d/ball_3d_controller.gd` (ajustes de física, resistência do ar, som de colisão dinâmico)
    - `scenes/ball/Ball3D.tscn` (ajustes nos parâmetros de física no Inspector)
    - `scripts/player_3d/player_3d_controller.gd` (ajustes na movimentação, gravidade customizada, aceleração/desaceleração, rotação suave, parâmetros de chute, condição de chute)
    - `scripts/game_3d/camera_controller.gd` (lógica de anti-oclusão com RayCast, ajustes de offset)
    - `scenes/game/Game3D.tscn` (atualizados parâmetros da câmera)
    - `scenes/game/TrainingMode3D.tscn` (atualizados parâmetros da câmera)
- **Próximos Passos da Migração 3D:** Testes extensivos pelo usuário são altamente recomendados. Após isso, novas funcionalidades ou mais refinamentos.
    - `scenes/game/Game3D.tscn` (atualizado com script de câmera)
    - `scenes/game/TrainingMode3D.tscn` (atualizado com script de câmera, lógica de treino, gols placeholder)
    - `scripts/player_3d/player_3d_controller.gd` (mecânica de chute aprimorada, som)
    - `scenes/player/Player3D.tscn` (adicionado AudioStreamPlayer3D)
    - `scripts/ball_3d/ball_3d_controller.gd` (som de colisão)
    - `scenes/ball/Ball3D.tscn` (adicionado AudioStreamPlayer3D, conectado sinal `body_entered`)
    - `project.godot` (novas actions de input: `reset_ball`, `reset_player`, `aim_high`)
- **Próximos Passos da Migração 3D:** Testes extensivos, depois mais refinamentos ou novas funcionalidades 3D.

### 9. Modo de Treinamento (Nova Solicitação)
- **Objetivo:** Fornecer um ambiente para o usuário testar livremente as mecânicas do jogo (movimentação, chutes, etc.) sem a pressão de uma partida.
- **Funcionalidades Propostas:**
    - Campo de jogo aberto.
    - Bola disponível para o jogador.
    - Sem oponentes ou com opção de adicionar oponentes estáticos/comportamento simples (ex: goleiro parado).
    - Possibilidade de resetar a posição da bola/jogador facilmente.
    - Sem cronômetro ou placar.
    - Pode servir como um ambiente de teste para novas mecânicas antes de integrá-las ao jogo principal.
- **Implementação:**
    - :heavy_check_mark: **Fase 1 (Ambiente Básico 3D):** Cena `TrainingMode3D.tscn` criada duplicando `Game3D.tscn`. UI básica informativa adicionada.
    - :heavy_check_mark: **Fase 2 (Funcionalidades):** Resets de bola e jogador implementados. Gols placeholders adicionados.
- **Arquivos Criados/Modificados (Modo Treinamento):**
    - `scenes/game/TrainingMode3D.tscn`
    - `scripts/game_3d/training_mode_logic.gd`
- **Arquivos Potenciais (Futuro):** Melhorias na UI do modo treino, opções de configuração.

## Prioridades e Próximos Passos (Revisados)

**Decisão do Usuário:** Migração para 3D é a prioridade máxima. Testes serão feitos após esta rodada de desenvolvimento.

1.  **Testes e Ajustes:** O usuário realizará testes nas funcionalidades implementadas. Feedback é aguardado.
2.  **Continuar Implementação da Migração 3D (Conforme plano detalhado e feedback dos testes):**
    -   Refinamento da câmera 3D com base nos testes.
    -   Ajustes na mecânica de chute (força, direção, elevação) com base nos testes.
    -   Ajustes na física da bola e do jogador, se necessário.
    -   Eventualmente, substituição de placeholders por assets 3D finais (quando disponíveis).
3.  **Re-priorizar outras tarefas originais** (IA, Faltas, etc.) para após a estabilização do núcleo 3D.
4.  **Estrutura de Testes Automatizados:** Introduzir testes para as novas mecânicas 3D assim que estiverem mais estáveis.
