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
    question="What is the purpose of an Ansible playbook?"
    hint="Think about how Ansible automates tasks and organizes configurations."
    instructions="[
                  {
                    \"instruction\": \"A playbook is a YAML file that defines tasks to be executed on remote systems\",
                    \"command\": \"ansible-playbook playbook.yml\"
                  },
                  {
                    \"instruction\": \"It organizes tasks into structured automation workflows, specifying modules, configurations, and execution order\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="It is a file containing roles that Ansible executes sequentially."
    answer_b="It is a YAML file that defines tasks to be executed on remote systems."  # Correct answer
    answer_c="It contains configurations for setting up the Ansible control node."
    answer_d="It initializes the inventory for managing remote hosts."
    ;;
  "fr")
    question="Quel est l'objectif d'un playbook Ansible ?"
    hint="Réfléchissez à la façon dont Ansible automatise les tâches et organise les configurations."
    instructions="[
                  {
                    \"instruction\": \"Un playbook est un fichier YAML qui définit les tâches à exécuter sur des systèmes distants\",
                    \"command\": \"ansible-playbook playbook.yml\"
                  },
                  {
                    \"instruction\": \"Il organise les tâches en flux de travail d'automatisation structurés, en spécifiant les modules, les configurations et l'ordre d'exécution\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="C'est un fichier contenant des rôles qu'Ansible exécute séquentiellement."
    answer_b="C'est un fichier YAML qui définit les tâches à exécuter sur des systèmes distants."  # Correct answer
    answer_c="Il contient des configurations pour configurer le nœud de contrôle Ansible."
    answer_d="Il initialise l'inventaire pour gérer les hôtes distants."
    ;;
  "de")
    question="Was ist der Zweck eines Ansible Playbooks?"
    hint="Denken Sie darüber nach, wie Ansible Aufgaben automatisiert und Konfigurationen organisiert."
    instructions="[
                  {
                    \"instruction\": \"Ein Playbook ist eine YAML-Datei, die Aufgaben definiert, die auf Remote-Systemen ausgeführt werden sollen\",
                    \"command\": \"ansible-playbook playbook.yml\"
                  },
                  {
                    \"instruction\": \"Es organisiert Aufgaben in strukturierte Automatisierungsabläufe, gibt Module, Konfigurationen und die Ausführungsreihenfolge an\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="Es ist eine Datei, die Rollen enthält, die Ansible sequentiell ausführt."
    answer_b="Es ist eine YAML-Datei, die Aufgaben definiert, die auf Remote-Systemen ausgeführt werden sollen."  # Correct answer
    answer_c="Es enthält Konfigurationen für die Einrichtung des Ansible-Steuerknotens."
    answer_d="Es initialisiert das Inventar zur Verwaltung von Remote-Hosts."
    ;;
  "es")
    question="¿Cuál es el propósito de un playbook de Ansible?"
    hint="Piensa en cómo Ansible automatiza tareas y organiza configuraciones."
    instructions="[
                  {
                    \"instruction\": \"Un playbook es un archivo YAML que define tareas para ejecutar en sistemas remotos\",
                    \"command\": \"ansible-playbook playbook.yml\"
                  },
                  {
                    \"instruction\": \"Organiza tareas en flujos de trabajo de automatización estructurados, especificando módulos, configuraciones y el orden de ejecución\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="Es un archivo que contiene roles que Ansible ejecuta secuencialmente."
    answer_b="Es un archivo YAML que define tareas para ejecutar en sistemas remotos."  # Correct answer
    answer_c="Contiene configuraciones para configurar el nodo de control de Ansible."
    answer_d="Inicializa el inventario para gestionar hosts remotos."
    ;;
  "it")
    question="Qual è lo scopo di un playbook di Ansible?"
    hint="Pensa a come Ansible automatizza le attività e organizza le configurazioni."
    instructions="[
                  {
                    \"instruction\": \"Un playbook è un file YAML che definisce le attività da eseguire su sistemi remoti\",
                    \"command\": \"ansible-playbook playbook.yml\"
                  },
                  {
                    \"instruction\": \"Organizza le attività in flussi di lavoro di automazione strutturati, specificando moduli, configurazioni e ordine di esecuzione\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="È un file che contiene ruoli che Ansible esegue in sequenza."
    answer_b="È un file YAML che definisce le attività da eseguire su sistemi remoti."  # Correct answer
    answer_c="Contiene configurazioni per impostare il nodo di controllo di Ansible."
    answer_d="Inizializza l'inventario per gestire gli host remoti."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of an Ansible playbook?"
    hint="Think about how Ansible automates tasks and organizes configurations."
    instructions="[
                  {
                    \"instruction\": \"A playbook is a YAML file that defines tasks to be executed on remote systems\",
                    \"command\": \"ansible-playbook playbook.yml\"
                  },
                  {
                    \"instruction\": \"It organizes tasks into structured automation workflows, specifying modules, configurations, and execution order\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="It is a file containing roles that Ansible executes sequentially."
    answer_b="It is a YAML file that defines tasks to be executed on remote systems."  # Correct answer
    answer_c="It contains configurations for setting up the Ansible control node."
    answer_d="It initializes the inventory for managing remote hosts."
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