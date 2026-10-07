#!/usr/bin/env bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
JAVA="$BASE/java/bin/java"
PAPER="$BASE/server/paper.jar"
if [[ "$(uname -s)" != "Linux" ]]; then echo "Este proyecto está preparado para Linux/Fedora."; exit 1; fi
if [[ "$(uname -m)" != "x86_64" ]]; then echo "Arquitectura no soportada: $(uname -m)"; exit 1; fi
[[ -x "$JAVA" ]] || { echo "Falta Java portable: $JAVA"; exit 1; }
[[ -f "$PAPER" ]] || { echo "Falta Paper: $PAPER"; exit 1; }
mkdir -p "$BASE/server/plugins" "$BASE/server/logs" "$BASE/backups"
chmod +x "$BASE"/*.sh "$BASE"/scripts/*.sh 2>/dev/null || true
cat > "$BASE/INICIAR.sh" <<'LAUNCH'
#!/usr/bin/env bash
BASE="$(cd "$(dirname "$0")" && pwd)"
exec "$BASE/PANEL.sh"
LAUNCH
chmod +x "$BASE/INICIAR.sh"
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/minecraft-portable-server.desktop" <<DESKTOP
[Desktop Entry]
Name=Minecraft Portable Server
Comment=Panel del servidor Minecraft portable
Exec=$BASE/INICIAR.sh
Terminal=true
Type=Application
Categories=Game;
StartupNotify=true
DESKTOP
printf '\nInstalación preparada en: %s\n' "$BASE"
printf 'Lanzador: Minecraft Portable Server\n'
