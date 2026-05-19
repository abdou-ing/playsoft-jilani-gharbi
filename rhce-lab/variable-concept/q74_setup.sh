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
    question="Which ansible command would you run to find the OS distribution of ALL managed hosts without writing a playbook?"
    hint="Try each command on your control node. One of them uses the setup module with a filter that targets only the distribution fact."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">setup</span> module collects all facts. Use the <span class=\\\"bold-green-text\\\">filter</span> argument to narrow down to a specific fact name.\",
                    \"command\": \"ansible all -m setup -a 'filter=ansible_distribution'\"
                  },
                  {
                    \"instruction\": \"The output shows the OS distribution for each host. You can also use <span class=\\\"bold-green-text\\\">ansible_distribution_version</span> or <span class=\\\"bold-green-text\\\">ansible_os_family</span> as filter values.\",
                    \"command\": \"# Example output:\\nansible1 | SUCCESS => {\\n    \\\"ansible_facts\\\": {\\n        \\\"ansible_distribution\\\": \\\"RedHat\\\"\\n    }\\n}\"
                  }
                ]"
    answer_a="ansible all -m debug -a 'var=ansible_distribution'"
    answer_b="ansible all -m setup -a 'filter=ansible_os_family'"
    answer_c="ansible all -m setup -a 'filter=ansible_distribution'"  # Correct answer
    answer_d="ansible-playbook -e 'gather_facts=yes' site.yml"
    ;;
  "fr")
    question="Quelle commande ansible exécuteriez-vous pour trouver la distribution OS de TOUS les hôtes gérés sans écrire de playbook ?"
    hint="Essayez chaque commande sur votre nœud de contrôle. L'une d'elles utilise le module setup avec un filtre qui cible uniquement le fait distribution."
    instructions="[
                  {
                    \"instruction\": \"Le module <span class=\\\"bold-green-text\\\">setup</span> collecte tous les faits. Utilisez l'argument <span class=\\\"bold-green-text\\\">filter</span> pour cibler un nom de fait spécifique.\",
                    \"command\": \"ansible all -m setup -a 'filter=ansible_distribution'\"
                  },
                  {
                    \"instruction\": \"La sortie affiche la distribution OS pour chaque hôte. Vous pouvez aussi utiliser <span class=\\\"bold-green-text\\\">ansible_distribution_version</span> ou <span class=\\\"bold-green-text\\\">ansible_os_family</span> comme valeurs de filtre.\",
                    \"command\": \"# Exemple de sortie :\\nansible1 | SUCCESS => {\\n    \\\"ansible_facts\\\": {\\n        \\\"ansible_distribution\\\": \\\"RedHat\\\"\\n    }\\n}\"
                  }
                ]"
    answer_a="ansible all -m debug -a 'var=ansible_distribution'"
    answer_b="ansible all -m setup -a 'filter=ansible_os_family'"
    answer_c="ansible all -m setup -a 'filter=ansible_distribution'"  # Correct answer
    answer_d="ansible-playbook -e 'gather_facts=yes' site.yml"
    ;;
  *)
    question="Which ansible command would you run to find the OS distribution of ALL managed hosts without writing a playbook?"
    hint="Try each command on your control node. One of them uses the setup module with a filter that targets only the distribution fact."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">setup</span> module collects all facts. Use the <span class=\\\"bold-green-text\\\">filter</span> argument to narrow down to a specific fact name.\",
                    \"command\": \"ansible all -m setup -a 'filter=ansible_distribution'\"
                  },
                  {
                    \"instruction\": \"The output shows the OS distribution for each host. You can also use <span class=\\\"bold-green-text\\\">ansible_distribution_version</span> or <span class=\\\"bold-green-text\\\">ansible_os_family</span> as filter values.\",
                    \"command\": \"# Example output:\\nansible1 | SUCCESS => {\\n    \\\"ansible_facts\\\": {\\n        \\\"ansible_distribution\\\": \\\"RedHat\\\"\\n    }\\n}\"
                  }
                ]"
    answer_a="ansible all -m debug -a 'var=ansible_distribution'"
    answer_b="ansible all -m setup -a 'filter=ansible_os_family'"
    answer_c="ansible all -m setup -a 'filter=ansible_distribution'"  # Correct answer
    answer_d="ansible-playbook -e 'gather_facts=yes' site.yml"
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
  "plateforme_required": "container",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
