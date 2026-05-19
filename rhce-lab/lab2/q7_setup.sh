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
    question="What is the purpose of the Ansible 'gather_facts' module?"
    hint="Think about how Ansible collects information about managed hosts."
    instructions="[
                  {
                    \"instruction\": \"The 'gather_facts' module collects detailed information about managed hosts, such as operating system, network interfaces, and hardware\",
                    \"command\": \"- name: Gather facts\n  gather_facts: yes\"
                  },
                  {
                    \"instruction\": \"This information is stored as variables and can be used in playbooks for conditional logic or dynamic configurations\",
                    \"command\": \"- debug:\n    var: ansible_facts\"
                  }
                ]"
    answer_a="It collects system information about managed hosts and stores it as variables."  # Correct answer
    answer_b="It executes playbooks on managed hosts."
    answer_c="It initializes the Ansible control node for task execution."
    answer_d="It sets up user authentication on managed hosts."
    ;;
  "fr")
    question="Quel est l'objectif du module Ansible 'gather_facts' ?"
    hint="Réfléchissez à la manière dont Ansible collecte des informations sur les hôtes gérés."
    instructions="[
                  {
                    \"instruction\": \"Le module 'gather_facts' collecte des informations détaillées sur les hôtes gérés, telles que le système d'exploitation, les interfaces réseau et le matériel\",
                    \"command\": \"- name: Collecter les informations\n  gather_facts: yes\"
                  },
                  {
                    \"instruction\": \"Ces informations sont stockées sous forme de variables et peuvent être utilisées dans les playbooks pour une logique conditionnelle ou des configurations dynamiques\",
                    \"command\": \"- debug:\n    var: ansible_facts\"
                  }
                ]"
    answer_a="Il collecte des informations système sur les hôtes gérés et les stocke sous forme de variables."  # Correct answer
    answer_b="Il exécute des playbooks sur les hôtes gérés."
    answer_c="Il initialise le nœud de contrôle Ansible pour l'exécution des tâches."
    answer_d="Il configure l'authentification des utilisateurs sur les hôtes gérés."
    ;;
  "de")
    question="Was ist der Zweck des Ansible-Moduls 'gather_facts'?"
    hint="Denken Sie darüber nach, wie Ansible Informationen über verwaltete Hosts sammelt."
    instructions="[
                  {
                    \"instruction\": \"Das Modul 'gather_facts' sammelt detaillierte Informationen über verwaltete Hosts, wie Betriebssystem, Netzwerkschnittstellen und Hardware\",
                    \"command\": \"- name: Informationen sammeln\n  gather_facts: yes\"
                  },
                  {
                    \"instruction\": \"Diese Informationen werden als Variablen gespeichert und können in Playbooks für bedingte Logik oder dynamische Konfigurationen verwendet werden\",
                    \"command\": \"- debug:\n    var: ansible_facts\"
                  }
                ]"
    answer_a="Es sammelt Systeminformationen über verwaltete Hosts und speichert sie als Variablen."  # Correct answer
    answer_b="Es führt Playbooks auf verwalteten Hosts aus."
    answer_c="Es initialisiert den Ansible-Steuerknoten für die Aufgabenausführung."
    answer_d="Es richtet die Benutzerauthentifizierung auf verwalteten Hosts ein."
    ;;
  "es")
    question="¿Cuál es el propósito del módulo 'gather_facts' de Ansible?"
    hint="Piensa en cómo Ansible recopila información sobre los hosts gestionados."
    instructions="[
                  {
                    \"instruction\": \"El módulo 'gather_facts' recopila información detallada sobre los hosts gestionados, como el sistema operativo, las interfaces de red y el hardware\",
                    \"command\": \"- name: Recopilar información\n  gather_facts: yes\"
                  },
                  {
                    \"instruction\": \"Esta información se almacena como variables y se puede utilizar en los playbooks para lógica condicional o configuraciones dinámicas\",
                    \"command\": \"- debug:\n    var: ansible_facts\"
                  }
                ]"
    answer_a="Recopila información del sistema sobre los hosts gestionados y la almacena como variables."  # Correct answer
    answer_b="Ejecuta playbooks en los hosts gestionados."
    answer_c="Inicializa el nodo de control de Ansible para la ejecución de tareas."
    answer_d="Configura la autenticación de usuarios en los hosts gestionados."
    ;;
  "it")
    question="Qual è lo scopo del modulo Ansible 'gather_facts'?"
    hint="Pensa a come Ansible raccoglie informazioni sugli host gestiti."
    instructions="[
                  {
                    \"instruction\": \"Il modulo 'gather_facts' raccoglie informazioni dettagliate sugli host gestiti, come il sistema operativo, le interfacce di rete e l'hardware\",
                    \"command\": \"- name: Raccogli informazioni\n  gather_facts: yes\"
                  },
                  {
                    \"instruction\": \"Queste informazioni sono memorizzate come variabili e possono essere utilizzate nei playbook per logica condizionale o configurazioni dinamiche\",
                    \"command\": \"- debug:\n    var: ansible_facts\"
                  }
                ]"
    answer_a="Raccoglie informazioni di sistema sugli host gestiti e le memorizza come variabili."  # Correct answer
    answer_b="Esegue playbook sugli host gestiti."
    answer_c="Inizializza il nodo di controllo di Ansible per l'esecuzione delle attività."
    answer_d="Configura l'autenticazione degli utenti sugli host gestiti."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the Ansible 'gather_facts' module?"
    hint="Think about how Ansible collects information about managed hosts."
    instructions="[
                  {
                    \"instruction\": \"The 'gather_facts' module collects detailed information about managed hosts, such as operating system, network interfaces, and hardware\",
                    \"command\": \"- name: Gather facts\n  gather_facts: yes\"
                  },
                  {
                    \"instruction\": \"This information is stored as variables and can be used in playbooks for conditional logic or dynamic configurations\",
                    \"command\": \"- debug:\n    var: ansible_facts\"
                  }
                ]"
    answer_a="It collects system information about managed hosts and stores it as variables."  # Correct answer
    answer_b="It executes playbooks on managed hosts."
    answer_c="It initializes the Ansible control node for task execution."
    answer_d="It sets up user authentication on managed hosts."
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