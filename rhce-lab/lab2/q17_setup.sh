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
    question="What is the purpose of the 'when' clause in Ansible tasks?"
    hint="Think about how Ansible controls conditional task execution."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">when</span> clause is used to execute tasks conditionally, based on the evaluation of a given expression or variable value.\",
                    \"command\": \"#Use 'when' to apply logic like 'when: ansible_os_family == \\\"Debian\\\"'.\"
                  },
                  {
                    \"instruction\": \"It ensures tasks are executed only when specific conditions are met.\",
                    \"command\": \"#when: my_variable == 'value'\"
                  }
                ]"
    answer_a="It retries the task until a condition is met."
    answer_b="It specifies a delay before executing the task."
    answer_c="It controls whether a task should be executed based on a condition."  # Correct answer
    answer_d="It tags a task for selective execution."
    ;;
  "fr")
    question="Quel est l'objectif de la clause 'when' dans les tâches Ansible ?"
    hint="Pensez à la manière dont Ansible contrôle l'exécution conditionnelle des tâches."
    instructions="[
                  {
                    \"instruction\": \"La clause <span class=\\\"bold-green-text\\\">when</span> est utilisée pour exécuter des tâches conditionnellement, en fonction de l'évaluation d'une expression ou d'une valeur de variable donnée.\",
                    \"command\": \"#Utilisez 'when' pour appliquer une logique comme 'when: ansible_os_family == \\\"Debian\\\"'.\"
                  },
                  {
                    \"instruction\": \"Cela garantit que les tâches ne sont exécutées que lorsque des conditions spécifiques sont remplies.\",
                    \"command\": \"#when: my_variable == 'value'\"
                  }
                ]"
    answer_a="Elle réessaie la tâche jusqu'à ce qu'une condition soit remplie."
    answer_b="Elle spécifie un délai avant l'exécution de la tâche."
    answer_c="Elle contrôle si une tâche doit être exécutée en fonction d'une condition."  # Correct answer
    answer_d="Elle étiquette une tâche pour une exécution sélective."
    ;;
  "es")
    question="¿Cuál es el propósito de la cláusula 'when' en las tareas de Ansible?"
    hint="Piensa en cómo Ansible controla la ejecución condicional de tareas."
    instructions="[
                  {
                    \"instruction\": \"La cláusula <span class=\\\"bold-green-text\\\">when</span> se utiliza para ejecutar tareas condicionalmente, basándose en la evaluación de una expresión o valor de variable dado.\",
                    \"command\": \"#Usa 'when' para aplicar lógica como 'when: ansible_os_family == \\\"Debian\\\"'.\"
                  },
                  {
                    \"instruction\": \"Asegura que las tareas se ejecuten solo cuando se cumplen condiciones específicas.\",
                    \"command\": \"#when: my_variable == 'value'\"
                  }
                ]"
    answer_a="Reintenta la tarea hasta que se cumple una condición."
    answer_b="Especifica un retraso antes de ejecutar la tarea."
    answer_c="Controla si una tarea debe ejecutarse en función de una condición."  # Correct answer
    answer_d="Etiqueta una tarea para ejecución selectiva."
    ;;
  "it")
    question="Qual è lo scopo della clausola 'when' nei compiti di Ansible?"
    hint="Pensa a come Ansible controlla l'esecuzione condizionale dei compiti."
    instructions="[
                  {
                    \"instruction\": \"La clausola <span class=\\\"bold-green-text\\\">when</span> viene utilizzata per eseguire compiti in modo condizionale, in base alla valutazione di un'espressione o al valore di una variabile.\",
                    \"command\": \"#Usa 'when' per applicare una logica come 'when: ansible_os_family == \\\"Debian\\\"'.\"
                  },
                  {
                    \"instruction\": \"Garantisce che i compiti vengano eseguiti solo quando vengono soddisfatte condizioni specifiche.\",
                    \"command\": \"#when: my_variable == 'value'\"
                  }
                ]"
    answer_a="Riprova il compito finché non viene soddisfatta una condizione."
    answer_b="Specifica un ritardo prima dell'esecuzione del compito."
    answer_c="Controlla se un compito deve essere eseguito in base a una condizione."  # Correct answer
    answer_d="Tagga un compito per un'esecuzione selettiva."
    ;;
  "de")
    question="Was ist der Zweck der 'when'-Klausel in Ansible-Aufgaben?"
    hint="Denken Sie darüber nach, wie Ansible die bedingte Ausführung von Aufgaben steuert."
    instructions="[
                  {
                    \"instruction\": \"Die <span class=\\\"bold-green-text\\\">when</span>-Klausel wird verwendet, um Aufgaben bedingt auszuführen, basierend auf der Bewertung eines Ausdrucks oder Variablenwerts.\",
                    \"command\": \"#Verwenden Sie 'when', um eine Logik wie 'when: ansible_os_family == \\\"Debian\\\"' anzuwenden.\"
                  },
                  {
                    \"instruction\": \"Es stellt sicher, dass Aufgaben nur ausgeführt werden, wenn bestimmte Bedingungen erfüllt sind.\",
                    \"command\": \"#when: my_variable == 'value'\"
                  }
                ]"
    answer_a="Es versucht die Aufgabe erneut, bis eine Bedingung erfüllt ist."
    answer_b="Es legt eine Verzögerung vor der Ausführung der Aufgabe fest."
    answer_c="Es steuert, ob eine Aufgabe basierend auf einer Bedingung ausgeführt werden soll."  # Correct answer
    answer_d="Es markiert eine Aufgabe für eine selektive Ausführung."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the 'when' clause in Ansible tasks?"
    hint="Think about how Ansible controls conditional task execution."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">when</span> clause is used to execute tasks conditionally, based on the evaluation of a given expression or variable value.\",
                    \"command\": \"#Use 'when' to apply logic like 'when: ansible_os_family == \\\"Debian\\\"'.\"
                  },
                  {
                    \"instruction\": \"It ensures tasks are executed only when specific conditions are met.\",
                    \"command\": \"#when: my_variable == 'value'\"
                  }
                ]"
    answer_a="It retries the task until a condition is met."
    answer_b="It specifies a delay before executing the task."
    answer_c="It controls whether a task should be executed based on a condition."  # Correct answer
    answer_d="It tags a task for selective execution."
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
  "platform_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
