#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="How do you reference a variable named \`username\` inside an Ansible task?"
    hint="Ansible uses Jinja2 templating syntax to reference variables. The variable name is wrapped in double curly braces."
    instructions='[{"instruction": "Define a variable in the vars: section, then use it in a task:", "command": "vars:\n  username: alice\ntasks:\n  - name: Create user\n    user:\n      name: \"{{ username }}\""}]'
    answer_a="{{ username }}"
    answer_b="$username"
    answer_c="%username%"
    answer_d="[username]"
    ;;
  fr)
    question="Comment référencer une variable nommée \`username\` dans une tâche Ansible ?"
    hint="Ansible utilise la syntaxe de templating Jinja2 pour référencer les variables. Le nom de la variable est entouré de doubles accolades."
    instructions='[{"instruction": "Définissez une variable dans la section vars:, puis utilisez-la dans une tâche :", "command": "vars:\n  username: alice\ntasks:\n  - name: Créer utilisateur\n    user:\n      name: \"{{ username }}\""}]'
    answer_a="{{ username }}"
    answer_b="$username"
    answer_c="%username%"
    answer_d="[username]"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --argjson instructions "$instructions" \
  --arg solution "$answer_a" \
  '{
    "question": $question,
    "type": "multi",
    "answers": {
      "answer_a": "{{ username }}",
      "answer_b": "$username",
      "answer_c": "%username%",
      "answer_d": "[username]"
    },
    "hint": $hint,
    "instructions": $instructions,
    "solution": $solution,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "ansible,rhce,variables,jinja2,beginner"
  }'
