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
    question="What is the purpose of an Ansible handler?"
    hint="Think about how handlers relate to events triggered during playbook execution."
    instructions="[
                  {
                    \"instruction\": \"Handlers perform actions when notified by other tasks, such as restarting a service or reloading a configuration\",
                    \"command\": \"- name: Restart Apache\n  notify: Restart Apache Service\n\n- name: Restart Apache Service\n  service:\n    name: apache2\n    state: restarted\"
                  },
                  {
                    \"instruction\": \"Handlers are only executed if notified by a task, and they run at the end of a playbook execution\",
                    \"command\": \"- name: Reload Nginx\n  notify: Reload Nginx Service\n\n- name: Reload Nginx Service\n  service:\n    name: nginx\n    state: reloaded\"
                  }
                ]"
    answer_a="It is used to manage errors during playbook execution."
    answer_b="It defines conditional execution of tasks."
    answer_c="It performs actions triggered by notifications from other tasks."  # Correct answer
    answer_d="It initializes the inventory for managed nodes."
    ;;
  "fr")
    question="Quel est l'objectif d'un gestionnaire Ansible ?"
    hint="Réfléchissez à la manière dont les gestionnaires sont liés aux événements déclenchés lors de l'exécution d'un playbook."
    instructions="[
                  {
                    \"instruction\": \"Les gestionnaires effectuent des actions lorsqu'ils sont notifiés par d'autres tâches, comme redémarrer un service ou recharger une configuration\",
                    \"command\": \"- name: Redémarrer Apache\n  notify: Redémarrer le service Apache\n\n- name: Redémarrer le service Apache\n  service:\n    name: apache2\n    state: restarted\"
                  },
                  {
                    \"instruction\": \"Les gestionnaires ne sont exécutés que s'ils sont notifiés par une tâche, et ils s'exécutent à la fin de l'exécution d'un playbook\",
                    \"command\": \"- name: Recharger Nginx\n  notify: Recharger le service Nginx\n\n- name: Recharger le service Nginx\n  service:\n    name: nginx\n    state: reloaded\"
                  }
                ]"
    answer_a="Il est utilisé pour gérer les erreurs lors de l'exécution d'un playbook."
    answer_b="Il définit l'exécution conditionnelle des tâches."
    answer_c="Il effectue des actions déclenchées par des notifications d'autres tâches."  # Correct answer
    answer_d="Il initialise l'inventaire pour les nœuds gérés."
    ;;
  "de")
    question="Was ist der Zweck eines Ansible-Handlers?"
    hint="Denken Sie darüber nach, wie Handler mit Ereignissen zusammenhängen, die während der Playbook-Ausführung ausgelöst werden."
    instructions="[
                  {
                    \"instruction\": \"Handler führen Aktionen aus, wenn sie von anderen Aufgaben benachrichtigt werden, z. B. das Neustarten eines Dienstes oder das Neuladen einer Konfiguration\",
                    \"command\": \"- name: Apache neu starten\n  notify: Apache-Dienst neu starten\n\n- name: Apache-Dienst neu starten\n  service:\n    name: apache2\n    state: restarted\"
                  },
                  {
                    \"instruction\": \"Handler werden nur ausgeführt, wenn sie von einer Aufgabe benachrichtigt werden, und sie werden am Ende der Playbook-Ausführung ausgeführt\",
                    \"command\": \"- name: Nginx neu laden\n  notify: Nginx-Dienst neu laden\n\n- name: Nginx-Dienst neu laden\n  service:\n    name: nginx\n    state: reloaded\"
                  }
                ]"
    answer_a="Es wird verwendet, um Fehler während der Playbook-Ausführung zu verwalten."
    answer_b="Es definiert die bedingte Ausführung von Aufgaben."
    answer_c="Es führt Aktionen aus, die durch Benachrichtigungen von anderen Aufgaben ausgelöst werden."  # Correct answer
    answer_d="Es initialisiert das Inventar für verwaltete Knoten."
    ;;
  "es")
    question="¿Cuál es el propósito de un manejador de Ansible?"
    hint="Piensa en cómo los manejadores se relacionan con los eventos activados durante la ejecución del playbook."
    instructions="[
                  {
                    \"instruction\": \"Los manejadores realizan acciones cuando son notificados por otras tareas, como reiniciar un servicio o recargar una configuración\",
                    \"command\": \"- name: Reiniciar Apache\n  notify: Reiniciar el servicio de Apache\n\n- name: Reiniciar el servicio de Apache\n  service:\n    name: apache2\n    state: restarted\"
                  },
                  {
                    \"instruction\": \"Los manejadores solo se ejecutan si son notificados por una tarea, y se ejecutan al final de la ejecución del playbook\",
                    \"command\": \"- name: Recargar Nginx\n  notify: Recargar el servicio de Nginx\n\n- name: Recargar el servicio de Nginx\n  service:\n    name: nginx\n    state: reloaded\"
                  }
                ]"
    answer_a="Se utiliza para gestionar errores durante la ejecución del playbook."
    answer_b="Define la ejecución condicional de tareas."
    answer_c="Realiza acciones activadas por notificaciones de otras tareas."  # Correct answer
    answer_d="Inicializa el inventario para los nodos gestionados."
    ;;
  "it")
    question="Qual è lo scopo di un gestore Ansible?"
    hint="Pensa a come i gestori sono correlati agli eventi attivati durante l'esecuzione del playbook."
    instructions="[
                  {
                    \"instruction\": \"I gestori eseguono azioni quando vengono notificati da altre attività, come riavviare un servizio o ricaricare una configurazione\",
                    \"command\": \"- name: Riavvia Apache\n  notify: Riavvia il servizio Apache\n\n- name: Riavvia il servizio Apache\n  service:\n    name: apache2\n    state: restarted\"
                  },
                  {
                    \"instruction\": \"I gestori vengono eseguiti solo se notificati da un'attività e vengono eseguiti alla fine dell'esecuzione del playbook\",
                    \"command\": \"- name: Ricarica Nginx\n  notify: Ricarica il servizio Nginx\n\n- name: Ricarica il servizio Nginx\n  service:\n    name: nginx\n    state: reloaded\"
                  }
                ]"
    answer_a="È utilizzato per gestire gli errori durante l'esecuzione del playbook."
    answer_b="Definisce l'esecuzione condizionale delle attività."
    answer_c="Esegue azioni attivate da notifiche di altre attività."  # Correct answer
    answer_d="Inizializza l'inventario per i nodi gestiti."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of an Ansible handler?"
    hint="Think about how handlers relate to events triggered during playbook execution."
    instructions="[
                  {
                    \"instruction\": \"Handlers perform actions when notified by other tasks, such as restarting a service or reloading a configuration\",
                    \"command\": \"- name: Restart Apache\n  notify: Restart Apache Service\n\n- name: Restart Apache Service\n  service:\n    name: apache2\n    state: restarted\"
                  },
                  {
                    \"instruction\": \"Handlers are only executed if notified by a task, and they run at the end of a playbook execution\",
                    \"command\": \"- name: Reload Nginx\n  notify: Reload Nginx Service\n\n- name: Reload Nginx Service\n  service:\n    name: nginx\n    state: reloaded\"
                  }
                ]"
    answer_a="It is used to manage errors during playbook execution."
    answer_b="It defines conditional execution of tasks."
    answer_c="It performs actions triggered by notifications from other tasks."  # Correct answer
    answer_d="It initializes the inventory for managed nodes."
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