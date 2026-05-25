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
  ["no_user"]="User 'john' does not exist. Create it with: sudo useradd -m -s /bin/bash john"
  ["wrong_shell"]="John's login shell is not /bin/bash. Fix it with: sudo usermod -s /bin/bash john"
  ["wrong_home"]="John's home directory entry in /etc/passwd is not /home/john. Check with: getent passwd john"
  ["no_home_dir"]="The home directory /home/john does not exist on disk. Re-create the user with: sudo userdel -r john && sudo useradd -m -s /bin/bash john"
)
declare -A messages_fr=(
  ["no_user"]="L'utilisateur 'john' n'existe pas. Créez-le avec : sudo useradd -m -s /bin/bash john"
  ["wrong_shell"]="Le shell de connexion de john n'est pas /bin/bash. Corrigez avec : sudo usermod -s /bin/bash john"
  ["wrong_home"]="Le répertoire home de john dans /etc/passwd n'est pas /home/john. Vérifiez avec : getent passwd john"
  ["no_home_dir"]="Le répertoire /home/john n'existe pas sur le disque. Recréez l'utilisateur avec : sudo userdel -r john && sudo useradd -m -s /bin/bash john"
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if ! id john &>/dev/null; then
  echo "$(get_message no_user)"; exit 0
fi

passwd_entry=$(getent passwd john)
user_shell=$(echo "$passwd_entry" | cut -d: -f7)
user_home=$(echo "$passwd_entry" | cut -d: -f6)

if [ "$user_shell" != "/bin/bash" ]; then
  echo "$(get_message wrong_shell)"; exit 0
fi

if [ "$user_home" != "/home/john" ]; then
  echo "$(get_message wrong_home)"; exit 0
fi

if [ ! -d "/home/john" ]; then
  echo "$(get_message no_home_dir)"; exit 0
fi

echo '{"result": "0"}'
