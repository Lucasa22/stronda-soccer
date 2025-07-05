@echo off
echo Organizando estrutura do projeto...

REM Mover scripts para pastas apropriadas
echo Movendo scripts...

REM Scripts globais
move "game-constants.gd" "scripts\globals\"

REM Scripts de jogador
move "player-script.gd" "scripts\player\"
move "multiplayer-player.gd" "scripts\player\"
move "enhanced-player-controller (1).txt" "scripts\player\enhanced-player-controller.gd"
move "enhanced-player-controller (2).txt" "scripts\player\enhanced-player-controller-v2.gd"

REM Scripts de jogo
move "game-script.gd" "scripts\game\"
move "game-multiplayer.gd" "scripts\game\"

REM Scripts de gerenciamento
move "player-manager.gd" "scripts\managers\"
move "ui-manager (1).txt" "scripts\ui\ui-manager.gd"
move "audio-system (1).txt" "scripts\managers\audio-system.gd"
move "visual-effects-manager (1).txt" "scripts\effects\visual-effects-manager.gd"

REM Scripts de arena
move "arena-builder.gd" "scripts\arena\"
move "arena-multiplayer (1).txt" "scripts\arena\arena-multiplayer.gd"

REM Scripts de física
move "advanced-physics-controller.gd" "scripts\physics\"
move "advanced-physics-controller (1).txt" "scripts\physics\advanced-physics-controller-backup.gd"
move "ball-script.gd" "scripts\physics\"

REM Scripts de rede
move "network-manager (1).txt" "scripts\network\network-manager.gd"

REM Scripts especiais
move "25d-implementation.gd" "scripts\effects\"

REM Mover documentação
echo Movendo documentação...
move "setup-guide.md" "docs\"
move "multiplayer-setup-guide.md" "docs\"
move "3d-migration-guide.md" "docs\"

REM Mover ferramentas
echo Movendo ferramentas...
move "convert_files.bat" "tools\"
move "remove_txt_files.bat" "tools\"

REM Mover ícone para assets
echo Movendo assets...
move "icon.svg" "assets\sprites\"

echo.
echo Organização concluída!
echo.
echo Nova estrutura:
echo ├── scripts/
echo │   ├── globals/       (Constantes e configurações)
echo │   ├── player/        (Scripts dos jogadores)
echo │   ├── game/          (Lógica principal do jogo)
echo │   ├── managers/      (Gerenciadores diversos)
echo │   ├── arena/         (Scripts da arena)
echo │   ├── physics/       (Física e mecânicas)
echo │   ├── effects/       (Efeitos visuais)
echo │   ├── ui/            (Interface do usuário)
echo │   └── network/       (Multiplayer online)
echo ├── scenes/
echo │   ├── player/
echo │   ├── ball/
echo │   ├── arena/
echo │   ├── game/
echo │   └── ui/
echo ├── assets/
echo │   ├── sprites/
echo │   ├── audio/
echo │   └── fonts/
echo ├── docs/              (Documentação)
echo └── tools/             (Scripts de desenvolvimento)
echo.
pause
