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
    question="How can you test the syntax of an Ansible playbook without executing it?"
    hint="Think about the command-line options available in Ansible to validate playbooks."
    instructions="[
                  {
                    \"instruction\": \"Use the 'ansible-playbook' command with the '--syntax-check' option to validate the syntax of a playbook without running it.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  },
                  {
                    \"instruction\": \"This helps catch errors in the playbook before execution.\",
                    \"command\": \"ansible-playbook --syntax-check another-playbook.yml\"
                  }
                ]"
    answer_a="Run 'ansible-playbook' with the '--check' option."
    answer_b="Run 'ansible-playbook' with the '--syntax-check' option."  # Correct answer
    answer_c="Run 'ansible-lint' on the playbook file."
    answer_d="Execute the playbook; syntax errors will stop execution."
    ;;
  "it")
    question="Come puoi verificare la sintassi di un playbook Ansible senza eseguirlo?"
    hint="Pensa alle opzioni della riga di comando disponibili in Ansible per convalidare i playbook."
    instructions="[
                  {
                    \"instruction\": \"Usa il comando 'ansible-playbook' con l'opzione '--syntax-check' per verificare la sintassi di un playbook senza eseguirlo.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Questo aiuta a rilevare errori nel playbook prima dell'esecuzione.\",
                    \"command\": \"ansible-playbook --syntax-check another-playbook.yml\"
                  }
                ]"
    answer_a="Esegui 'ansible-playbook' con l'opzione '--check'."
    answer_b="Esegui 'ansible-playbook' con l'opzione '--syntax-check'."  # Correct answer
    answer_c="Esegui 'ansible-lint' sul file del playbook."
    answer_d="Esegui il playbook; gli errori di sintassi interromperanno l'esecuzione."
    ;;
  "de")
    question="Wie können Sie die Syntax eines Ansible-Playbooks testen, ohne es auszuführen?"
    hint="Denken Sie an die Befehlszeilenoptionen, die in Ansible zum Überprüfen von Playbooks verfügbar sind."
    instructions="[
                  {
                    \"instruction\": \"Verwenden Sie den Befehl 'ansible-playbook' mit der Option '--syntax-check', um die Syntax eines Playbooks zu überprüfen, ohne es auszuführen.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Dies hilft, Fehler im Playbook vor der Ausführung zu erkennen.\",
                    \"command\": \"ansible-playbook --syntax-check another-playbook.yml\"
                  }
                ]"
    answer_a="Führen Sie 'ansible-playbook' mit der Option '--check' aus."
    answer_b="Führen Sie 'ansible-playbook' mit der Option '--syntax-check' aus."  # Correct answer
    answer_c="Führen Sie 'ansible-lint' auf der Playbook-Datei aus."
    answer_d="Führen Sie das Playbook aus; Syntaxfehler stoppen die Ausführung."
    ;;
  "fr")
    question="Comment tester la syntaxe d'un playbook Ansible sans l'exécuter ?"
    hint="Pensez aux options de ligne de commande disponibles dans Ansible pour valider les playbooks."
    instructions="[
                  {
                    \"instruction\": \"Utilisez la commande 'ansible-playbook' avec l'option '--syntax-check' pour valider la syntaxe d'un playbook sans l'exécuter.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Cela permet de détecter les erreurs avant l'exécution.\",
                    \"command\": \"ansible-playbook --syntax-check another-playbook.yml\"
                  }
                ]"
    answer_a="Utilisez 'ansible-playbook' avec l'option '--check'."
    answer_b="Utilisez 'ansible-playbook' avec l'option '--syntax-check'."  # Correct answer
    answer_c="Exécutez 'ansible-lint' sur le fichier playbook."
    answer_d="Exécutez le playbook ; les erreurs de syntaxe arrêteront l'exécution."
    ;;
  "es")
    question="¿Cómo puedes probar la sintaxis de un playbook de Ansible sin ejecutarlo?"
    hint="Piensa en las opciones de línea de comandos disponibles en Ansible para validar playbooks."
    instructions="[
                  {
                    \"instruction\": \"Usa el comando 'ansible-playbook' con la opción '--syntax-check' para validar la sintaxis de un playbook sin ejecutarlo.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Esto ayuda a detectar errores antes de la ejecución.\",
                    \"command\": \"ansible-playbook --syntax-check another-playbook.yml\"
                  }
                ]"
    answer_a="Ejecuta 'ansible-playbook' con la opción '--check'."
    answer_b="Ejecuta 'ansible-playbook' con la opción '--syntax-check'."  # Correct answer
    answer_c="Ejecuta 'ansible-lint' en el archivo del playbook."
    answer_d="Ejecuta el playbook; los errores de sintaxis detendrán la ejecución."
    ;;
  *)
    # Default to English if the language is not supported
    question="How can you test the syntax of an Ansible playbook without executing it?"
    hint="Think about the command-line options available in Ansible to validate playbooks."
    instructions="[
                  {
                    \"instruction\": \"Use the 'ansible-playbook' command with the '--syntax-check' option to validate the syntax of a playbook without running it.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  },
                  {
                    \"instruction\": \"This helps catch errors in the playbook before execution.\",
                    \"command\": \"ansible-playbook --syntax-check another-playbook.yml\"
                  }
                ]"
    answer_a="Run 'ansible-playbook' with the '--check' option."
    answer_b="Run 'ansible-playbook' with the '--syntax-check' option."  # Correct answer
    answer_c="Run 'ansible-lint' on the playbook file."
    answer_d="Execute the playbook; syntax errors will stop execution."
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
  "solution": "'"$answer_b"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
