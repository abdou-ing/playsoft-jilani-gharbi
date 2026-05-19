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
    question="What is the purpose of the 'with_items' loop in Ansible?"
    hint="Think about how Ansible repeats a task for multiple inputs."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">with_items</span> loop allows you to iterate over a list of items, executing the same task for each item in the list.\",
                    \"command\": \"- name: Install multiple packages\\n  apt:\\n    name: \\\"{{ item }}\\\"\\n  with_items:\\n    - nginx\\n    - apache2\"
                  },
                  {
                    \"instruction\": \"It simplifies repeating tasks for multiple inputs in a structured manner.\",
                    \"command\": \"with_items: [item1, item2, item3]\"
                  }
                ]"
    answer_a="It retries a task multiple times until success."
    answer_b="It executes a task for each item in a list."  # Correct answer
    answer_c="It assigns a tag to each task for selective execution."
    answer_d="It defines conditional execution based on variables."
    ;;
  "fr")
    question="Quel est l'objectif de la boucle 'with_items' dans Ansible ?"
    hint="Pensez à comment Ansible répète une tâche pour plusieurs entrées."
    instructions="[
                  {
                    \"instruction\": \"La boucle <span class=\\\"bold-green-text\\\">with_items</span> permet d'itérer sur une liste d'éléments, en exécutant la même tâche pour chaque élément de la liste.\",
                    \"command\": \"- name: Installer plusieurs packages\\n  apt:\\n    name: \\\"{{ item }}\\\"\\n  with_items:\\n    - nginx\\n    - apache2\"
                  },
                  {
                    \"instruction\": \"Elle simplifie la répétition des tâches pour plusieurs entrées de manière structurée.\",
                    \"command\": \"with_items: [item1, item2, item3]\"
                  }
                ]"
    answer_a="Elle réessaie une tâche plusieurs fois jusqu'à la réussite."
    answer_b="Elle exécute une tâche pour chaque élément d'une liste."  # Correct answer
    answer_c="Elle assigne une étiquette à chaque tâche pour une exécution sélective."
    answer_d="Elle définit une exécution conditionnelle basée sur des variables."
    ;;
  "es")
    question="¿Cuál es el propósito del bucle 'with_items' en Ansible?"
    hint="Piensa en cómo Ansible repite una tarea para múltiples entradas."
    instructions="[
                  {
                    \"instruction\": \"El bucle <span class=\\\"bold-green-text\\\">with_items</span> te permite iterar sobre una lista de elementos, ejecutando la misma tarea para cada elemento de la lista.\",
                    \"command\": \"- name: Instalar varios paquetes\\n  apt:\\n    name: \\\"{{ item }}\\\"\\n  with_items:\\n    - nginx\\n    - apache2\"
                  },
                  {
                    \"instruction\": \"Simplifica la repetición de tareas para múltiples entradas de manera estructurada.\",
                    \"command\": \"with_items: [item1, item2, item3]\"
                  }
                ]"
    answer_a="Reintenta una tarea varias veces hasta que tenga éxito."
    answer_b="Ejecuta una tarea para cada elemento en una lista."  # Correct answer
    answer_c="Asigna una etiqueta a cada tarea para una ejecución selectiva."
    answer_d="Define la ejecución condicional basada en variables."
    ;;
  "it")
    question="Qual è lo scopo del ciclo 'with_items' in Ansible?"
    hint="Pensa a come Ansible ripete un'attività per più elementi."
    instructions="[
                  {
                    \"instruction\": \"Il ciclo <span class=\\\"bold-green-text\\\">with_items</span> consente di iterare su un elenco di elementi, eseguendo la stessa attività per ciascun elemento dell'elenco.\",
                    \"command\": \"- name: Installa più pacchetti\\n  apt:\\n    name: \\\"{{ item }}\\\"\\n  with_items:\\n    - nginx\\n    - apache2\"
                  },
                  {
                    \"instruction\": \"Semplifica la ripetizione delle attività per più input in modo strutturato.\",
                    \"command\": \"with_items: [item1, item2, item3]\"
                  }
                ]"
    answer_a="Riprova un'attività più volte fino al successo."
    answer_b="Esegue un'attività per ogni elemento in un elenco."  # Correct answer
    answer_c="Assegna un tag a ogni attività per un'esecuzione selettiva."
    answer_d="Definisce l'esecuzione condizionale basata su variabili."
    ;;
  "de")
    question="Was ist der Zweck der 'with_items'-Schleife in Ansible?"
    hint="Denken Sie daran, wie Ansible eine Aufgabe für mehrere Eingaben wiederholt."
    instructions="[
                  {
                    \"instruction\": \"Die <span class=\\\"bold-green-text\\\">with_items</span>-Schleife ermöglicht es Ihnen, über eine Liste von Elementen zu iterieren und dieselbe Aufgabe für jedes Element in der Liste auszuführen.\",
                    \"command\": \"- name: Mehrere Pakete installieren\\n  apt:\\n    name: \\\"{{ item }}\\\"\\n  with_items:\\n    - nginx\\n    - apache2\"
                  },
                  {
                    \"instruction\": \"Sie vereinfacht die Wiederholung von Aufgaben für mehrere Eingaben in strukturierter Weise.\",
                    \"command\": \"with_items: [item1, item2, item3]\"
                  }
                ]"
    answer_a="Es versucht eine Aufgabe mehrmals, bis sie erfolgreich ist."
    answer_b="Es führt eine Aufgabe für jedes Element in einer Liste aus."  # Correct answer
    answer_c="Es weist jeder Aufgabe ein Tag für die selektive Ausführung zu."
    answer_d="Es definiert eine bedingte Ausführung basierend auf Variablen."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the 'with_items' loop in Ansible?"
    hint="Think about how Ansible repeats a task for multiple inputs."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">with_items</span> loop allows you to iterate over a list of items, executing the same task for each item in the list.\",
                    \"command\": \"- name: Install multiple packages\\n  apt:\\n    name: \\\"{{ item }}\\\"\\n  with_items:\\n    - nginx\\n    - apache2\"
                  },
                  {
                    \"instruction\": \"It simplifies repeating tasks for multiple inputs in a structured manner.\",
                    \"command\": \"with_items: [item1, item2, item3]\"
                  }
                ]"
    answer_a="It retries a task multiple times until success."
    answer_b="It executes a task for each item in a list."  # Correct answer
    answer_c="It assigns a tag to each task for selective execution."
    answer_d="It defines conditional execution based on variables."
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
