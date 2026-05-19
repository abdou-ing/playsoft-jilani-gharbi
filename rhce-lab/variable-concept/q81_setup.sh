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
    question="Which command displays the installed Ansible version on the control node?"
    hint="Try each command on your control node. The correct one prints the version number and the Python path Ansible is using."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible --version</span> prints the installed version along with the config file location and Python path.\",
                    \"command\": \"ansible --version\\n# Example output:\\nansible [core 2.16.3]\\n  config file = /home/admin/ansible/ansible.cfg\\n  python version = 3.11.2\"
                  },
                  {
                    \"instruction\": \"Always check the version first on a new control node to know which modules and features are available.\",
                    \"command\": \"# Also useful to verify which ansible.cfg is being loaded:\\nansible --version | grep 'config file'\"
                  }
                ]"
    answer_a="ansible -v"
    answer_b="ansible-version"
    answer_c="ansible info"
    answer_d="ansible --version"  # Correct answer
    ;;
  "fr")
    question="Quelle commande affiche la version d'Ansible installée sur le nœud de contrôle ?"
    hint="Essayez chaque commande sur votre nœud de contrôle. La bonne affiche le numéro de version et le chemin Python qu'Ansible utilise."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible --version</span> affiche la version installée ainsi que l'emplacement du fichier de configuration et le chemin Python.\",
                    \"command\": \"ansible --version\\n# Exemple de sortie :\\nansible [core 2.16.3]\\n  config file = /home/admin/ansible/ansible.cfg\\n  python version = 3.11.2\"
                  },
                  {
                    \"instruction\": \"Vérifiez toujours la version en premier sur un nouveau nœud de contrôle pour savoir quels modules et fonctionnalités sont disponibles.\",
                    \"command\": \"# Utile aussi pour vérifier quel ansible.cfg est chargé :\\nansible --version | grep 'config file'\"
                  }
                ]"
    answer_a="ansible -v"
    answer_b="ansible-version"
    answer_c="ansible info"
    answer_d="ansible --version"  # Correct answer
    ;;
  *)
    question="Which command displays the installed Ansible version on the control node?"
    hint="Try each command on your control node. The correct one prints the version number and the Python path Ansible is using."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible --version</span> prints the installed version along with the config file location and Python path.\",
                    \"command\": \"ansible --version\\n# Example output:\\nansible [core 2.16.3]\\n  config file = /home/admin/ansible/ansible.cfg\\n  python version = 3.11.2\"
                  },
                  {
                    \"instruction\": \"Always check the version first on a new control node to know which modules and features are available.\",
                    \"command\": \"# Also useful to verify which ansible.cfg is being loaded:\\nansible --version | grep 'config file'\"
                  }
                ]"
    answer_a="ansible -v"
    answer_b="ansible-version"
    answer_c="ansible info"
    answer_d="ansible --version"  # Correct answer
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
