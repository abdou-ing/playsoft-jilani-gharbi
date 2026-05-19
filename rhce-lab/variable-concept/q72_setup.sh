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
    question="Which command would you run on the control node to verify that custom facts are properly loaded on ALL managed hosts?"
    hint="Try each option on your control node. The correct command uses the setup module with a specific filter argument that targets custom facts only."
    instructions="[
                  {
                    \"instruction\": \"Run the command on your control node and observe the output. Custom facts are stored under the <span class=\\\"bold-green-text\\\">ansible_local</span> key.\",
                    \"command\": \"ansible all -m setup -a \\\"filter=ansible_local\\\"\"
                  },
                  {
                    \"instruction\": \"The output will show the contents of every .fact file found in /etc/ansible/facts.d on each host.\",
                    \"command\": \"# Example output:\\nansible1 | SUCCESS => {\\n    \\\"ansible_facts\\\": {\\n        \\\"ansible_local\\\": {\\n            \\\"custom\\\": {\\n                \\\"software\\\": {\\n                    \\\"package\\\": \\\"httpd\\\"\\n                }\\n            }\\n        }\\n    }\\n}\"
                  }
                ]"
    answer_a="ansible all -m debug -a 'var=ansible_facts'"
    answer_b="ansible all -m setup -a 'filter=ansible_facts[ansible_local]'"
    answer_c="ansible-playbook --check facts.yml"
    answer_d="ansible all -m setup -a 'filter=ansible_local'"  # Correct answer
    ;;
  "fr")
    question="Quelle commande exécuteriez-vous sur le nœud de contrôle pour vérifier que les faits personnalisés sont correctement chargés sur TOUS les hôtes gérés ?"
    hint="Essayez chaque option sur votre nœud de contrôle. La bonne commande utilise le module setup avec un argument filter spécifique qui cible uniquement les faits personnalisés."
    instructions="[
                  {
                    \"instruction\": \"Exécutez la commande sur votre nœud de contrôle et observez la sortie. Les faits personnalisés sont stockés sous la clé <span class=\\\"bold-green-text\\\">ansible_local</span>.\",
                    \"command\": \"ansible all -m setup -a \\\"filter=ansible_local\\\"\"
                  },
                  {
                    \"instruction\": \"La sortie affichera le contenu de chaque fichier .fact trouvé dans /etc/ansible/facts.d sur chaque hôte.\",
                    \"command\": \"# Exemple de sortie :\\nansible1 | SUCCESS => {\\n    \\\"ansible_facts\\\": {\\n        \\\"ansible_local\\\": {\\n            \\\"custom\\\": {\\n                \\\"software\\\": {\\n                    \\\"package\\\": \\\"httpd\\\"\\n                }\\n            }\\n        }\\n    }\\n}\"
                  }
                ]"
    answer_a="ansible all -m debug -a 'var=ansible_facts'"
    answer_b="ansible all -m setup -a 'filter=ansible_facts[ansible_local]'"
    answer_c="ansible-playbook --check facts.yml"
    answer_d="ansible all -m setup -a 'filter=ansible_local'"  # Correct answer
    ;;
  *)
    question="Which command would you run on the control node to verify that custom facts are properly loaded on ALL managed hosts?"
    hint="Try each option on your control node. The correct command uses the setup module with a specific filter argument that targets custom facts only."
    instructions="[
                  {
                    \"instruction\": \"Run the command on your control node and observe the output. Custom facts are stored under the <span class=\\\"bold-green-text\\\">ansible_local</span> key.\",
                    \"command\": \"ansible all -m setup -a \\\"filter=ansible_local\\\"\"
                  },
                  {
                    \"instruction\": \"The output will show the contents of every .fact file found in /etc/ansible/facts.d on each host.\",
                    \"command\": \"# Example output:\\nansible1 | SUCCESS => {\\n    \\\"ansible_facts\\\": {\\n        \\\"ansible_local\\\": {\\n            \\\"custom\\\": {\\n                \\\"software\\\": {\\n                    \\\"package\\\": \\\"httpd\\\"\\n                }\\n            }\\n        }\\n    }\\n}\"
                  }
                ]"
    answer_a="ansible all -m debug -a 'var=ansible_facts'"
    answer_b="ansible all -m setup -a 'filter=ansible_facts[ansible_local]'"
    answer_c="ansible-playbook --check facts.yml"
    answer_d="ansible all -m setup -a 'filter=ansible_local'"  # Correct answer
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
