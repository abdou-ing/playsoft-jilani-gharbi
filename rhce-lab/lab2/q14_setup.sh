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
    question="How can you apply tags to tasks in an Ansible playbook?"
    hint="Tags help in selectively running tasks or skipping them."
    instructions="[
                  {
                    \"instruction\": \"You can apply tags by adding the <span class=\\\"bold-green-text\\\">tags</span> key to a task and specifying one or more tag names.\",
                    \"command\": \"- name: Install Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  tags:\\n    - webserver\\n    - install\"
                  },
                  {
                    \"instruction\": \"This allows selective task execution using the '--tags' option.\",
                    \"command\": \"ansible-playbook playbook.yml --tags webserver\"
                  }
                ]"
    answer_a="By using the <span class=\\\"bold-green-text\\\">tags</span> key in a task definition."  # Correct answer
    answer_b="By specifying the tag in the playbook's metadata."
    answer_c="By setting the 'tag' parameter in the ansible.cfg file."
    answer_d="By including a tag comment at the start of the task."
    ;;
  "fr")
    question="Comment pouvez-vous appliquer des tags aux tâches dans un playbook Ansible ?"
    hint="Les tags aident à exécuter ou à ignorer des tâches de manière sélective."
    instructions="[
                  {
                    \"instruction\": \"Vous pouvez appliquer des tags en ajoutant la clé <span class=\\\"bold-green-text\\\">tags</span> à une tâche et en spécifiant un ou plusieurs noms de tags.\",
                    \"command\": \"- name: Installer Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  tags:\\n    - webserver\\n    - install\"
                  },
                  {
                    \"instruction\": \"Cela permet une exécution sélective des tâches en utilisant l'option '--tags'.\",
                    \"command\": \"ansible-playbook playbook.yml --tags webserver\"
                  }
                ]"
    answer_a="En utilisant la clé <span class=\\\"bold-green-text\\\">tags</span> dans la définition d'une tâche."  # Correct answer
    answer_b="En spécifiant le tag dans les métadonnées du playbook."
    answer_c="En définissant le paramètre 'tag' dans le fichier ansible.cfg."
    answer_d="En incluant un commentaire de tag au début de la tâche."
    ;;
  "es")
    question="¿Cómo puedes aplicar etiquetas a tareas en un playbook de Ansible?"
    hint="Las etiquetas ayudan a ejecutar o omitir tareas de manera selectiva."
    instructions="[
                  {
                    \"instruction\": \"Puedes aplicar etiquetas agregando la clave <span class=\\\"bold-green-text\\\">tags</span> a una tarea y especificando uno o más nombres de etiquetas.\",
                    \"command\": \"- name: Instalar Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  tags:\\n    - webserver\\n    - install\"
                  },
                  {
                    \"instruction\": \"Esto permite la ejecución selectiva de tareas usando la opción '--tags'.\",
                    \"command\": \"ansible-playbook playbook.yml --tags webserver\"
                  }
                ]"
    answer_a="Usando la clave <span class=\\\"bold-green-text\\\">tags</span> en la definición de una tarea."  # Correct answer
    answer_b="Especificando la etiqueta en los metadatos del playbook."
    answer_c="Configurando el parámetro 'tag' en el archivo ansible.cfg."
    answer_d="Incluyendo un comentario de etiqueta al inicio de la tarea."
    ;;
  "it")
    question="Come puoi applicare tag alle attività in un playbook Ansible?"
    hint="I tag aiutano a eseguire o saltare selettivamente le attività."
    instructions="[
                  {
                    \"instruction\": \"Puoi applicare i tag aggiungendo la chiave <span class=\\\"bold-green-text\\\">tags</span> a un'attività e specificando uno o più nomi di tag.\",
                    \"command\": \"- name: Installa Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  tags:\\n    - webserver\\n    - install\"
                  },
                  {
                    \"instruction\": \"Questo consente l'esecuzione selettiva delle attività utilizzando l'opzione '--tags'.\",
                    \"command\": \"ansible-playbook playbook.yml --tags webserver\"
                  }
                ]"
    answer_a="Utilizzando la chiave <span class=\\\"bold-green-text\\\">tags</span> nella definizione dell'attività."  # Correct answer
    answer_b="Specificando il tag nei metadati del playbook."
    answer_c="Impostando il parametro 'tag' nel file ansible.cfg."
    answer_d="Includendo un commento tag all'inizio dell'attività."
    ;;
  "de")
    question="Wie können Sie Aufgaben in einem Ansible-Playbook mit Tags versehen?"
    hint="Tags helfen dabei, Aufgaben selektiv auszuführen oder zu überspringen."
    instructions="[
                  {
                    \"instruction\": \"Sie können Tags anwenden, indem Sie den Schlüssel <span class=\\\"bold-green-text\\\">tags</span> zu einer Aufgabe hinzufügen und einen oder mehrere Tag-Namen angeben.\",
                    \"command\": \"- name: Installiere Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  tags:\\n    - webserver\\n    - install\"
                  },
                  {
                    \"instruction\": \"Dies ermöglicht die selektive Ausführung von Aufgaben mit der Option '--tags'.\",
                    \"command\": \"ansible-playbook playbook.yml --tags webserver\"
                  }
                ]"
    answer_a="Durch die Verwendung des Schlüssels <span class=\\\"bold-green-text\\\">tags</span> in der Aufgaben-Definition."  # Correct answer
    answer_b="Durch die Angabe des Tags in den Metadaten des Playbooks."
    answer_c="Durch das Festlegen des 'tag'-Parameters in der ansible.cfg-Datei."
    answer_d="Durch das Einfügen eines Tag-Kommentars am Anfang der Aufgabe."
    ;;
  *)
    # Default to English if the language is not supported
    question="How can you apply tags to tasks in an Ansible playbook?"
    hint="Tags help in selectively running tasks or skipping them."
    instructions="[
                  {
                    \"instruction\": \"You can apply tags by adding the <span class=\\\"bold-green-text\\\">tags</span> key to a task and specifying one or more tag names.\",
                    \"command\": \"- name: Install Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  tags:\\n    - webserver\\n    - install\"
                  },
                  {
                    \"instruction\": \"This allows selective task execution using the '--tags' option.\",
                    \"command\": \"ansible-playbook playbook.yml --tags webserver\"
                  }
                ]"
    answer_a="By using the <span class=\\\"bold-green-text\\\">tags</span> key in a task definition."  # Correct answer
    answer_b="By specifying the tag in the playbook's metadata."
    answer_c="By setting the 'tag' parameter in the ansible.cfg file."
    answer_d="By including a tag comment at the start of the task."
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
  "solution": "'"$answer_a"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .