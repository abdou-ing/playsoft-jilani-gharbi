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
    question="What happens if multiple variables with the same name are defined in Ansible?"
    hint="Think about how Ansible resolves conflicts when variables are defined in different places."
    instructions="[
                  {
                    \"instruction\": \"Ansible uses variable precedence to determine which value to use when multiple variables with the same name are defined\",
                    \"command\": \"ansible-playbook playbook.yml -e 'var_name=value'\"
                  },
                  {
                    \"instruction\": \"The order of precedence (from highest to lowest) includes: 1) Extra vars, 2) Task vars, 3) Block vars, 4) Role and play vars, 5) Inventory vars, 6) Facts, and 7) Default vars\",
                    \"command\": \"ansible-playbook playbook.yml --extra-vars 'var_name=value'\"
                  }
                ]"
    answer_a="Ansible merges the variables to create a composite value."
    answer_b="Ansible raises an error and stops execution."
    answer_c="Ansible uses the value with the highest precedence according to its variable precedence rules."  # Correct answer
    answer_d="Ansible always uses the first value it encounters in the playbook."
    ;;
  "fr")
    question="Que se passe-t-il si plusieurs variables portant le même nom sont définies dans Ansible ?"
    hint="Réfléchissez à la manière dont Ansible résout les conflits lorsque des variables sont définies à différents endroits."
    instructions="[
                  {
                    \"instruction\": \"Ansible utilise la précédence des variables pour déterminer quelle valeur utiliser lorsque plusieurs variables portant le même nom sont définies\",
                    \"command\": \"ansible-playbook playbook.yml -e 'var_name=value'\"
                  },
                  {
                    \"instruction\": \"L'ordre de précédence (du plus élevé au plus bas) comprend : 1) Variables supplémentaires, 2) Variables de tâche, 3) Variables de bloc, 4) Variables de rôle et de play, 5) Variables d'inventaire, 6) Faits, et 7) Variables par défaut\",
                    \"command\": \"ansible-playbook playbook.yml --extra-vars 'var_name=value'\"
                  }
                ]"
    answer_a="Ansible fusionne les variables pour créer une valeur composite."
    answer_b="Ansible génère une erreur et arrête l'exécution."
    answer_c="Ansible utilise la valeur ayant la précédence la plus élevée selon ses règles de précédence des variables."  # Correct answer
    answer_d="Ansible utilise toujours la première valeur qu'il rencontre dans le playbook."
    ;;
  "de")
    question="Was passiert, wenn mehrere Variablen mit demselben Namen in Ansible definiert sind?"
    hint="Denken Sie darüber nach, wie Ansible Konflikte löst, wenn Variablen an verschiedenen Stellen definiert sind."
    instructions="[
                  {
                    \"instruction\": \"Ansible verwendet die Variablenpriorität, um zu bestimmen, welcher Wert verwendet wird, wenn mehrere Variablen mit demselben Namen definiert sind\",
                    \"command\": \"ansible-playbook playbook.yml -e 'var_name=value'\"
                  },
                  {
                    \"instruction\": \"Die Reihenfolge der Priorität (von höchster zu niedrigster) umfasst: 1) Extra-Variablen, 2) Aufgaben-Variablen, 3) Block-Variablen, 4) Rollen- und Play-Variablen, 5) Inventar-Variablen, 6) Fakten und 7) Standard-Variablen\",
                    \"command\": \"ansible-playbook playbook.yml --extra-vars 'var_name=value'\"
                  }
                ]"
    answer_a="Ansible kombiniert die Variablen, um einen zusammengesetzten Wert zu erstellen."
    answer_b="Ansible löst einen Fehler aus und stoppt die Ausführung."
    answer_c="Ansible verwendet den Wert mit der höchsten Priorität gemäß seinen Regeln für die Variablenpriorität."  # Correct answer
    answer_d="Ansible verwendet immer den ersten Wert, auf den es im Playbook stößt."
    ;;
  "es")
    question="¿Qué sucede si se definen múltiples variables con el mismo nombre en Ansible?"
    hint="Piensa en cómo Ansible resuelve conflictos cuando las variables se definen en diferentes lugares."
    instructions="[
                  {
                    \"instruction\": \"Ansible utiliza la precedencia de variables para determinar qué valor usar cuando se definen múltiples variables con el mismo nombre\",
                    \"command\": \"ansible-playbook playbook.yml -e 'var_name=value'\"
                  },
                  {
                    \"instruction\": \"El orden de precedencia (de mayor a menor) incluye: 1) Variables adicionales, 2) Variables de tarea, 3) Variables de bloque, 4) Variables de rol y play, 5) Variables de inventario, 6) Hechos y 7) Variables predeterminadas\",
                    \"command\": \"ansible-playbook playbook.yml --extra-vars 'var_name=value'\"
                  }
                ]"
    answer_a="Ansible combina las variables para crear un valor compuesto."
    answer_b="Ansible genera un error y detiene la ejecución."
    answer_c="Ansible utiliza el valor con la precedencia más alta según sus reglas de precedencia de variables."  # Correct answer
    answer_d="Ansible siempre utiliza el primer valor que encuentra en el playbook."
    ;;
  "it")
    question="Cosa succede se più variabili con lo stesso nome sono definite in Ansible?"
    hint="Pensa a come Ansible risolve i conflitti quando le variabili sono definite in luoghi diversi."
    instructions="[
                  {
                    \"instruction\": \"Ansible utilizza la precedenza delle variabili per determinare quale valore utilizzare quando più variabili con lo stesso nome sono definite\",
                    \"command\": \"ansible-playbook playbook.yml -e 'var_name=value'\"
                  },
                  {
                    \"instruction\": \"L'ordine di precedenza (dal più alto al più basso) include: 1) Variabili extra, 2) Variabili di attività, 3) Variabili di blocco, 4) Variabili di ruolo e play, 5) Variabili di inventario, 6) Fatti e 7) Variabili predefinite\",
                    \"command\": \"ansible-playbook playbook.yml --extra-vars 'var_name=value'\"
                  }
                ]"
    answer_a="Ansible combina le variabili per creare un valore composito."
    answer_b="Ansible genera un errore e interrompe l'esecuzione."
    answer_c="Ansible utilizza il valore con la precedenza più alta secondo le sue regole di precedenza delle variabili."  # Correct answer
    answer_d="Ansible utilizza sempre il primo valore che incontra nel playbook."
    ;;
  *)
    # Default to English if the language is not supported
    question="What happens if multiple variables with the same name are defined in Ansible?"
    hint="Think about how Ansible resolves conflicts when variables are defined in different places."
    instructions="[
                  {
                    \"instruction\": \"Ansible uses variable precedence to determine which value to use when multiple variables with the same name are defined\",
                    \"command\": \"ansible-playbook playbook.yml -e 'var_name=value'\"
                  },
                  {
                    \"instruction\": \"The order of precedence (from highest to lowest) includes: 1) Extra vars, 2) Task vars, 3) Block vars, 4) Role and play vars, 5) Inventory vars, 6) Facts, and 7) Default vars\",
                    \"command\": \"ansible-playbook playbook.yml --extra-vars 'var_name=value'\"
                  }
                ]"
    answer_a="Ansible merges the variables to create a composite value."
    answer_b="Ansible raises an error and stops execution."
    answer_c="Ansible uses the value with the highest precedence according to its variable precedence rules."  # Correct answer
    answer_d="Ansible always uses the first value it encounters in the playbook."
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