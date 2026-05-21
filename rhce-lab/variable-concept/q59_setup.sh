#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

cmd1="ansible --version | head -2"
answer_a="2.9.2"
answer_b="2.14.1"
answer_c="2.16.2"
answer_d="2.20.1"
solution="$answer_d"

case "$lang" in
  en)
    question="What is the version of Ansible installed on the control node?"
    hint="Run 'ansible --version' in the terminal — the version appears on the first line of the output."
    inst1="Run this command to discover the exact Ansible version installed on the control node:"
    ;;
  fr)
    question="Quelle est la version d'Ansible installée sur le nœud de contrôle ?"
    hint="Exécutez 'ansible --version' dans le terminal — la version apparaît sur la première ligne de la sortie."
    inst1="Exécutez cette commande pour découvrir la version exacte d'Ansible installée sur le nœud de contrôle :"
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
    "os_required": "ubuntu"
  }'
