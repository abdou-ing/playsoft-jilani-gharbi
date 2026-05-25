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
  ["no_group"]="The 'developers' group does not exist. Create it first: sudo groupadd developers"
  ["no_user"]="User 'john' does not exist. Create it first: sudo useradd -m -s /bin/bash john"
  ["not_member"]="john is not a member of the developers group. Add him with: sudo usermod -aG developers john"
)
declare -A messages_fr=(
  ["no_group"]="Le groupe 'developers' n'existe pas. Créez-le d'abord : sudo groupadd developers"
  ["no_user"]="L'utilisateur 'john' n'existe pas. Créez-le d'abord : sudo useradd -m -s /bin/bash john"
  ["not_member"]="john n'est pas membre du groupe developers. Ajoutez-le avec : sudo usermod -aG developers john"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if ! getent group developers &>/dev/null; then
  echo "$(get_message no_group)"; exit 0
fi

if ! id john &>/dev/null; then
  echo "$(get_message no_user)"; exit 0
fi

if ! id john | grep -q "(developers)"; then
  echo "$(get_message not_member)"; exit 0
fi

echo '{"result": "0"}'
