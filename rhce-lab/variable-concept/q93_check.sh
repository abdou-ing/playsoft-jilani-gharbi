#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

output_file="/home/ansible_user/uptime.txt"

# SKIP: auto-run uptime ad-hoc and save output silently
if [[ "$1" == "skip" ]]; then
  ansible webservers -m command -a 'uptime' -q > "$output_file" 2>/dev/null
  echo '{"result": "0"}'; exit 0
fi

declare -A messages_en=(
  ["no_file"]="File not found at $output_file. Run: ansible webservers -m command -a 'uptime' > ~/uptime.txt"
  ["empty_file"]="$output_file exists but is empty. Re-run the ad-hoc command to capture output."
  ["no_uptime"]="$output_file does not contain uptime output. Make sure you used -m command -a 'uptime'."
)
declare -A messages_fr=(
  ["no_file"]="Fichier introuvable à $output_file. Exécutez : ansible webservers -m command -a 'uptime' > ~/uptime.txt"
  ["empty_file"]="$output_file existe mais est vide. Relancez la commande ad-hoc pour capturer la sortie."
  ["no_uptime"]="$output_file ne contient pas de sortie uptime. Assurez-vous d'avoir utilisé -m command -a 'uptime'."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$output_file" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if [ ! -s "$output_file" ]; then
  echo "$(get_message empty_file)"; exit 0
fi

if ! grep -qi "load average\|up " "$output_file"; then
  echo "$(get_message no_uptime)"; exit 0
fi

echo '{"result": "0"}'
