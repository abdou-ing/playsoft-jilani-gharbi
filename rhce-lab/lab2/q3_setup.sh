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
    question="What is the purpose of an Ansible role?"
    hint="Consider how roles help in organizing and reusing automation tasks."
    instructions="[
                  {
                    \"instruction\": \"Roles group related tasks, variables, handlers, and templates into reusable components\",
                    \"command\": \"ansible-galaxy init <role_name>\"
                  },
                  {
                    \"instruction\": \"They simplify complex configurations by promoting modularity and reusability\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml --tags <role_name>\"
                  }
                ]"
    answer_a="It is used to define the sequence of tasks in a playbook."
    answer_b="It groups related tasks, variables, and templates into reusable components."  # Correct answer
    answer_c="It initializes the Ansible environment."
    answer_d="It stores information about managed hosts."
    ;;
  "fr")
    question="Quel est l'objectif d'un rôle Ansible ?"
    hint="Réfléchissez à la façon dont les rôles aident à organiser et à réutiliser les tâches d'automatisation."
    instructions="[
                  {
                    \"instruction\": \"Les rôles regroupent des tâches, variables, gestionnaires et modèles connexes en composants réutilisables\",
                    \"command\": \"ansible-galaxy init <role_name>\"
                  },
                  {
                    \"instruction\": \"Ils simplifient les configurations complexes en favorisant la modularité et la réutilisabilité\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml --tags <role_name>\"
                  }
                ]"
    answer_a="Il est utilisé pour définir la séquence des tâches dans un playbook."
    answer_b="Il regroupe des tâches, variables et modèles connexes en composants réutilisables."  # Correct answer
    answer_c="Il initialise l'environnement Ansible."
    answer_d="Il stocke des informations sur les hôtes gérés."
    ;;
  "de")
    question="Was ist der Zweck einer Ansible-Rolle?"
    hint="Überlegen Sie, wie Rollen helfen, Automatisierungsaufgaben zu organisieren und wiederzuverwenden."
    instructions="[
                  {
                    \"instruction\": \"Rollen gruppieren verwandte Aufgaben, Variablen, Handler und Vorlagen in wiederverwendbare Komponenten\",
                    \"command\": \"ansible-galaxy init <role_name>\"
                  },
                  {
                    \"instruction\": \"Sie vereinfachen komplexe Konfigurationen durch Modularität und Wiederverwendbarkeit\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml --tags <role_name>\"
                  }
                ]"
    answer_a="Es wird verwendet, um die Reihenfolge der Aufgaben in einem Playbook zu definieren."
    answer_b="Es gruppiert verwandte Aufgaben, Variablen und Vorlagen in wiederverwendbare Komponenten."  # Correct answer
    answer_c="Es initialisiert die Ansible-Umgebung."
    answer_d="Es speichert Informationen über verwaltete Hosts."
    ;;
  "es")
    question="¿Cuál es el propósito de un rol de Ansible?"
    hint="Considera cómo los roles ayudan a organizar y reutilizar tareas de automatización."
    instructions="[
                  {
                    \"instruction\": \"Los roles agrupan tareas, variables, manejadores y plantillas relacionadas en componentes reutilizables\",
                    \"command\": \"ansible-galaxy init <role_name>\"
                  },
                  {
                    \"instruction\": \"Simplifican configuraciones complejas promoviendo la modularidad y la reutilización\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml --tags <role_name>\"
                  }
                ]"
    answer_a="Se utiliza para definir la secuencia de tareas en un playbook."
    answer_b="Agrupa tareas, variables y plantillas relacionadas en componentes reutilizables."  # Correct answer
    answer_c="Inicializa el entorno de Ansible."
    answer_d="Almacena información sobre los hosts gestionados."
    ;;
  "it")
    question="Qual è lo scopo di un ruolo Ansible?"
    hint="Considera come i ruoli aiutano a organizzare e riutilizzare le attività di automazione."
    instructions="[
                  {
                    \"instruction\": \"I ruoli raggruppano attività, variabili, gestori e modelli correlati in componenti riutilizzabili\",
                    \"command\": \"ansible-galaxy init <role_name>\"
                  },
                  {
                    \"instruction\": \"Semplificano configurazioni complesse promuovendo la modularità e la riutilizzabilità\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml --tags <role_name>\"
                  }
                ]"
    answer_a="È utilizzato per definire la sequenza delle attività in un playbook."
    answer_b="Raggruppa attività, variabili e modelli correlati in componenti riutilizzabili."  # Correct answer
    answer_c="Inizializza l'ambiente Ansible."
    answer_d="Memorizza informazioni sugli host gestiti."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of an Ansible role?"
    hint="Consider how roles help in organizing and reusing automation tasks."
    instructions="[
                  {
                    \"instruction\": \"Roles group related tasks, variables, handlers, and templates into reusable components\",
                    \"command\": \"ansible-galaxy init <role_name>\"
                  },
                  {
                    \"instruction\": \"They simplify complex configurations by promoting modularity and reusability\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml --tags <role_name>\"
                  }
                ]"
    answer_a="It is used to define the sequence of tasks in a playbook."
    answer_b="It groups related tasks, variables, and templates into reusable components."  # Correct answer
    answer_c="It initializes the Ansible environment."
    answer_d="It stores information about managed hosts."
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