#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Which command shows the installed Ansible version?"
    hint="This command also displays the Python version and the config file path in use."
    instructions='[{"instruction": "Try it on the control node:", "command": "ansible --version"}]'
    answer_a="ansible --version"
    answer_b="ansible -v"
    answer_c="ansible version"
    answer_d="ansible --check"
    ;;
  fr)
    question="Quelle commande affiche la version d'Ansible installée ?"
    hint="Cette commande affiche aussi la version de Python et le chemin du fichier de configuration utilisé."
    instructions='[{"instruction": "Essayez-le sur le nœud de contrôle :", "command": "ansible --version"}]'
    answer_a="ansible --version"
    answer_b="ansible -v"
    answer_c="ansible version"
    answer_d="ansible --check"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac

answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --argjson instructions "$instructions" \
  --arg solution "$answer_a" \
  --arg shuffled "$shuffled_answers" \
  '{
    "question": $question,
    "type": "quiz",
    "answers": ($shuffled | split(",") | map(split(":") | {(.[0] | ltrimstr("\"") | rtrimstr("\"")): (.[1] | ltrimstr("\"") | rtrimstr("\""))}) | add),
    "hint": $hint,
    "instructions": $instructions,
    "solution": $solution,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "ansible,rhce,beginner"
  }'
