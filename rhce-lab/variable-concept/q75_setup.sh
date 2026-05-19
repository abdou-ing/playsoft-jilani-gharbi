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
    question="Which ansible command lets you verify whether user 'charlie' exists on ALL managed hosts?"
    hint="Try each command on your control node. The correct one runs a native Linux command on every host and returns the result for each."
    instructions="[
                  {
                    \"instruction\": \"Use the <span class=\\\"bold-green-text\\\">command</span> module with <span class=\\\"bold-green-text\\\">id charlie</span> to probe each host. A SUCCESS result means the user exists; a FAILED result means it does not.\",
                    \"command\": \"ansible all -m command -a 'id charlie'\"
                  },
                  {
                    \"instruction\": \"Compare the output across hosts to identify on which server charlie exists.\",
                    \"command\": \"# charlie exists on ansible1:\\nansible1 | CHANGED | rc=0 >>\\nuid=1001(charlie) gid=1001(charlie) groups=1001(charlie)\\n\\n# charlie does not exist on ansible2:\\nansible2 | FAILED | rc=1 >>\\nid: charlie: no such user\"
                  }
                ]"
    answer_a="ansible all -m user -a 'name=charlie state=present'"
    answer_b="ansible all -u charlie -m ping"
    answer_c="ansible all -m setup -a 'filter=ansible_user_id'"
    answer_d="ansible all -m command -a 'id charlie'"  # Correct answer
    ;;
  "fr")
    question="Quelle commande ansible permet de vérifier si l'utilisateur 'charlie' existe sur TOUS les hôtes gérés ?"
    hint="Essayez chaque commande sur votre nœud de contrôle. La bonne exécute une commande Linux native sur chaque hôte et retourne le résultat pour chacun."
    instructions="[
                  {
                    \"instruction\": \"Utilisez le module <span class=\\\"bold-green-text\\\">command</span> avec <span class=\\\"bold-green-text\\\">id charlie</span> pour interroger chaque hôte. Un résultat SUCCESS signifie que l'utilisateur existe ; un résultat FAILED signifie qu'il n'existe pas.\",
                    \"command\": \"ansible all -m command -a 'id charlie'\"
                  },
                  {
                    \"instruction\": \"Comparez la sortie entre les hôtes pour identifier sur quel serveur charlie existe.\",
                    \"command\": \"# charlie existe sur ansible1 :\\nansible1 | CHANGED | rc=0 >>\\nuid=1001(charlie) gid=1001(charlie) groups=1001(charlie)\\n\\n# charlie n'existe pas sur ansible2 :\\nansible2 | FAILED | rc=1 >>\\nid: charlie: no such user\"
                  }
                ]"
    answer_a="ansible all -m user -a 'name=charlie state=present'"
    answer_b="ansible all -u charlie -m ping"
    answer_c="ansible all -m setup -a 'filter=ansible_user_id'"
    answer_d="ansible all -m command -a 'id charlie'"  # Correct answer
    ;;
  *)
    question="Which ansible command lets you verify whether user 'charlie' exists on ALL managed hosts?"
    hint="Try each command on your control node. The correct one runs a native Linux command on every host and returns the result for each."
    instructions="[
                  {
                    \"instruction\": \"Use the <span class=\\\"bold-green-text\\\">command</span> module with <span class=\\\"bold-green-text\\\">id charlie</span> to probe each host. A SUCCESS result means the user exists; a FAILED result means it does not.\",
                    \"command\": \"ansible all -m command -a 'id charlie'\"
                  },
                  {
                    \"instruction\": \"Compare the output across hosts to identify on which server charlie exists.\",
                    \"command\": \"# charlie exists on ansible1:\\nansible1 | CHANGED | rc=0 >>\\nuid=1001(charlie) gid=1001(charlie) groups=1001(charlie)\\n\\n# charlie does not exist on ansible2:\\nansible2 | FAILED | rc=1 >>\\nid: charlie: no such user\"
                  }
                ]"
    answer_a="ansible all -m user -a 'name=charlie state=present'"
    answer_b="ansible all -u charlie -m ping"
    answer_c="ansible all -m setup -a 'filter=ansible_user_id'"
    answer_d="ansible all -m command -a 'id charlie'"  # Correct answer
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
  "solution": "'"$answer_d"'",
  "plateforme_required": "container",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
