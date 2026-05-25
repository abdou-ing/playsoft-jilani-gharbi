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
  ["no_dir"]="/srv/devproject does not exist. Create it with: sudo mkdir -p /srv/devproject"
  ["no_group"]="The 'developers' group does not exist. Create it first: sudo groupadd developers"
  ["wrong_group"]="/srv/devproject is not owned by the 'developers' group. Fix with: sudo chown :developers /srv/devproject"
  ["no_setgid"]="/srv/devproject does not have the setgid bit set. Fix with: sudo chmod g+s /srv/devproject"
)
declare -A messages_fr=(
  ["no_dir"]="/srv/devproject n'existe pas. Créez-le avec : sudo mkdir -p /srv/devproject"
  ["no_group"]="Le groupe 'developers' n'existe pas. Créez-le d'abord : sudo groupadd developers"
  ["wrong_group"]="/srv/devproject n'appartient pas au groupe 'developers'. Corrigez avec : sudo chown :developers /srv/devproject"
  ["no_setgid"]="/srv/devproject n'a pas le bit setgid défini. Corrigez avec : sudo chmod g+s /srv/devproject"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if ! getent group developers &>/dev/null; then
  echo "$(get_message no_group)"; exit 0
fi

if [ ! -d "/srv/devproject" ]; then
  echo "$(get_message no_dir)"; exit 0
fi

dir_group=$(stat -c "%G" /srv/devproject)
if [ "$dir_group" != "developers" ]; then
  echo "$(get_message wrong_group)"; exit 0
fi

if ! find /srv/devproject -maxdepth 0 -perm -g+s -type d | grep -q "/srv/devproject"; then
  echo "$(get_message no_setgid)"; exit 0
fi

echo '{"result": "0"}'
