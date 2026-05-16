#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Which command is used to execute an Ansible playbook named \`site.yml\` located in the current directory?"
    hint="Ansible has a dedicated command for running playbooks — it is different from the \`ansible\` ad-hoc command."
    instructions='[{"instruction": "To run a playbook, use", "command": "ansible-playbook site.yml"},{"instruction": "To check syntax before running, use", "command": "ansible-playbook --syntax-check site.yml"}]'
    answer_a="ansible-playbook site.yml"
    answer_b="ansible site.yml"
    answer_c="ansible-run site.yml"
    answer_d="ansible --playbook site.yml"
    ;;
  fr)
    question="Quelle commande est utilisée pour exécuter un playbook Ansible nommé \`site.yml\` situé dans le répertoire courant ?"
    hint="Ansible dispose d'une commande dédiée pour exécuter les playbooks — elle est différente de la commande ad-hoc \`ansible\`."
    instructions='[{"instruction": "Pour exécuter un playbook, utilisez", "command": "ansible-playbook site.yml"},{"instruction": "Pour vérifier la syntaxe avant d'\''exécuter, utilisez", "command": "ansible-playbook --syntax-check site.yml"}]'
    answer_a="ansible-playbook site.yml"
    answer_b="ansible site.yml"
    answer_c="ansible-run site.yml"
    answer_d="ansible --playbook site.yml"
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
  '{
    "question": $question,
    "type": "multi",
    "answers": {"answer_a": "ansible-playbook site.yml", "answer_b": "ansible site.yml", "answer_c": "ansible-run site.yml", "answer_d": "ansible --playbook site.yml"},
    "hint": $hint,
    "instructions": $instructions,
    "solution": $solution,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "ansible,rhce,playbook"
  }'
