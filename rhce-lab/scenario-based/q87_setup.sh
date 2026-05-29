#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

cmd1="\`\`\`shell
ansible-doc ansible.builtin.service | grep -A5 'state:'
\`\`\`"

answer_a="ansible.builtin.service"
answer_b="ansible.builtin.systemd"
answer_c="ansible.builtin.command"
answer_d="ansible.builtin.daemon"
solution="$answer_a"

case "$lang" in
  en)
    question="After modifying SSH configuration files on the webservers, you need to ensure the SSH daemon is **restarted** to apply changes, and **enabled to start at boot**. Which Ansible module manages **service state** (started, stopped, restarted) and **boot enablement** across Linux distributions without needing to know the init system?"
    hint="This module provides a consistent interface for managing services regardless of whether the system uses systemd, SysV init, or Upstart. It supports: name, state (started/stopped/restarted/reloaded), enabled, and daemon_reload. Run: ansible-doc ansible.builtin.service"
    inst1="Explore the module documentation to see state options:"
    ;;
  fr)
    question="Après avoir modifié les fichiers de configuration SSH sur les webservers, vous devez vous assurer que le démon SSH est **redémarré** pour appliquer les changements, et **activé au démarrage**. Quel module Ansible gère **l'état des services** (started, stopped, restarted) et **l'activation au démarrage** sur les distributions Linux sans avoir besoin de connaître le système d'init ?"
    hint="Ce module fournit une interface cohérente pour gérer les services qu'il utilise systemd, SysV init ou Upstart. Il supporte : name, state (started/stopped/restarted/reloaded), enabled, et daemon_reload. Exécutez : ansible-doc ansible.builtin.service"
    inst1="Explorez la documentation du module pour voir les options d'état :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")
shuffled=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --arg inst1 "$inst1" \
  --arg cmd1 "$cmd1" \
  --arg solution "$solution" \
  --argjson answers "{$shuffled}" \
  '{
    "question": $question,
    "type": "multi",
    "answers": $answers,
    "hint": $hint,
    "instructions": [{"instruction": $inst1, "command": $cmd1}],
    "solution": $solution,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "ansible,service,module,rhce"
  }'
