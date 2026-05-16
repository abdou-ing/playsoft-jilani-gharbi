#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="In modern RHEL/CentOS systems, the Ansible package was split. Which package name should you install to get the core Ansible engine and the \`ansible\` command?"
    hint="The old \`ansible\` package became \`ansible-core\` starting from Ansible 2.10. The \`ansible\` package now refers to a larger community collection bundle."
    instructions='[{"instruction": "To install the core Ansible engine on RHEL/CentOS, use", "command": "sudo yum install ansible-core"}]'
    answer_a="ansible-core"
    answer_b="ansible"
    answer_c="ansible-base"
    answer_d="ansible-engine"
    # change to a quizz
    
    ;;
  fr)
    question="Sur les systèmes RHEL/CentOS modernes, le paquet Ansible a été divisé. Quel nom de paquet faut-il installer pour obtenir le moteur Ansible et la commande \`ansible\` ?"
    hint="L'ancien paquet \`ansible\` est devenu \`ansible-core\` à partir d'Ansible 2.10. Le paquet \`ansible\` désigne désormais un bundle de collections communautaires plus large."
    instructions='[{"instruction": "Pour installer le moteur Ansible sur RHEL/CentOS, utilisez", "command": "sudo yum install ansible-core"}]'
    answer_a="ansible-core"
    answer_b="ansible"
    answer_c="ansible-base"
    answer_d="ansible-engine"
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
    "type": "multi",
    "answers": ($shuffled | split(",") | map(split(":") | {(.[0] | ltrimstr("\"") | rtrimstr("\"")): (.[1] | ltrimstr("\"") | rtrimstr("\""))}) | add),
    "hint": $hint,
    "instructions": $instructions,
    "solution": $solution,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "ansible,rhce"
  }'
