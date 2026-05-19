#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="Which of the following groups are defined in the configured Ansible inventory?"
    hint="Use 'ansible-inventory' to inspect the inventory structure."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to list all groups in the Ansible inventory.\",
                    \"command\": \"ansible-inventory --list\"
                  },
                  {
                    \"instruction\": \"The output will show the groups and their associated hosts.\",
                    \"command\": \"ansible-inventory --graph\"
                  }
                ]"
    ;;
  "fr")
    question="Quels sont les groupes définis dans l'inventaire Ansible configuré ?"
    hint="Utilisez 'ansible-inventory' pour inspecter la structure de l'inventaire."
    instructions="[
                  {
                    \"instruction\": \"Exécutez la commande suivante pour lister tous les groupes dans l'inventaire Ansible.\",
                    \"command\": \"ansible-inventory --list\"
                  },
                  {
                    \"instruction\": \"La sortie affichera les groupes et leurs hôtes associés.\",
                    \"command\": \"ansible-inventory --graph\"
                  }
                ]"
    ;;
  "es")
    question="¿Cuáles de los siguientes grupos están definidos en el inventario configurado de Ansible?"
    hint="Usa 'ansible-inventory' para inspeccionar la estructura del inventario."
    instructions="[
                  {
                    \"instruction\": \"Ejecuta el siguiente comando para listar todos los grupos en el inventario de Ansible.\",
                    \"command\": \"ansible-inventory --list\"
                  },
                  {
                    \"instruction\": \"La salida mostrará los grupos y sus hosts asociados.\",
                    \"command\": \"ansible-inventory --graph\"
                  }
                ]"
    ;;
  "it")
    question="Quali dei seguenti gruppi sono definiti nell'inventario configurato di Ansible?"
    hint="Usa 'ansible-inventory' per ispezionare la struttura dell'inventario."
    instructions="[
                  {
                    \"instruction\": \"Esegui il seguente comando per elencare tutti i gruppi nell'inventario di Ansible.\",
                    \"command\": \"ansible-inventory --list\"
                  },
                  {
                    \"instruction\": \"L'output mostrerà i gruppi e i loro host associati.\",
                    \"command\": \"ansible-inventory --graph\"
                  }
                ]"
    ;;
  "de")
    question="Welche der folgenden Gruppen sind im konfigurierten Ansible-Inventar definiert?"
    hint="Verwenden Sie 'ansible-inventory', um die Inventarstruktur zu überprüfen."
    instructions="[
                  {
                    \"instruction\": \"Führen Sie den folgenden Befehl aus, um alle Gruppen im Ansible-Inventar aufzulisten.\",
                    \"command\": \"ansible-inventory --list\"
                  },
                  {
                    \"instruction\": \"Die Ausgabe zeigt die Gruppen und ihre zugehörigen Hosts.\",
                    \"command\": \"ansible-inventory --graph\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="Which of the following groups are defined in the configured Ansible inventory?"
    hint="Use 'ansible-inventory' to inspect the inventory structure."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to list all groups in the Ansible inventory.\",
                    \"command\": \"ansible-inventory --list\"
                  },
                  {
                    \"instruction\": \"The output will show the groups and their associated hosts.\",
                    \"command\": \"ansible-inventory --graph\"
                  }
                ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  groups="Ansible not installed"
  answer_a="webservers"
  answer_b="dbservers"
  answer_c="Ansible not installed"
  answer_d="loadbalancers"
  correct_answer="Ansible not installed"
else
  # Fetch groups from the inventory
  # Execute the groups command as ansible_user
  groups=$(sudo -u ansible_user bash -c "ansible-inventory --list 2>/dev/null | jq -r 'keys[]' | grep -v '^_' | tr '\n' ', ' | sed 's/, \$//'" || echo "No groups found")

  correct_answer="$groups"

  # Generate distractor answers
  # Select distractors from plausible group names
  answer_a="webservers"
  answer_b="dbservers"
  answer_c="$correct_answer"
  answer_d="loadbalancers"
fi

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
  "solution": "'"$correct_answer"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .