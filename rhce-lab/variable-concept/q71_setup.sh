#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="This playbook runs without error but the msg always shows as undefined. What is the problem?\n\n---\n- name: display OS distribution\n  hosts: all\n  gather_facts: no\n  tasks:\n    - name: show distribution\n      debug:\n        msg: OS is {{ ansible_facts['distribution'] }}"
    hint="The playbook executes without crashing but the fact value is empty. Compare line 3 of the play header with what line 7 is trying to display."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">gather_facts: no</span> skips the implicit setup task, leaving ansible_facts empty for the entire play.\",
                    \"command\": \"# Fix option 1: remove gather_facts: no entirely\\n\\n# Fix option 2: add a manual setup task before the debug task\\n- name: gather facts\\n  setup:\"
                  },
                  {
                    \"instruction\": \"If you must skip facts globally for performance, run setup explicitly only where facts are needed.\",
                    \"command\": \"- name: display OS distribution\\n  hosts: all\\n  gather_facts: no\\n  tasks:\\n    - name: gather facts\\n      setup:\\n    - name: show distribution\\n      debug:\\n        msg: OS is {{ ansible_facts['distribution'] }}\"
                  }
                ]"
    answer_a="The debug module cannot use msg: with facts, it must use the var: argument"
    answer_b="The square bracket notation is incorrect and dotted notation must be used"
    answer_c="gather_facts: no disables fact collection but the task uses ansible_facts which requires it"  # Correct answer
    answer_d="The hosts: all value is invalid and must reference a named inventory group"
    ;;
  "fr")
    question="Ce playbook s'exécute sans erreur mais le msg affiche toujours undefined. Quel est le problème ?\n\n---\n- name: afficher la distribution OS\n  hosts: all\n  gather_facts: no\n  tasks:\n    - name: afficher la distribution\n      debug:\n        msg: OS est {{ ansible_facts['distribution'] }}"
    hint="Le playbook s'exécute sans planter mais la valeur du fait est vide. Comparez la ligne 3 de l'en-tête du play avec ce que la ligne 7 essaie d'afficher."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">gather_facts: no</span> ignore la tâche setup implicite, laissant ansible_facts vide pour tout le play.\",
                    \"command\": \"# Solution 1 : supprimer entièrement gather_facts: no\\n\\n# Solution 2 : ajouter une tâche setup manuelle avant la tâche debug\\n- name: collecter les faits\\n  setup:\"
                  },
                  {
                    \"instruction\": \"Si vous devez ignorer les faits globalement pour les performances, exécutez setup explicitement là où les faits sont nécessaires.\",
                    \"command\": \"- name: afficher la distribution OS\\n  hosts: all\\n  gather_facts: no\\n  tasks:\\n    - name: collecter les faits\\n      setup:\\n    - name: afficher la distribution\\n      debug:\\n        msg: OS est {{ ansible_facts['distribution'] }}\"
                  }
                ]"
    answer_a="Le module debug ne peut pas utiliser msg: avec les faits, il doit utiliser l'argument var:"
    answer_b="La notation entre crochets est incorrecte et la notation pointée doit être utilisée"
    answer_c="gather_facts: no désactive la collecte des faits mais la tâche utilise ansible_facts qui en a besoin"  # Correct answer
    answer_d="La valeur hosts: all est invalide et doit référencer un groupe d'inventaire nommé"
    ;;
  *)
    question="This playbook runs without error but the msg always shows as undefined. What is the problem?\n\n---\n- name: display OS distribution\n  hosts: all\n  gather_facts: no\n  tasks:\n    - name: show distribution\n      debug:\n        msg: OS is {{ ansible_facts['distribution'] }}"
    hint="The playbook executes without crashing but the fact value is empty. Compare line 3 of the play header with what line 7 is trying to display."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">gather_facts: no</span> skips the implicit setup task, leaving ansible_facts empty for the entire play.\",
                    \"command\": \"# Fix option 1: remove gather_facts: no entirely\\n\\n# Fix option 2: add a manual setup task before the debug task\\n- name: gather facts\\n  setup:\"
                  },
                  {
                    \"instruction\": \"If you must skip facts globally for performance, run setup explicitly only where facts are needed.\",
                    \"command\": \"- name: display OS distribution\\n  hosts: all\\n  gather_facts: no\\n  tasks:\\n    - name: gather facts\\n      setup:\\n    - name: show distribution\\n      debug:\\n        msg: OS is {{ ansible_facts['distribution'] }}\"
                  }
                ]"
    answer_a="The debug module cannot use msg: with facts, it must use the var: argument"
    answer_b="The square bracket notation is incorrect and dotted notation must be used"
    answer_c="gather_facts: no disables fact collection but the task uses ansible_facts which requires it"  # Correct answer
    answer_d="The hosts: all value is invalid and must reference a named inventory group"
    ;;
esac

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers to avoid predictable order
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the display JSON
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": {
    '"$shuffled_answers"'
  },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$answer_c"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
