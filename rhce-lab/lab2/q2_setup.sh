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
    question="What is the purpose of the Ansible inventory file?"
    hint="Think about how Ansible keeps track of the hosts it manages."
    instructions="[
                  {
                    \"instruction\": \"The inventory file defines the list of hosts (managed nodes) Ansible can operate on\",
                    \"command\": \"cat /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"It can also include optional variables for those hosts, such as connection details or group memberships\",
                    \"command\": \"ansible-inventory --list\"
                  }
                ]"
    answer_a="It is a YAML file that defines automation tasks for specific systems."
    answer_b="It is a configuration file for Ansible's control node setup."
    answer_c="It defines a list of managed hosts and associated variables."  # Correct answer
    answer_d="It contains playbooks to be executed in sequential order."
    ;;
  "fr")
    question="Quel est l'objectif du fichier d'inventaire Ansible ?"
    hint="Réfléchissez à la façon dont Ansible garde une trace des hôtes qu'il gère."
    instructions="[
                  {
                    \"instruction\": \"Le fichier d'inventaire définit la liste des hôtes (nœuds gérés) sur lesquels Ansible peut opérer\",
                    \"command\": \"cat /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"Il peut également inclure des variables optionnelles pour ces hôtes, telles que les détails de connexion ou les appartenances à des groupes\",
                    \"command\": \"ansible-inventory --list\"
                  }
                ]"
    answer_a="C'est un fichier YAML qui définit des tâches d'automatisation pour des systèmes spécifiques."
    answer_b="C'est un fichier de configuration pour la configuration du nœud de contrôle d'Ansible."
    answer_c="Il définit une liste d'hôtes gérés et les variables associées."  # Correct answer
    answer_d="Il contient des playbooks à exécuter dans un ordre séquentiel."
    ;;
  "de")
    question="Was ist der Zweck der Ansible-Inventardatei?"
    hint="Denken Sie darüber nach, wie Ansible die von ihm verwalteten Hosts im Auge behält."
    instructions="[
                  {
                    \"instruction\": \"Die Inventardatei definiert die Liste der Hosts (verwaltete Knoten), auf denen Ansible arbeiten kann\",
                    \"command\": \"cat /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"Sie kann auch optionale Variablen für diese Hosts enthalten, wie Verbindungsdetails oder Gruppenzugehörigkeiten\",
                    \"command\": \"ansible-inventory --list\"
                  }
                ]"
    answer_a="Es ist eine YAML-Datei, die Automatisierungsaufgaben für bestimmte Systeme definiert."
    answer_b="Es ist eine Konfigurationsdatei für die Einrichtung des Ansible-Steuerknotens."
    answer_c="Es definiert eine Liste von verwalteten Hosts und zugehörigen Variablen."  # Correct answer
    answer_d="Es enthält Playbooks, die in sequentieller Reihenfolge ausgeführt werden sollen."
    ;;
  "es")
    question="¿Cuál es el propósito del archivo de inventario de Ansible?"
    hint="Piensa en cómo Ansible lleva un registro de los hosts que gestiona."
    instructions="[
                  {
                    \"instruction\": \"El archivo de inventario define la lista de hosts (nodos gestionados) en los que Ansible puede operar\",
                    \"command\": \"cat /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"También puede incluir variables opcionales para esos hosts, como detalles de conexión o membresías de grupo\",
                    \"command\": \"ansible-inventory --list\"
                  }
                ]"
    answer_a="Es un archivo YAML que define tareas de automatización para sistemas específicos."
    answer_b="Es un archivo de configuración para la configuración del nodo de control de Ansible."
    answer_c="Define una lista de hosts gestionados y variables asociadas."  # Correct answer
    answer_d="Contiene playbooks que se ejecutarán en orden secuencial."
    ;;
  "it")
    question="Qual è lo scopo del file di inventario di Ansible?"
    hint="Pensa a come Ansible tiene traccia degli host che gestisce."
    instructions="[
                  {
                    \"instruction\": \"Il file di inventario definisce l'elenco degli host (nodi gestiti) su cui Ansible può operare\",
                    \"command\": \"cat /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"Può anche includere variabili opzionali per tali host, come dettagli di connessione o appartenenze a gruppi\",
                    \"command\": \"ansible-inventory --list\"
                  }
                ]"
    answer_a="È un file YAML che definisce attività di automazione per sistemi specifici."
    answer_b="È un file di configurazione per la configurazione del nodo di controllo di Ansible."
    answer_c="Definisce un elenco di host gestiti e variabili associate."  # Correct answer
    answer_d="Contiene playbook da eseguire in ordine sequenziale."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the Ansible inventory file?"
    hint="Think about how Ansible keeps track of the hosts it manages."
    instructions="[
                  {
                    \"instruction\": \"The inventory file defines the list of hosts (managed nodes) Ansible can operate on\",
                    \"command\": \"cat /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"It can also include optional variables for those hosts, such as connection details or group memberships\",
                    \"command\": \"ansible-inventory --list\"
                  }
                ]"
    answer_a="It is a YAML file that defines automation tasks for specific systems."
    answer_b="It is a configuration file for Ansible's control node setup."
    answer_c="It defines a list of managed hosts and associated variables."  # Correct answer
    answer_d="It contains playbooks to be executed in sequential order."
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