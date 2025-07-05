# Stronda Soccer ⚽

Um jogo de futebol 2.5D desenvolvido em Godot 4, com suporte a multiplayer local e mecânicas avançadas de física.

## 🎮 Características

- **Multiplayer Local**: Suporte para até 4 jogadores
- **Física Avançada**: Sistema de física realista para bola e jogadores
- **Gráficos 2.5D**: Visual moderno com efeitos 2.5D
- **Sistema Tático**: IA e comportamento tático dos jogadores
- **Audio Sistema**: Efeitos sonoros e música ambiente
- **UI Moderna**: Interface responsiva e intuitiva

## 🚀 Como Executar

1. **Instale o Godot 4.4+**
   - Download: [https://godotengine.org/](https://godotengine.org/)

2. **Clone o repositório**
   ```bash
   git clone https://github.com/Lucasa22/stronda-soccer.git
   cd stronda-soccer
   ```

3. **Abra no Godot**
   - Abra o Godot Engine
   - Clique em "Import"
   - Selecione o arquivo `project.godot`
   - Clique em "Import & Edit"

4. **Execute o jogo**
   - Pressione F5 ou clique no botão Play
   - Selecione `Main.tscn` como cena principal se solicitado

## 📁 Estrutura do Projeto

```
stronda-soccer/
├── assets/              # Assets do jogo
│   ├── audio/           # Músicas e efeitos sonoros
│   ├── fonts/           # Fontes
│   └── sprites/         # Sprites e texturas
├── scenes/              # Cenas do Godot
│   ├── arena/           # Cenas da arena
│   ├── ball/            # Cena da bola
│   ├── game/            # Cena principal do jogo
│   ├── player/          # Cenas dos jogadores
│   └── ui/              # Interface do usuário
├── scripts/             # Scripts GDScript
│   ├── arena/           # Scripts da arena
│   ├── effects/         # Efeitos visuais
│   ├── game/            # Lógica principal do jogo
│   ├── globals/         # Constantes globais
│   ├── managers/        # Gerenciadores de sistema
│   ├── network/         # Sistema de rede
│   ├── physics/         # Sistema de física
│   ├── player/          # Controle dos jogadores
│   └── ui/              # Scripts da UI
├── docs/                # Documentação
└── tools/               # Ferramentas de desenvolvimento
```

## 🎯 Controles

### Jogador 1 (Teclado)
- **WASD**: Movimento
- **Space**: Pular
- **Shift**: Sprint
- **F**: Chutar

### Jogador 2 (Teclado)
- **Setas**: Movimento
- **Enter**: Pular
- **Ctrl**: Sprint
- **NumPad 0**: Chutar

### Controle (Gamepad)
- **Analógico Esquerdo**: Movimento
- **A/X**: Pular
- **B/Circle**: Sprint
- **Y/Square**: Chutar

## 🛠️ Desenvolvimento

### Pré-requisitos
- Godot 4.4+
- Git

### Contribuindo
1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📋 Roadmap

- [x] Sistema básico de movimento
- [x] Física da bola
- [x] Multiplayer local
- [x] Sistema de chutes
- [ ] IA dos jogadores
- [ ] Sistema de times
- [ ] Efeitos visuais avançados
- [ ] Sistema de torneios
- [ ] Multiplayer online

## 🐛 Bugs Conhecidos

Veja os [Issues](https://github.com/Lucasa22/stronda-soccer/issues) para bugs conhecidos e features planejadas.

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Autores

- **Lucas** - *Desenvolvimento inicial* - [Lucasa22](https://github.com/Lucasa22)

## 🙏 Agradecimentos

- Comunidade Godot
- Assets utilizados (creditar quando aplicável)
- Beta testers

---

⚽ **Feito com ❤️ e Godot 4** ⚽
