#!/usr/bin/env bash
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"
SERVER="$BASE/server"
JAVA="$BASE/java/bin/java"
PAPER="$SERVER/paper.jar"
LOG="$SERVER/logs/latest.log"
PIDFILE="$SERVER/.server.pid"
CONSOLE="$SERVER/.console.pipe"
RAM_MIN="1G"
RAM_MAX="4G"
PORT_DEFAULT=25565

mkdir -p "$SERVER/plugins" "$SERVER/logs" "$BASE/backups"

is_running() {
  [[ -f "$PIDFILE" ]] || return 1
  local pid; pid=$(cat "$PIDFILE" 2>/dev/null || true)
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

server_pid() { cat "$PIDFILE" 2>/dev/null || true; }

port() {
  awk -F= '$1=="server-port" {print $2}' "$SERVER/server.properties" 2>/dev/null | tail -1
}

port() { local p; p=$(awk -F= '$1=="server-port" {print $2}' "$SERVER/server.properties" 2>/dev/null | tail -1); echo "${p:-$PORT_DEFAULT}"; }

players() {
  if ! is_running; then echo "0"; return; fi
  local n; n=$(grep -oE 'There are [0-9]+ of a max of [0-9]+' "$LOG" 2>/dev/null | tail -1 | grep -oE 'There are [0-9]+' | awk '{print $3}' || true)
  echo "${n:-?}"
}

start_server() {
  if is_running; then echo "El servidor ya está iniciado."; read -rp "ENTER..."; return; fi
  if [[ ! -x "$JAVA" ]]; then echo "ERROR: falta Java portable en $JAVA"; read -rp "ENTER..."; return; fi
  if [[ ! -f "$PAPER" ]]; then echo "ERROR: falta $PAPER"; read -rp "ENTER..."; return; fi
  rm -f "$CONSOLE"
  mkfifo "$CONSOLE"
  : > "$LOG"
  nohup "$JAVA" -Xms"$RAM_MIN" -Xmx"$RAM_MAX" -jar "$PAPER" --nogui < "$CONSOLE" >> "$LOG" 2>&1 &
  echo $! > "$PIDFILE"
  sleep 2
  echo "Servidor iniciado en segundo plano."
  read -rp "ENTER..."
}

stop_server() {
  if ! is_running; then echo "El servidor no está iniciado por el panel."; read -rp "ENTER..."; return; fi
  echo "save-all" > "$CONSOLE" 2>/dev/null || true
  sleep 2
  echo "stop" > "$CONSOLE" 2>/dev/null || true
  local i=0
  while is_running && (( i < 30 )); do sleep 1; ((i++)); done
  if is_running; then kill "$(server_pid)" 2>/dev/null || true; fi
  rm -f "$PIDFILE" "$CONSOLE"
  echo "Servidor detenido."
  read -rp "ENTER..."
}

restart_server() { stop_server; start_server; }

console_menu() {
  if ! is_running; then echo "Servidor offline."; read -rp "ENTER..."; return; fi
  clear
  echo "=== CONSOLA MINECRAFT ==="
  echo "Escribe comandos sin / . Usa 'salir' para volver."
  while is_running; do
    read -rp "> " cmd || break
    [[ "$cmd" == "salir" ]] && break
    [[ -z "$cmd" ]] && continue
    echo "$cmd" > "$CONSOLE" 2>/dev/null || true
    sleep 0.4
    tail -n 12 "$LOG" 2>/dev/null
  done
}

properties_menu() {
  if [[ ! -f "$SERVER/server.properties" ]]; then
    echo "server.properties aún no existe. Inicia Paper una vez primero."
  else
    nano "$SERVER/server.properties"
  fi
}

permissions_menu() {
  while true; do
    clear; echo "=== PERMISOS ==="
    echo "1) Dar OP"; echo "2) Quitar OP"; echo "3) Añadir whitelist"; echo "4) Quitar whitelist"; echo "5) Ver whitelist"; echo "0) Volver"
    read -rp "> " op
    case "$op" in
      1) read -rp "Jugador: " n; echo "op $n" > "$CONSOLE"; read -rp "ENTER...";;
      2) read -rp "Jugador: " n; echo "deop $n" > "$CONSOLE"; read -rp "ENTER...";;
      3) read -rp "Jugador: " n; echo "whitelist add $n" > "$CONSOLE"; read -rp "ENTER...";;
      4) read -rp "Jugador: " n; echo "whitelist remove $n" > "$CONSOLE"; read -rp "ENTER...";;
      5) [[ -p "$CONSOLE" ]] && echo "whitelist list" > "$CONSOLE"; sleep .5; tail -n 8 "$LOG"; read -rp "ENTER...";;
      0) return;;
    esac
  done
}

