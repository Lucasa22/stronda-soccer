@echo off
echo Converting .txt files to .gd files...
echo.

REM Convert script files (.txt to .gd)
echo Converting script files:

if exist "25d-implementation.txt" (
    echo - 25d-implementation.txt ^> 25d-implementation.gd
    copy "25d-implementation.txt" "25d-implementation.gd" >nul
)

if exist "advanced-physics-controller.txt" (
    echo - advanced-physics-controller.txt ^> advanced-physics-controller.gd
    copy "advanced-physics-controller.txt" "advanced-physics-controller.gd" >nul
)

if exist "advanced-physics-controller (1).txt" (
    echo - advanced-physics-controller (1).txt ^> advanced-physics-controller-alt.gd
    copy "advanced-physics-controller (1).txt" "advanced-physics-controller-alt.gd" >nul
)

if exist "ai-tactical-behavior.txt" (
    echo - ai-tactical-behavior.txt ^> ai-tactical-behavior.gd
    copy "ai-tactical-behavior.txt" "ai-tactical-behavior.gd" >nul
)

if exist "arena-builder.txt" (
    echo - arena-builder.txt ^> arena-builder-backup.gd
    copy "arena-builder.txt" "arena-builder-backup.gd" >nul
)

if exist "arena-multiplayer.txt" (
    echo - arena-multiplayer.txt ^> arena-multiplayer.gd
    copy "arena-multiplayer.txt" "arena-multiplayer.gd" >nul
)

if exist "arena-multiplayer (1).txt" (
    echo - arena-multiplayer (1).txt ^> arena-multiplayer-alt.gd
    copy "arena-multiplayer (1).txt" "arena-multiplayer-alt.gd" >nul
)

if exist "audio-system.txt" (
    echo - audio-system.txt ^> audio-system.gd
    copy "audio-system.txt" "audio-system.gd" >nul
)

if exist "audio-system (1).txt" (
    echo - audio-system (1).txt ^> audio-system-alt.gd
    copy "audio-system (1).txt" "audio-system-alt.gd" >nul
)

if exist "ball-script.txt" (
    echo - ball-script.txt ^> ball-script-backup.gd
    copy "ball-script.txt" "ball-script-backup.gd" >nul
)

if exist "enhanced-player-controller.txt" (
    echo - enhanced-player-controller.txt ^> enhanced-player-controller.gd
    copy "enhanced-player-controller.txt" "enhanced-player-controller.gd" >nul
)

if exist "enhanced-player-controller (1).txt" (
    echo - enhanced-player-controller (1).txt ^> enhanced-player-controller-alt.gd
    copy "enhanced-player-controller (1).txt" "enhanced-player-controller-alt.gd" >nul
)

if exist "enhanced-player-controller (2).txt" (
    echo - enhanced-player-controller (2).txt ^> enhanced-player-controller-alt2.gd
    copy "enhanced-player-controller (2).txt" "enhanced-player-controller-alt2.gd" >nul
)

if exist "field-25d-example.txt" (
    echo - field-25d-example.txt ^> field-25d-example.gd
    copy "field-25d-example.txt" "field-25d-example.gd" >nul
)

if exist "game-constants.txt" (
    echo - game-constants.txt ^> game-constants-backup.gd
    copy "game-constants.txt" "game-constants-backup.gd" >nul
)

if exist "game-multiplayer.txt" (
    echo - game-multiplayer.txt ^> game-multiplayer-backup.gd
    copy "game-multiplayer.txt" "game-multiplayer-backup.gd" >nul
)

if exist "game-script.txt" (
    echo - game-script.txt ^> game-script-backup.gd
    copy "game-script.txt" "game-script-backup.gd" >nul
)

if exist "multiplayer-inputs.txt" (
    echo - multiplayer-inputs.txt ^> multiplayer-inputs.gd
    copy "multiplayer-inputs.txt" "multiplayer-inputs.gd" >nul
)

if exist "multiplayer-player.txt" (
    echo - multiplayer-player.txt ^> multiplayer-player-backup.gd
    copy "multiplayer-player.txt" "multiplayer-player-backup.gd" >nul
)

if exist "network-manager.txt" (
    echo - network-manager.txt ^> network-manager.gd
    copy "network-manager.txt" "network-manager.gd" >nul
)

if exist "network-manager (1).txt" (
    echo - network-manager (1).txt ^> network-manager-alt.gd
    copy "network-manager (1).txt" "network-manager-alt.gd" >nul
)

if exist "player-manager.txt" (
    echo - player-manager.txt ^> player-manager-backup.gd
    copy "player-manager.txt" "player-manager-backup.gd" >nul
)

if exist "player-script.txt" (
    echo - player-script.txt ^> player-script-backup.gd
    copy "player-script.txt" "player-script-backup.gd" >nul
)

if exist "simple-25d-effects.txt" (
    echo - simple-25d-effects.txt ^> simple-25d-effects.gd
    copy "simple-25d-effects.txt" "simple-25d-effects.gd" >nul
)

if exist "tactical-feedback-system.txt" (
    echo - tactical-feedback-system.txt ^> tactical-feedback-system.gd
    copy "tactical-feedback-system.txt" "tactical-feedback-system.gd" >nul
)

if exist "tactical-system.txt" (
    echo - tactical-system.txt ^> tactical-system.gd
    copy "tactical-system.txt" "tactical-system.gd" >nul
)

if exist "ui-manager.txt" (
    echo - ui-manager.txt ^> ui-manager.gd
    copy "ui-manager.txt" "ui-manager.gd" >nul
)

if exist "ui-manager (1).txt" (
    echo - ui-manager (1).txt ^> ui-manager-alt.gd
    copy "ui-manager (1).txt" "ui-manager-alt.gd" >nul
)

if exist "visual-effects-manager.txt" (
    echo - visual-effects-manager.txt ^> visual-effects-manager.gd
    copy "visual-effects-manager.txt" "visual-effects-manager.gd" >nul
)

if exist "visual-effects-manager (1).txt" (
    echo - visual-effects-manager (1).txt ^> visual-effects-manager-alt.gd
    copy "visual-effects-manager (1).txt" "visual-effects-manager-alt.gd" >nul
)

echo.
echo Converting documentation files:

if exist "project-structure.txt" (
    echo - project-structure.txt ^> project-structure.md
    copy "project-structure.txt" "project-structure.md" >nul
)

if exist "project-godot-config.txt" (
    echo - project-godot-config.txt ^> project-godot-config.md
    copy "project-godot-config.txt" "project-godot-config.md" >nul
)

echo.
echo Conversion completed!
echo.
echo Files converted to .gd format:
dir /b *.gd | find /c /v ""
echo.
pause
