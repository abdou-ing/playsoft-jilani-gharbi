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
    question="What is the purpose of the 'ansible.cfg' file?"
    hint="Think about where Ansible stores its default configurations."
    instructions="[
                  {
                    \"instruction\": \"The 'ansible.cfg' file defines default configurations for Ansible, such as inventory location and connection settings\",
                    \"command\": \"cat /etc/ansible/ansible.cfg\"
                  },
                  {
                    \"instruction\": \"It allows customization of Ansible's behavior, including roles path, logging, and plugin configurations\",
                    \"command\": \"ansible-config view\"
                  }
                ]"
    answer_a="It contains the list of playbooks to be executed."
    answer_b="It defines default configurations for Ansible, such as inventory location and connection settings."  # Correct answer
    answer_c="It is used to initialize the Ansible control node."
    answer_d="It is used to store sensitive credentials for managed nodes."
    ;;
  "fr")
    question="Quel est l'objectif du fichier 'ansible.cfg' ?"
    hint="Réfléchissez à l'endroit où Ansible stocke ses configurations par défaut."
    instructions="[
                  {
                    \"instruction\": \"Le fichier 'ansible.cfg' définit les configurations par défaut d'Ansible, telles que l'emplacement de l'inventaire et les paramètres de connexion\",
                    \"command\": \"cat /etc/ansible/ansible.cfg\"
                  },
                  {
                    \"instruction\": \"Il permet de personnaliser le comportement d'Ansible, y compris le chemin des rôles, la journalisation et les configurations des plugins\",
                    \"command\": \"ansible-config view\"
                  }
                ]"
    answer_a="Il contient la liste des playbooks à exécuter."
    answer_b="Il définit les configurations par défaut d'Ansible, telles que l'emplacement de l'inventaire et les paramètres de connexion."  # Correct answer
    answer_c="Il est utilisé pour initialiser le nœud de contrôle Ansible."
    answer_d="Il est utilisé pour stocker des informations d'identification sensibles pour les nœuds gérés."
    ;;
  "de")
    question="Was ist der Zweck der Datei 'ansible.cfg'?"
    hint="Denken Sie darüber nach, wo Ansible seine Standardkonfigurationen speichert."
    instructions="[
                  {
                    \"instruction\": \"Die Datei 'ansible.cfg' definiert Standardkonfigurationen für Ansible, wie den Speicherort des Inventars und Verbindungseinstellungen\",
                    \"command\": \"cat /etc/ansible/ansible.cfg\"
                  },
                  {
                    \"instruction\": \"Sie ermöglicht die Anpassung des Ansible-Verhaltens, einschließlich des Rollenpfads, der Protokollierung und der Plugin-Konfigurationen\",
                    \"command\": \"ansible-config view\"
                  }
                ]"
    answer_a="Sie enthält die Liste der auszuführenden Playbooks."
    answer_b="Sie definiert Standardkonfigurationen für Ansible, wie den Speicherort des Inventars und Verbindungseinstellungen."  # Correct answer
    answer_c="Sie wird verwendet, um den Ansible-Steuerknoten zu initialisieren."
    answer_d="Sie wird verwendet, um sensible Anmeldeinformationen für verwaltete Knoten zu speichern."
    ;;
  "es")
    question="¿Cuál es el propósito del archivo 'ansible.cfg'?"
    hint="Piensa en dónde Ansible almacena sus configuraciones predeterminadas."
    instructions="[
                  {
                    \"instruction\": \"El archivo 'ansible.cfg' define configuraciones predeterminadas para Ansible, como la ubicación del inventario y los ajustes de conexión\",
                    \"command\": \"cat /etc/ansible/ansible.cfg\"
                  },
                  {
                    \"instruction\": \"Permite personalizar el comportamiento de Ansible, incluyendo la ruta de roles, el registro y las configuraciones de plugins\",
                    \"command\": \"ansible-config view\"
                  }
                ]"
    answer_a="Contiene la lista de playbooks que se van a ejecutar."
    answer_b="Define configuraciones predeterminadas para Ansible, como la ubicación del inventario y los ajustes de conexión."  # Correct answer
    answer_c="Se utiliza para inicializar el nodo de control de Ansible."
    answer_d="Se utiliza para almacenar credenciales sensibles para los nodos gestionados."
    ;;
  "it")
    question="Qual è lo scopo del file 'ansible.cfg'?"
    hint="Pensa a dove Ansible memorizza le sue configurazioni predefinite."
    instructions="[
                  {
                    \"instruction\": \"Il file 'ansible.cfg' definisce le configurazioni predefinite per Ansible, come la posizione dell'inventario e le impostazioni di connessione\",
                    \"command\": \"cat /etc/ansible/ansible.cfg\"
                  },
                  {
                    \"instruction\": \"Consente di personalizzare il comportamento di Ansible, incluso il percorso dei ruoli, la registrazione e le configurazioni dei plugin\",
                    \"command\": \"ansible-config view\"
                  }
                ]"
    answer_a="Contiene l'elenco dei playbook da eseguire."
    answer_b="Definisce le configurazioni predefinite per Ansible, come la posizione dell'inventario e le impostazioni di connessione."  # Correct answer
    answer_c="Viene utilizzato per inizializzare il nodo di controllo di Ansible."
    answer_d="Viene utilizzato per memorizzare credenziali sensibili per i nodi gestiti."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the 'ansible.cfg' file?"
    hint="Think about where Ansible stores its default configurations."
    instructions="[
                  {
                    \"instruction\": \"The 'ansible.cfg' file defines default configurations for Ansible, such as inventory location and connection settings\",
                    \"command\": \"cat /etc/ansible/ansible.cfg\"
                  },
                  {
                    \"instruction\": \"It allows customization of Ansible's behavior, including roles path, logging, and plugin configurations\",
                    \"command\": \"ansible-config view\"
                  }
                ]"
    answer_a="It contains the list of playbooks to be executed."
    answer_b="It defines default configurations for Ansible, such as inventory location and connection settings."  # Correct answer
    answer_c="It is used to initialize the Ansible control node."
    answer_d="It is used to store sensitive credentials for managed nodes."
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