plugins_menu() {
  while true; do
    clear; echo "=== PLUGINS ==="; echo
    shopt -s nullglob; local arr=("$SERVER/plugins"/*.jar); shopt -u nullglob
    if ((${#arr[@]}==0)); then echo "No hay plugins instalados."; else printf '%s\n' "${arr[@]##*/}"; fi
    echo; echo "Los .jar se instalan copiándolos a:"; echo "$SERVER/plugins/"
    echo; echo "1) Abrir carpeta de plugins"; echo "2) Eliminar plugin"; echo "0) Volver"
    read -rp "> " op
    case "$op" in
      1) xdg-open "$SERVER/plugins" >/dev/null 2>&1 || true; read -rp "ENTER...";;
      2) read -rp "Nombre exacto del .jar: " f; [[ -f "$SERVER/plugins/$f" ]] && rm -i "$SERVER/plugins/$f"; read -rp "ENTER...";;
      0) return;;
    esac
  done
}

backup_server() {
  local stamp out
  stamp=$(date +%Y-%m-%d_%H-%M-%S); out="$BASE/backups/minecraft-$stamp.tar.gz"
  if is_running; then echo "save-all" > "$CONSOLE"; sleep 2; fi
  tar -czf "$out" -C "$SERVER" world world_nether world_the_end plugins server.properties ops.json whitelist.json 2>/dev/null || tar -czf "$out" -C "$SERVER" .
  echo "Backup creado: $out"; read -rp "ENTER..."
}

logs_menu() { clear; echo "=== LOGS ==="; tail -n 80 "$LOG" 2>/dev/null || echo "Sin logs."; read -rp "ENTER..."; }

info_menu() {
  clear
  echo "=== INFORMACIÓN ==="; echo
  echo "Estado:      $(is_running && echo ONLINE || echo OFFLINE)"
  echo "PID:         $(server_pid)"
  echo "Java:        $($JAVA -version 2>&1 | head -1 2>/dev/null || echo 'no disponible')"
  echo "Puerto:      $(port)"
  echo "IP local:    $(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "Ruta USB:    $BASE"
  echo "Paper:       $(basename "$PAPER")"
  echo "Plugins:     $(find "$SERVER/plugins" -maxdepth 1 -name '*.jar' 2>/dev/null | wc -l)"
  echo; read -rp "ENTER..."
}

while true; do
  clear
  echo "=================================================="
  echo "        MINECRAFT PORTABLE SERVER"
  echo "=================================================="
  echo "Estado: $(is_running && echo '● ONLINE' || echo '○ OFFLINE')    Jugadores: $(players)    Puerto: $(port)"
  echo
  echo "1) Iniciar servidor"
  echo "2) Parar servidor"
  echo "3) Reiniciar servidor"
  echo "4) Jugadores"
  echo "5) Consola"
  echo "6) Propiedades"
  echo "7) Permisos / OP"
  echo "8) Plugins"
  echo "9) Copia de seguridad"
  echo "10) Logs"
  echo "11) Información"
  echo "0) Salir"
  echo
  read -rp "> " choice
  case "$choice" in
    1) start_server;; 2) stop_server;; 3) restart_server;;
    4) [[ -p "$CONSOLE" ]] && echo "list" > "$CONSOLE"; sleep .5; tail -n 8 "$LOG"; read -rp "ENTER...";;
    5) console_menu;; 6) properties_menu;; 7) permissions_menu;; 8) plugins_menu;; 9) backup_server;; 10) logs_menu;; 11) info_menu;; 0) exit 0;;
  esac
done
