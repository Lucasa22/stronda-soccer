@echo off
echo Removendo arquivos .txt que foram convertidos para .gd...
echo.

:: Lista dos arquivos .txt que devem ser removidos
set "files_to_remove=multiplayer-player.txt game-multiplayer.txt arena-multiplayer.txt network-manager.txt audio-system.txt advanced-physics-controller.txt ai-tactical-behavior.txt enhanced-player-controller.txt field-25d-example.txt visual-effects-manager.txt ui-manager.txt tactical-system.txt tactical-feedback-system.txt simple-25d-effects.txt 25d-implementation.txt player-manager.txt player-script.txt ball-script.txt game-script.txt arena-builder.txt game-constants.txt project-godot-config.txt project-structure.txt multiplayer-inputs.txt"

:: Verificar e remover cada arquivo
for %%f in (%files_to_remove%) do (
    if exist "%%f" (
        echo Removendo: %%f
        del "%%f"
    ) else (
        echo Arquivo nao encontrado: %%f
    )
)

:: Remover também arquivos duplicados com (1) no nome
echo.
echo Removendo arquivos duplicados...
if exist "arena-multiplayer (1).txt" (
    echo Removendo: arena-multiplayer (1).txt
    del "arena-multiplayer (1).txt"
)

if exist "network-manager (1).txt" (
    echo Removendo: network-manager (1).txt
    del "network-manager (1).txt"
)

if exist "audio-system (1).txt" (
    echo Removendo: audio-system (1).txt
    del "audio-system (1).txt"
)

if exist "enhanced-player-controller (1).txt" (
    echo Removendo: enhanced-player-controller (1).txt
    del "enhanced-player-controller (1).txt"
)

if exist "enhanced-player-controller (2).txt" (
    echo Removendo: enhanced-player-controller (2).txt
    del "enhanced-player-controller (2).txt"
)

if exist "visual-effects-manager (1).txt" (
    echo Removendo: visual-effects-manager (1).txt
    del "visual-effects-manager (1).txt"
)

if exist "ui-manager (1).txt" (
    echo Removendo: ui-manager (1).txt
    del "ui-manager (1).txt"
)

if exist "advanced-physics-controller (1).txt" (
    echo Removendo: advanced-physics-controller (1).txt
    del "advanced-physics-controller (1).txt"
)

echo.
echo Processo concluido!
echo.
echo Arquivos restantes no diretorio:
dir /b *.txt
echo.
pause
