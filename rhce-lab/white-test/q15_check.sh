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
  ["no_playbook"]="Playbook /home/ansible_user/workspace/storage.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/storage.yml"
  ["no_block"]="Playbook must use 'block:' section for the main LVM task."
  ["no_rescue"]="Playbook must use 'rescue:' section to handle LVM failures."
  ["no_always"]="Playbook must use 'always:' section to create the filesystem."
  ["no_lvol"]="Playbook does not use the 'lvol' module. Use: community.general.lvol"
  ["no_research_vg"]="Playbook does not reference VG 'research'. Set: vg: research"
  ["no_data_lv"]="Playbook does not create LV named 'data'. Set: lv: data"
  ["no_1500m"]="Block section must attempt to create LV with size 1500m."
  ["no_800m"]="Rescue section must create LV with size 800m when space is insufficient."
  ["no_filesystem"]="Always section must create an ext4 filesystem. Use: community.general.filesystem with fstype: ext4"
  ["no_register"]="Block task must register the result: register: lv_info"
  ["no_does_not_exist"]="Rescue section must check for 'does not exist' in lv_info.msg (VG not found case)."
  ["no_insufficient"]="Rescue section must check for 'insufficient' in lv_info.err (not enough space case)."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook /home/ansible_user/workspace/storage.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/storage.yml"
  ["no_block"]="Le playbook doit utiliser la section 'block:' pour la tâche LVM principale."
  ["no_rescue"]="Le playbook doit utiliser la section 'rescue:' pour gérer les échecs LVM."
  ["no_always"]="Le playbook doit utiliser la section 'always:' pour créer le système de fichiers."
  ["no_lvol"]="Le playbook n'utilise pas le module 'lvol'. Utilisez : community.general.lvol"
  ["no_research_vg"]="Le playbook ne référence pas le VG 'research'. Définissez : vg: research"
  ["no_data_lv"]="Le playbook ne crée pas un LV nommé 'data'. Définissez : lv: data"
  ["no_1500m"]="La section block doit tenter de créer un LV de taille 1500m."
  ["no_800m"]="La section rescue doit créer un LV de taille 800m quand l'espace est insuffisant."
  ["no_filesystem"]="La section always doit créer un système de fichiers ext4. Utilisez : community.general.filesystem avec fstype: ext4"
  ["no_register"]="La tâche block doit enregistrer le résultat : register: lv_info"
  ["no_does_not_exist"]="La section rescue doit vérifier 'does not exist' dans lv_info.msg (cas VG introuvable)."
  ["no_insufficient"]="La section rescue doit vérifier 'insufficient' dans lv_info.err (cas d'espace insuffisant)."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook must exist
[ -f "playbooks/storage.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — no syntax errors
ansible-playbook --syntax-check playbooks/storage.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — must have block/rescue/always structure
grep -q "block:" playbooks/storage.yml || { echo "$(get_message no_block)"; exit 0; }
grep -q "rescue:" playbooks/storage.yml || { echo "$(get_message no_rescue)"; exit 0; }
grep -q "always:" playbooks/storage.yml || { echo "$(get_message no_always)"; exit 0; }

# CHECK 4 — must use lvol module
grep -q "lvol" playbooks/storage.yml || { echo "$(get_message no_lvol)"; exit 0; }

# CHECK 5 — must reference VG 'research'
grep -q "research" playbooks/storage.yml || { echo "$(get_message no_research_vg)"; exit 0; }

# CHECK 6 — must create LV named 'data'
grep -q "lv:\s*data" playbooks/storage.yml || { echo "$(get_message no_data_lv)"; exit 0; }

# CHECK 7 — block section must use 1500m
grep -q "1500" playbooks/storage.yml || grep -q "1500m" playbooks/storage.yml || \
  { echo "$(get_message no_1500m)"; exit 0; }

# CHECK 8 — rescue section must use 800m
grep -q "800" playbooks/storage.yml || grep -q "800m" playbooks/storage.yml || \
  { echo "$(get_message no_800m)"; exit 0; }

# CHECK 9 — must use filesystem module in always
grep -q "filesystem" playbooks/storage.yml || { echo "$(get_message no_filesystem)"; exit 0; }
grep -q "ext4" playbooks/storage.yml || { echo "$(get_message no_filesystem)"; exit 0; }

# CHECK 10 — block task must register lv_info
grep -q "register.*lv_info\|lv_info" playbooks/storage.yml || { echo "$(get_message no_register)"; exit 0; }

# CHECK 11 — rescue must check for VG not found
grep -q "does not exist" playbooks/storage.yml || { echo "$(get_message no_does_not_exist)"; exit 0; }

# CHECK 12 — rescue must check for insufficient space
grep -q "insufficient" playbooks/storage.yml || { echo "$(get_message no_insufficient)"; exit 0; }

echo '{"result": "0"}'
