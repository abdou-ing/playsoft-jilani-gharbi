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
    question="What is the purpose of the 'register' keyword in Ansible?"
    hint="Think about how Ansible stores the output of a task."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">register</span> keyword is used to store the result of a task in a variable, allowing you to reference it in subsequent tasks.\",
                    \"command\": \"- name: Check disk usage\\n  command: df -h\\n  register: disk_usage\"
                  },
                  {
                    \"instruction\": \"You can then use the registered variable in later tasks.\",
                    \"command\": \"- name: Display disk usage\\n  debug:\\n    var: disk_usage.stdout\"
                  }
                ]"
    answer_a="It assigns a name to a playbook."
    answer_b="It tags a task for selective execution."
    answer_c="It stores the result of a task in a variable for later use."  # Correct answer
    answer_d="It defines a conditional statement for task execution."
    ;;
  "fr")
    question="Quel est le but du mot-clé 'register' dans Ansible ?"
    hint="Réfléchissez à la manière dont Ansible stocke le résultat d'une tâche."
    instructions="[
                  {
                    \"instruction\": \"Le mot-clé <span class=\\\"bold-green-text\\\">register</span> est utilisé pour stocker le résultat d'une tâche dans une variable, vous permettant de le référencer dans les tâches suivantes.\",
                    \"command\": \"- name: Vérifier l'utilisation du disque\\n  command: df -h\\n  register: disk_usage\"
                  },
                  {
                    \"instruction\": \"Vous pouvez ensuite utiliser la variable enregistrée dans des tâches ultérieures.\",
                    \"command\": \"- name: Afficher l'utilisation du disque\\n  debug:\\n    var: disk_usage.stdout\"
                  }
                ]"
    answer_a="Il attribue un nom à un playbook."
    answer_b="Il ajoute un tag à une tâche pour une exécution sélective."
    answer_c="Il stocke le résultat d'une tâche dans une variable pour une utilisation ultérieure."  # Correct answer
    answer_d="Il définit une instruction conditionnelle pour l'exécution d'une tâche."
    ;;
  "es")
    question="¿Cuál es el propósito de la palabra clave 'register' en Ansible?"
    hint="Piensa en cómo Ansible almacena el resultado de una tarea."
    instructions="[
                  {
                    \"instruction\": \"La palabra clave <span class=\\\"bold-green-text\\\">register</span> se utiliza para almacenar el resultado de una tarea en una variable, lo que permite referenciarla en tareas posteriores.\",
                    \"command\": \"- name: Verificar el uso del disco\\n  command: df -h\\n  register: disk_usage\"
                  },
                  {
                    \"instruction\": \"Luego puedes usar la variable registrada en tareas posteriores.\",
                    \"command\": \"- name: Mostrar el uso del disco\\n  debug:\\n    var: disk_usage.stdout\"
                  }
                ]"
    answer_a="Asigna un nombre a un playbook."
    answer_b="Etiqueta una tarea para su ejecución selectiva."
    answer_c="Almacena el resultado de una tarea en una variable para su uso posterior."  # Correct answer
    answer_d="Define una declaración condicional para la ejecución de una tarea."
    ;;
  "it")
    question="Qual è lo scopo della parola chiave 'register' in Ansible?"
    hint="Pensa a come Ansible memorizza l'output di un'attività."
    instructions="[
                  {
                    \"instruction\": \"La parola chiave <span class=\\\"bold-green-text\\\">register</span> viene utilizzata per memorizzare il risultato di un'attività in una variabile, consentendo di fare riferimento ad essa nelle attività successive.\",
                    \"command\": \"- name: Controlla l'uso del disco\\n  command: df -h\\n  register: disk_usage\"
                  },
                  {
                    \"instruction\": \"Puoi quindi utilizzare la variabile registrata nelle attività successive.\",
                    \"command\": \"- name: Mostra l'uso del disco\\n  debug:\\n    var: disk_usage.stdout\"
                  }
                ]"
    answer_a="Assegna un nome a un playbook."
    answer_b="Aggiunge un tag a un'attività per l'esecuzione selettiva."
    answer_c="Memorizza il risultato di un'attività in una variabile per un uso successivo."  # Correct answer
    answer_d="Definisce un'istruzione condizionale per l'esecuzione di un'attività."
    ;;
  "de")
    question="Was ist der Zweck des Schlüsselworts 'register' in Ansible?"
    hint="Denken Sie darüber nach, wie Ansible die Ausgabe einer Aufgabe speichert."
    instructions="[
                  {
                    \"instruction\": \"Das Schlüsselwort <span class=\\\"bold-green-text\\\">register</span> wird verwendet, um das Ergebnis einer Aufgabe in einer Variablen zu speichern, sodass Sie in späteren Aufgaben darauf verweisen können.\",
                    \"command\": \"- name: Überprüfe die Festplattennutzung\\n  command: df -h\\n  register: disk_usage\"
                  },
                  {
                    \"instruction\": \"Sie können die registrierte Variable dann in späteren Aufgaben verwenden.\",
                    \"command\": \"- name: Zeige die Festplattennutzung an\\n  debug:\\n    var: disk_usage.stdout\"
                  }
                ]"
    answer_a="Es weist einem Playbook einen Namen zu."
    answer_b="Es markiert eine Aufgabe für die selektive Ausführung."
    answer_c="Es speichert das Ergebnis einer Aufgabe in einer Variablen für die spätere Verwendung."  # Correct answer
    answer_d="Es definiert eine bedingte Anweisung für die Aufgabenausführung."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the 'register' keyword in Ansible?"
    hint="Think about how Ansible stores the output of a task."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">register</span> keyword is used to store the result of a task in a variable, allowing you to reference it in subsequent tasks.\",
                    \"command\": \"- name: Check disk usage\\n  command: df -h\\n  register: disk_usage\"
                  },
                  {
                    \"instruction\": \"You can then use the registered variable in later tasks.\",
                    \"command\": \"- name: Display disk usage\\n  debug:\\n    var: disk_usage.stdout\"
                  }
                ]"
    answer_a="It assigns a name to a playbook."
    answer_b="It tags a task for selective execution."
    answer_c="It stores the result of a task in a variable for later use."  # Correct answer
    answer_d="It defines a conditional statement for task execution."
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

# Pretty print the JSON output (optional)
echo "$display" | jq .