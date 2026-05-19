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
    question="How does Ansible execute tasks on remote systems?"
    hint="Think about how Ansible communicates without requiring a special agent."
    instructions="[
                  {
                    \"instruction\": \"Ansible uses SSH to connect to remote systems and execute tasks\",
                    \"command\": \"ansible all -m ping -i inventory\"
                  },
                  {
                    \"instruction\": \"No agent is required on the managed nodes, making Ansible lightweight and easy to deploy\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="It uses an agent installed on each managed node."
    answer_b="It communicates with managed nodes using the HTTP protocol."
    answer_c="It uses SSH to execute tasks on remote systems without requiring an agent."  # Correct answer
    answer_d="It relies on cloud APIs for task execution."
    ;;
  "fr")
    question="Comment Ansible exécute-t-il des tâches sur des systèmes distants ?"
    hint="Réfléchissez à la manière dont Ansible communique sans nécessiter d'agent spécial."
    instructions="[
                  {
                    \"instruction\": \"Ansible utilise SSH pour se connecter aux systèmes distants et exécuter des tâches\",
                    \"command\": \"ansible all -m ping -i inventory\"
                  },
                  {
                    \"instruction\": \"Aucun agent n'est requis sur les nœuds gérés, ce qui rend Ansible léger et facile à déployer\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="Il utilise un agent installé sur chaque nœud géré."
    answer_b="Il communique avec les nœuds gérés en utilisant le protocole HTTP."
    answer_c="Il utilise SSH pour exécuter des tâches sur des systèmes distants sans nécessiter d'agent."  # Correct answer
    answer_d="Il s'appuie sur les API cloud pour l'exécution des tâches."
    ;;
  "de")
    question="Wie führt Ansible Aufgaben auf entfernten Systemen aus?"
    hint="Denken Sie darüber nach, wie Ansible ohne einen speziellen Agenten kommuniziert."
    instructions="[
                  {
                    \"instruction\": \"Ansible verwendet SSH, um eine Verbindung zu entfernten Systemen herzustellen und Aufgaben auszuführen\",
                    \"command\": \"ansible all -m ping -i inventory\"
                  },
                  {
                    \"instruction\": \"Auf den verwalteten Knoten ist kein Agent erforderlich, was Ansible leichtgewichtig und einfach zu implementieren macht\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="Es verwendet einen Agenten, der auf jedem verwalteten Knoten installiert ist."
    answer_b="Es kommuniziert mit verwalteten Knoten über das HTTP-Protokoll."
    answer_c="Es verwendet SSH, um Aufgaben auf entfernten Systemen auszuführen, ohne einen Agenten zu benötigen."  # Correct answer
    answer_d="Es verlässt sich auf Cloud-APIs für die Aufgabenausführung."
    ;;
  "es")
    question="¿Cómo ejecuta Ansible tareas en sistemas remotos?"
    hint="Piensa en cómo Ansible se comunica sin requerir un agente especial."
    instructions="[
                  {
                    \"instruction\": \"Ansible utiliza SSH para conectarse a sistemas remotos y ejecutar tareas\",
                    \"command\": \"ansible all -m ping -i inventory\"
                  },
                  {
                    \"instruction\": \"No se requiere ningún agente en los nodos gestionados, lo que hace que Ansible sea ligero y fácil de implementar\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="Utiliza un agente instalado en cada nodo gestionado."
    answer_b="Se comunica con los nodos gestionados utilizando el protocolo HTTP."
    answer_c="Utiliza SSH para ejecutar tareas en sistemas remotos sin requerir un agente."  # Correct answer
    answer_d="Depende de las API de la nube para la ejecución de tareas."
    ;;
  "it")
    question="Come esegue Ansible le attività sui sistemi remoti?"
    hint="Pensa a come Ansible comunica senza richiedere un agente speciale."
    instructions="[
                  {
                    \"instruction\": \"Ansible utilizza SSH per connettersi ai sistemi remoti ed eseguire attività\",
                    \"command\": \"ansible all -m ping -i inventory\"
                  },
                  {
                    \"instruction\": \"Non è richiesto alcun agente sui nodi gestiti, rendendo Ansible leggero e facile da distribuire\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="Utilizza un agente installato su ciascun nodo gestito."
    answer_b="Comunica con i nodi gestiti utilizzando il protocollo HTTP."
    answer_c="Utilizza SSH per eseguire attività su sistemi remoti senza richiedere un agente."  # Correct answer
    answer_d="Si affida alle API cloud per l'esecuzione delle attività."
    ;;
  *)
    # Default to English if the language is not supported
    question="How does Ansible execute tasks on remote systems?"
    hint="Think about how Ansible communicates without requiring a special agent."
    instructions="[
                  {
                    \"instruction\": \"Ansible uses SSH to connect to remote systems and execute tasks\",
                    \"command\": \"ansible all -m ping -i inventory\"
                  },
                  {
                    \"instruction\": \"No agent is required on the managed nodes, making Ansible lightweight and easy to deploy\",
                    \"command\": \"ansible-playbook -i inventory playbook.yml\"
                  }
                ]"
    answer_a="It uses an agent installed on each managed node."
    answer_b="It communicates with managed nodes using the HTTP protocol."
    answer_c="It uses SSH to execute tasks on remote systems without requiring an agent."  # Correct answer
    answer_d="It relies on cloud APIs for task execution."
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