#!/bin/bash

# Enable debugging if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Create a temporary inventory file
TEMP_INVENTORY="/tmp/temp_ansible_inventory"
TEMP_GROUP="temporary_group"

cat > "$TEMP_INVENTORY" <<EOL
[$TEMP_GROUP]
host1 ansible_host=192.168.1.1
host2 ansible_host=192.168.1.2

[other_group]
host3 ansible_host=192.168.1.3
host4 ansible_host=192.168.1.4
host5 ansible_host=192.168.1.5
EOL

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="Which hosts belong to the group '$TEMP_GROUP' in the inventory file $TEMP_INVENTORY?"
    hint="Use 'ansible-inventory' to inspect the group."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to list all groups and their hosts in the inventory.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --list\"
                  },
                  {
                    \"instruction\": \"The output will show the groups and their associated hosts.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --graph\"
                  }
                ]"
    ;;
  "fr")
    question="Quels hôtes appartiennent au groupe '$TEMP_GROUP' dans le fichier d'inventaire $TEMP_INVENTORY ?"
    hint="Utilisez 'ansible-inventory' pour inspecter le groupe."
    instructions="[
                  {
                    \"instruction\": \"Exécutez la commande suivante pour lister tous les groupes et leurs hôtes dans l'inventaire.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --list\"
                  },
                  {
                    \"instruction\": \"La sortie affichera les groupes et leurs hôtes associés.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --graph\"
                  }
                ]"
    ;;
  "es")
    question="¿Qué hosts pertenecen al grupo '$TEMP_GROUP' en el archivo de inventario $TEMP_INVENTORY?"
    hint="Usa 'ansible-inventory' para inspeccionar el grupo."
    instructions="[
                  {
                    \"instruction\": \"Ejecuta el siguiente comando para listar todos los grupos y sus hosts en el inventario.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --list\"
                  },
                  {
                    \"instruction\": \"La salida mostrará los grupos y sus hosts asociados.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --graph\"
                  }
                ]"
    ;;
  "it")
    question="Quali host appartengono al gruppo '$TEMP_GROUP' nel file di inventario $TEMP_INVENTORY?"
    hint="Usa 'ansible-inventory' per ispezionare il gruppo."
    instructions="[
                  {
                    \"instruction\": \"Esegui il seguente comando per elencare tutti i gruppi e i loro host nell'inventario.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --list\"
                  },
                  {
                    \"instruction\": \"L'output mostrerà i gruppi e i loro host associati.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --graph\"
                  }
                ]"
    ;;
  "de")
    question="Welche Hosts gehören zur Gruppe '$TEMP_GROUP' in der Inventardatei $TEMP_INVENTORY?"
    hint="Verwenden Sie 'ansible-inventory', um die Gruppe zu inspizieren."
    instructions="[
                  {
                    \"instruction\": \"Führen Sie den folgenden Befehl aus, um alle Gruppen und deren Hosts im Inventar aufzulisten.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --list\"
                  },
                  {
                    \"instruction\": \"Die Ausgabe zeigt die Gruppen und ihre zugehörigen Hosts.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --graph\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="Which hosts belong to the group '$TEMP_GROUP' in the inventory file $TEMP_INVENTORY?"
    hint="Use 'ansible-inventory' to inspect the group."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to list all groups and their hosts in the inventory.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --list\"
                  },
                  {
                    \"instruction\": \"The output will show the groups and their associated hosts.\",
                    \"command\": \"ansible-inventory -i /tmp/temp_ansible_inventory --graph\"
                  }
                ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible-inventory &>/dev/null; then
  correct_answer="Ansible not installed"
  answer_a="host4, host5"
  answer_b="host1, host2"
  answer_c="host1, host4"
  answer_d="host2, host5"
else
  # Get the correct answer dynamically
  correct_answer=$(sudo -u ansible_user ansible-inventory -i "$TEMP_INVENTORY" --list 2>/dev/null | jq -r ".\"$TEMP_GROUP\".hosts | join(\", \")" || echo "No hosts found")
  
  # Generate distractor answers
  answer_a="host4, host5"
  answer_b="$correct_answer"
  answer_c="host1, host4"
  answer_d="host2, host5"
fi

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers to avoid predictable order
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the JSON output
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": {
    '"$shuffled_answers"'
  },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$correct_answer"'",
  "platform_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
