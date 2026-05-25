#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

declare -A messages_en=(
  ["no_user"]="User 'john' does not exist. Create it first: sudo useradd -m -s /bin/bash john"
  ["no_sudo"]="john is not in the sudo group. Grant sudo access with: sudo usermod -aG sudo john"
)
declare -A messages_fr=(
  ["no_user"]="L'utilisateur 'john' n'existe pas. Créez-le d'abord : sudo useradd -m -s /bin/bash john"
  ["no_sudo"]="john n'est pas dans le groupe sudo. Accordez l'accès sudo avec : sudo usermod -aG sudo john"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if ! id john &>/dev/null; then
  echo "$(get_message no_user)"; exit 0
fi

if ! id john | grep -q "(sudo)"; then
  echo "$(get_message no_sudo)"; exit 0
fi

echo '{"result": "0"}'
