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
    question="How does Ansible handle idempotency in its modules?"
    hint="Think about how Ansible ensures tasks do not cause repeated changes."
    instructions="[
                  {
                    \"instruction\": \"Ansible modules are designed to be idempotent, meaning they check the state of the system before making changes.\",
                    \"command\": \"#Ensure tasks are idempotent by validating their effects through the module's logic.\"
                  },
                  {
                    \"instruction\": \"This ensures changes are only applied if the desired state is not already met.\",
                    \"command\": \"#Run playbooks multiple times to observe idempotent behavior.\"
                  }
                ]"
    answer_a="Ansible retries tasks until the desired state is achieved."
    answer_b="Ansible modules are idempotent, applying changes only when needed."  # Correct answer
    answer_c="Ansible executes tasks repeatedly to ensure consistency."
    answer_d="Ansible uses 'retry logic' to handle repeated tasks."
    ;;
  "fr")
    question="Comment Ansible gère-t-il l'idempotence dans ses modules ?"
    hint="Pensez à la manière dont Ansible garantit que les tâches ne provoquent pas de modifications répétées."
    instructions="[
                  {
                    \"instruction\": \"Les modules Ansible sont conçus pour être idempotents, c'est-à-dire qu'ils vérifient l'état du système avant de procéder aux modifications.\",
                    \"command\": \"#Assurez-vous que les tâches sont idempotentes en validant leurs effets grâce à la logique du module.\"
                  },
                  {
                    \"instruction\": \"Cela garantit que les modifications ne sont appliquées que si l'état souhaité n'est pas déjà atteint.\",
                    \"command\": \"#Exécutez les playbooks plusieurs fois pour observer le comportement idempotent.\"
                  }
                ]"
    answer_a="Ansible réessaie les tâches jusqu'à ce que l'état souhaité soit atteint."
    answer_b="Les modules Ansible sont idempotents, appliquant des modifications uniquement lorsque cela est nécessaire."  # Correct answer
    answer_c="Ansible exécute les tâches de manière répétée pour garantir la cohérence."
    answer_d="Ansible utilise une 'logique de réessai' pour gérer les tâches répétées."
    ;;
  "es")
    question="¿Cómo maneja Ansible la idempotencia en sus módulos?"
    hint="Piensa en cómo Ansible garantiza que las tareas no causen cambios repetidos."
    instructions="[
                  {
                    \"instruction\": \"Los módulos de Ansible están diseñados para ser idempotentes, es decir, verifican el estado del sistema antes de realizar cambios.\",
                    \"command\": \"#Asegúrate de que las tareas sean idempotentes validando sus efectos a través de la lógica del módulo.\"
                  },
                  {
                    \"instruction\": \"Esto garantiza que los cambios solo se apliquen si el estado deseado aún no se ha alcanzado.\",
                    \"command\": \"#Ejecuta los playbooks varias veces para observar el comportamiento idempotente.\"
                  }
                ]"
    answer_a="Ansible reintenta las tareas hasta que se logra el estado deseado."
    answer_b="Los módulos de Ansible son idempotentes, aplicando cambios solo cuando es necesario."  # Correct answer
    answer_c="Ansible ejecuta las tareas repetidamente para garantizar la consistencia."
    answer_d="Ansible utiliza 'lógica de reintento' para manejar tareas repetidas."
    ;;
  "it")
    question="Come gestisce Ansible l'idempotenza nei suoi moduli?"
    hint="Pensa a come Ansible garantisce che le attività non causino modifiche ripetute."
    instructions="[
                  {
                    \"instruction\": \"I moduli Ansible sono progettati per essere idempotenti, ovvero controllano lo stato del sistema prima di apportare modifiche.\",
                    \"command\": \"# Garantire che le attività siano idempotenti convalidando i loro effetti tramite la logica del modulo.\"
                  },
                  {
                    \"instruction\": \"Ciò garantisce che le modifiche vengano applicate solo se lo stato desiderato non è già stato raggiunto.\",
                    \"command\": \"# Esegui i playbook più volte per osservare il comportamento idempotente.\"
                  }
                ]"
    answer_a="Ansible ripete le attività fino a quando non viene raggiunto lo stato desiderato."
    answer_b="I moduli Ansible sono idempotenti, applicando modifiche solo quando necessario."  # Correct answer
    answer_c="Ansible esegue ripetutamente le attività per garantire la coerenza."
    answer_d="Ansible utilizza la 'logica di ripetizione' per gestire attività ripetute."
    ;;
  "de")
    question="Wie geht Ansible mit Idempotenz in seinen Modulen um?"
    hint="Denken Sie darüber nach, wie Ansible sicherstellt, dass Aufgaben keine wiederholten Änderungen verursachen."
    instructions="[
                  {
                    \"instruction\": \"Ansible-Module sind so gestaltet, dass sie idempotent sind, was bedeutet, dass sie den Zustand des Systems überprüfen, bevor Änderungen vorgenommen werden.\",
                    \"command\": \"# Stellen Sie sicher, dass Aufgaben idempotent sind, indem Sie ihre Auswirkungen durch die Logik des Moduls überprüfen.\"
                  },
                  {
                    \"instruction\": \"Dies stellt sicher, dass Änderungen nur angewendet werden, wenn der gewünschte Zustand noch nicht erreicht ist.\",
                    \"command\": \"# Führen Sie Playbooks mehrmals aus, um idempotentes Verhalten zu beobachten.\"
                  }
                ]"
    answer_a="Ansible wiederholt Aufgaben, bis der gewünschte Zustand erreicht ist."
    answer_b="Ansible-Module sind idempotent und wenden Änderungen nur an, wenn sie erforderlich sind."  # Correct answer
    answer_c="Ansible führt Aufgaben wiederholt aus, um Konsistenz zu gewährleisten."
    answer_d="Ansible verwendet 'Retry-Logik', um wiederholte Aufgaben zu handhaben."
    ;;
  *)
    # Default to English if the language is not supported
    question="How does Ansible handle idempotency in its modules?"
    hint="Think about how Ansible ensures tasks do not cause repeated changes."
    instructions="[
                  {
                    \"instruction\": \"Ansible modules are designed to be idempotent, meaning they check the state of the system before making changes.\",
                    \"command\": \"#Ensure tasks are idempotent by validating their effects through the module's logic.\"
                  },
                  {
                    \"instruction\": \"This ensures changes are only applied if the desired state is not already met.\",
                    \"command\": \"#Run playbooks multiple times to observe idempotent behavior.\"
                  }
                ]"
    answer_a="Ansible retries tasks until the desired state is achieved."
    answer_b="Ansible modules are idempotent, applying changes only when needed."  # Correct answer
    answer_c="Ansible executes tasks repeatedly to ensure consistency."
    answer_d="Ansible uses 'retry logic' to handle repeated tasks."
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
