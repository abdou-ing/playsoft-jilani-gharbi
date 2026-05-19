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

# List of possible shells
shells=("/bin/bash" "/bin/ksh" "/bin/sh" "/bin/zsh")

# Randomly select one shell as the default
default_shell=${shells[$RANDOM % ${#shells[@]}]}

# Update the Ansible inventory file with the selected default shell
# Use '|' as the delimiter in the sed command to avoid conflicts with '/'
sudo sed -i "s|^web1.*|web1 shell_default=$default_shell|" /etc/ansible/hosts

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="What is the value of the variable 'shell_default' for the host 'web1'?"
    hint="Use 'ansible-inventory' to inspect the variables assigned to hosts."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to inspect the variables for the host 'web1'.\",
                    \"command\": \"ansible-inventory --host web1\"
                  },
                  {
                    \"instruction\": \"The output will show the variables assigned to the host, including 'shell_default'.\",
                    \"command\": \"ansible-inventory --host web1 | jq .\"
                  }
                ]"
    ;;
  "fr")
    question="Quelle est la valeur de la variable 'shell_default' pour l'hôte 'web1' ?"
    hint="Utilisez 'ansible-inventory' pour inspecter les variables attribuées aux hôtes."
    instructions="[
                  {
                    \"instruction\": \"Exécutez la commande suivante pour inspecter les variables de l'hôte 'web1'.\",
                    \"command\": \"ansible-inventory --host web1\"
                  },
                  {
                    \"instruction\": \"La sortie affichera les variables attribuées à l'hôte, y compris 'shell_default'.\",
                    \"command\": \"ansible-inventory --host web1 | jq .\"
                  }
                ]"
    ;;
  "es")
    question="¿Cuál es el valor de la variable 'shell_default' para el host 'web1'?"
    hint="Usa 'ansible-inventory' para inspeccionar las variables asignadas a los hosts."
    instructions="[
                  {
                    \"instruction\": \"Ejecuta el siguiente comando para inspeccionar las variables del host 'web1'.\",
                    \"command\": \"ansible-inventory --host web1\"
                  },
                  {
                    \"instruction\": \"La salida mostrará las variables asignadas al host, incluyendo 'shell_default'.\",
                    \"command\": \"ansible-inventory --host web1 | jq .\"
                  }
                ]"
    ;;
  "it")
    question="Qual è il valore della variabile 'shell_default' per l'host 'web1'?"
    hint="Usa 'ansible-inventory' per ispezionare le variabili assegnate agli host."
    instructions="[
                  {
                    \"instruction\": \"Esegui il seguente comando per ispezionare le variabili dell'host 'web1'.\",
                    \"command\": \"ansible-inventory --host web1\"
                  },
                  {
                    \"instruction\": \"L'output mostrerà le variabili assegnate all'host, inclusa 'shell_default'.\",
                    \"command\": \"ansible-inventory --host web1 | jq .\"
                  }
                ]"
    ;;
  "de")
    question="Was ist der Wert der Variable 'shell_default' für den Host 'web1'?"
    hint="Verwenden Sie 'ansible-inventory', um die Variablen zu überprüfen, die den Hosts zugewiesen sind."
    instructions="[
                  {
                    \"instruction\": \"Führen Sie den folgenden Befehl aus, um die Variablen für den Host 'web1' zu überprüfen.\",
                    \"command\": \"ansible-inventory --host web1\"
                  },
                  {
                    \"instruction\": \"Die Ausgabe zeigt die dem Host zugewiesenen Variablen, einschließlich 'shell_default'.\",
                    \"command\": \"ansible-inventory --host web1 | jq .\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the value of the variable 'shell_default' for the host 'web1'?"
    hint="Use 'ansible-inventory' to inspect the variables assigned to hosts."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to inspect the variables for the host 'web1'.\",
                    \"command\": \"ansible-inventory --host web1\"
                  },
                  {
                    \"instruction\": \"The output will show the variables assigned to the host, including 'shell_default'.\",
                    \"command\": \"ansible-inventory --host web1 | jq .\"
                  }
                ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  variable_value="Ansible not installed"
  answer_a="/bin/bash"
  answer_b="/bin/ksh"
  answer_c="/bin/sh"
  answer_d="Ansible not installed"
  correct_answer="Ansible not installed"
else
  # Fetch variable value for the host 'web1'
  variable_value=$(ansible-inventory --host web1 2>/dev/null | jq -r '.shell_default // "No value set"')
  correct_answer="$variable_value"

  # Generate distractor answers (the remaining shells)
  distractors=()
  for shell in "${shells[@]}"; do
    if [[ "$shell" != "$default_shell" ]]; then
      distractors+=("$shell")
    fi
  done

  # Assign distractor answers
  answer_a="${distractors[0]}"
  answer_b="${distractors[1]}"
  answer_c="${distractors[2]}"
  answer_d="$default_shell"
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