#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

# Delegate into the control-node container if running on the host
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

cfg_path="/home/ansible_user/ansible.cfg"
cfg_dir="$(dirname "$cfg_path")"
inventory_path="/home/ansible_user/inventory"

declare -A messages_en=(
  ["wrong_name"]="ansible.cfg has the wrong name (found: FOUND_FILE). Rename it: mv FOUND_FILE $cfg_path"
  ["no_file"]="$cfg_path does not exist. Create it with [defaults] and [privilege_escalation] sections."
  ["empty_file"]="$cfg_path exists but is empty. Add the required [defaults] and [privilege_escalation] sections."
  ["no_defaults"]="$cfg_path is missing the [defaults] section header."
  ["no_privilege"]="$cfg_path is missing the [privilege_escalation] section header."
  ["remote_user_space"]="'remote_user' has spaces around '='. Use: remote_user=ansible_user (no spaces)."
  ["remote_user_wrong"]="'remote_user' is set to the wrong value. Expected: remote_user=ansible_user"
  ["no_remote_user"]="$cfg_path is missing 'remote_user=ansible_user' under [defaults]."
  ["inventory_space"]="'inventory' has spaces around '='. Use: inventory=$inventory_path (no spaces)."
  ["inventory_wrong"]="'inventory' is set to a different path. Expected: inventory=$inventory_path"
  ["no_inventory"]="$cfg_path is missing 'inventory=$inventory_path' under [defaults]."
  ["become_space"]="'become' has spaces around '='. Use: become=true (no spaces)."
  ["become_wrong"]="'become' is not set to true. Expected: become=true"
  ["no_become"]="$cfg_path is missing 'become=true' under [privilege_escalation]."
  ["become_wrong_section"]="'become=true' must be under [privilege_escalation], not [defaults]."
)
declare -A messages_fr=(
  ["wrong_name"]="ansible.cfg a un mauvais nom (trouvé : FOUND_FILE). Renommez-le : mv FOUND_FILE $cfg_path"
  ["no_file"]="$cfg_path n'existe pas. Créez-le avec les sections [defaults] et [privilege_escalation]."
  ["empty_file"]="$cfg_path existe mais est vide. Ajoutez les sections [defaults] et [privilege_escalation] requises."
  ["no_defaults"]="$cfg_path ne contient pas l'en-tête de section [defaults]."
  ["no_privilege"]="$cfg_path ne contient pas l'en-tête de section [privilege_escalation]."
  ["remote_user_space"]="'remote_user' a des espaces autour de '='. Utilisez : remote_user=ansible_user (sans espaces)."
  ["remote_user_wrong"]="'remote_user' est défini avec une mauvaise valeur. Attendu : remote_user=ansible_user"
  ["no_remote_user"]="$cfg_path ne contient pas 'remote_user=ansible_user' sous [defaults]."
  ["inventory_space"]="'inventory' a des espaces autour de '='. Utilisez : inventory=$inventory_path (sans espaces)."
  ["inventory_wrong"]="'inventory' pointe vers un chemin différent. Attendu : inventory=$inventory_path"
  ["no_inventory"]="$cfg_path ne contient pas 'inventory=$inventory_path' sous [defaults]."
  ["become_space"]="'become' a des espaces autour de '='. Utilisez : become=true (sans espaces)."
  ["become_wrong"]="'become' n'est pas défini à true. Attendu : become=true"
  ["no_become"]="$cfg_path ne contient pas 'become=true' sous [privilege_escalation]."
  ["become_wrong_section"]="'become=true' doit être sous [privilege_escalation], pas sous [defaults]."
)



# Helper: returns the section name ([defaults], [privilege_escalation], etc.)
# that contains the given key in the config file
get_key_section() {
  local key="$1" current_section=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
      current_section="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]*${key}[[:space:]]*= ]]; then
      echo "$current_section"; return
    fi
  done < "$cfg_path"
}

# CHECK 1 — file must be named exactly "ansible.cfg"
# Catches common wrong names in the same directory
if [ ! -f "$cfg_path" ]; then
  found_file=""
  for wrong_name in ansible.cfg.ini ansible.cfg.txt ansible.cfg.bak ansiblecfg ansible_cfg ansible.conf ansible.ini; do
    [ -f "$cfg_dir/$wrong_name" ] && found_file="$cfg_dir/$wrong_name" && break
  done
  if [ -n "$found_file" ]; then
    msg=$(get_message wrong_name)
    echo "${msg//FOUND_FILE/$found_file}"; exit 0
  fi
  echo "$(get_message no_file)"; exit 0
fi

# CHECK 2 — file must not be empty
if [ ! -s "$cfg_path" ]; then
  echo "$(get_message empty_file)"; exit 0
fi

# CHECK 3 — [defaults] section header must be present
if ! grep -q "^\[defaults\]" "$cfg_path"; then
  echo "$(get_message no_defaults)"; exit 0
fi

# CHECK 4 — [privilege_escalation] section header must be present
if ! grep -q "^\[privilege_escalation\]" "$cfg_path"; then
  echo "$(get_message no_privilege)"; exit 0
fi

# CHECK 5 — remote_user: detect spaces around = before checking value
# Catches: remote_user = ansible_user  (spaces around =)
if grep -qi "^remote_user\s*=\s*ansible_user" "$cfg_path" && ! grep -q "^remote_user=ansible_user" "$cfg_path"; then
  echo "$(get_message remote_user_space)"; exit 0
fi
# Catches: remote_user=root  or  remote_user=student  (wrong value)
if grep -q "^remote_user=" "$cfg_path" && ! grep -q "^remote_user=ansible_user" "$cfg_path"; then
  echo "$(get_message remote_user_wrong)"; exit 0
fi
# Catches: key missing entirely
if ! grep -q "^remote_user=ansible_user" "$cfg_path"; then
  echo "$(get_message no_remote_user)"; exit 0
fi

# CHECK 6 — inventory: detect spaces around = before checking value
if grep -qi "^inventory\s*=\s*${inventory_path}" "$cfg_path" && ! grep -q "^inventory=${inventory_path}" "$cfg_path"; then
  echo "$(get_message inventory_space)"; exit 0
fi
# Catches: inventory=/some/other/path
if grep -q "^inventory=" "$cfg_path" && ! grep -q "^inventory=${inventory_path}" "$cfg_path"; then
  echo "$(get_message inventory_wrong)"; exit 0
fi
# Catches: key missing entirely
if ! grep -q "^inventory=${inventory_path}" "$cfg_path"; then
  echo "$(get_message no_inventory)"; exit 0
fi

# CHECK 7 — become: detect spaces around = before checking value
if grep -qi "^become\s*=\s*true" "$cfg_path" && ! grep -q "^become=true" "$cfg_path"; then
  echo "$(get_message become_space)"; exit 0
fi
# Catches: become=false or become=yes (non-standard)
if grep -q "^become=" "$cfg_path" && ! grep -q "^become=true" "$cfg_path"; then
  echo "$(get_message become_wrong)"; exit 0
fi
# Catches: key missing entirely
if ! grep -q "^become=true" "$cfg_path"; then
  echo "$(get_message no_become)"; exit 0
fi
# Catches: become=true placed under [defaults] instead of [privilege_escalation]
become_section=$(get_key_section "become")
if [[ "$become_section" != "privilege_escalation" ]]; then
  echo "$(get_message become_wrong_section)"; exit 0
fi

echo '{"result": "0"}'
