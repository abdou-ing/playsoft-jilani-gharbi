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
    question="What is the default behavior of Ansible when it encounters an error in a task?"
    hint="Think about how Ansible treats task failures by default."
    instructions="[
                  {
                    \"instruction\": \"By default, Ansible stops execution of the playbook when it encounters an error in a task.\",
                    \"command\": \"Check playbook configurations for 'ignore_errors: true' if you want to continue execution despite errors.\"
                  },
                  {
                    \"instruction\": \"To override default behavior, use the 'ignore_errors' parameter.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  }
                ]"
    answer_a="It skips the task and continues execution."
    answer_b="It stops execution of the playbook."  # Correct answer
    answer_c="It retries the task three times before stopping."
    answer_d="It logs the error and proceeds to the next play."
    ;;
  "fr")
    question="Quel est le comportement par défaut d'Ansible lorsqu'il rencontre une erreur dans une tâche ?"
    hint="Pensez à la façon dont Ansible traite les échecs de tâche par défaut."
    instructions="[
                  {
                    \"instruction\": \"Par défaut, Ansible arrête l'exécution du playbook lorsqu'il rencontre une erreur dans une tâche.\",
                    \"command\": \"Vérifiez les configurations du playbook pour 'ignore_errors: true' si vous souhaitez continuer l'exécution malgré les erreurs.\"
                  },
                  {
                    \"instruction\": \"Pour remplacer le comportement par défaut, utilisez le paramètre 'ignore_errors'.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  }
                ]"
    answer_a="Il saute la tâche et continue l'exécution."
    answer_b="Il arrête l'exécution du playbook."  # Correct answer
    answer_c="Il réessaie la tâche trois fois avant de s'arrêter."
    answer_d="Il enregistre l'erreur et passe à la tâche suivante."
    ;;
  "es")
    question="¿Cuál es el comportamiento predeterminado de Ansible cuando encuentra un error en una tarea?"
    hint="Piensa en cómo Ansible maneja los fallos en las tareas por defecto."
    instructions="[
                  {
                    \"instruction\": \"Por defecto, Ansible detiene la ejecución del playbook cuando encuentra un error en una tarea.\",
                    \"command\": \"Verifica las configuraciones del playbook para 'ignore_errors: true' si deseas continuar la ejecución a pesar de los errores.\"
                  },
                  {
                    \"instruction\": \"Para modificar el comportamiento predeterminado, usa el parámetro 'ignore_errors'.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  }
                ]"
    answer_a="Omite la tarea y continúa la ejecución."
    answer_b="Detiene la ejecución del playbook."  # Correct answer
    answer_c="Reintenta la tarea tres veces antes de detenerse."
    answer_d="Registra el error y pasa a la siguiente tarea."
    ;;
   "it")
    question="Qual è il comportamento predefinito di Ansible quando si verifica un errore in un'attività?"
    hint="Pensa a come Ansible gestisce i fallimenti delle attività per impostazione predefinita."
    instructions="[
                  {
                    \"instruction\": \"Per impostazione predefinita, Ansible interrompe l'esecuzione del playbook quando si verifica un errore in un'attività.\",
                    \"command\": \"Controlla le configurazioni del playbook per 'ignore_errors: true' se vuoi continuare l'esecuzione nonostante gli errori.\"
                  },
                  {
                    \"instruction\": \"Per modificare il comportamento predefinito, utilizza il parametro 'ignore_errors'.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  }
                ]"
    answer_a="Salta l'attività e continua l'esecuzione."
    answer_b="Interrompe l'esecuzione del playbook."  # Correct answer
    answer_c="Ripete l'attività tre volte prima di fermarsi."
    answer_d="Registra l'errore e procede al play successivo."
    ;;
  "de")
    question="Wie verhält sich Ansible standardmäßig, wenn ein Fehler in einer Aufgabe auftritt?"
    hint="Denken Sie darüber nach, wie Ansible standardmäßig mit Aufgabenfehlern umgeht."
    instructions="[
                  {
                    \"instruction\": \"Standardmäßig stoppt Ansible die Ausführung des Playbooks, wenn ein Fehler in einer Aufgabe auftritt.\",
                    \"command\": \"Überprüfen Sie die Playbook-Konfigurationen auf 'ignore_errors: true', wenn Sie die Ausführung trotz Fehlern fortsetzen möchten.\"
                  },
                  {
                    \"instruction\": \"Um das Standardverhalten zu ändern, verwenden Sie den Parameter 'ignore_errors'.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  }
                ]"
    answer_a="Es überspringt die Aufgabe und setzt die Ausführung fort."
    answer_b="Es stoppt die Ausführung des Playbooks."  # Correct answer
    answer_c="Es wiederholt die Aufgabe dreimal, bevor es stoppt."
    answer_d="Es protokolliert den Fehler und fährt mit dem nächsten Play fort."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the default behavior of Ansible when it encounters an error in a task?"
    hint="Think about how Ansible treats task failures by default."
    instructions="[
                  {
                    \"instruction\": \"By default, Ansible stops execution of the playbook when it encounters an error in a task.\",
                    \"command\": \"Check playbook configurations for 'ignore_errors: true' if you want to continue execution despite errors.\"
                  },
                  {
                    \"instruction\": \"To override default behavior, use the 'ignore_errors' parameter.\",
                    \"command\": \"ansible-playbook --syntax-check playbook.yml\"
                  }
                ]"
    answer_a="It skips the task and continues execution."
    answer_b="It stops execution of the playbook."  # Correct answer
    answer_c="It retries the task three times before stopping."
    answer_d="It logs the error and proceeds to the next play."
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
  "platform_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
