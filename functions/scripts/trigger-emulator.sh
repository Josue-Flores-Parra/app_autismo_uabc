#!/usr/bin/env bash
# Ejecuta sendConsentConfirmations una vez en el emulador de Functions.
#
# El emulador registra la función programada como suscriptor de Pub/Sub, pero
# no la dispara por horario ni siempre consume los mensajes publicados; este
# script llama directo al endpoint de disparadores del emulador.
#
# Uso: functions/scripts/trigger-emulator.sh [proyecto]   (por omisión demo-appy)
set -euo pipefail
project="${1:-demo-appy}"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' -X POST \
  "http://127.0.0.1:5001/functions/projects/${project}/triggers/us-central1-sendConsentConfirmations-0" \
  -H 'Content-Type: application/json' \
  -d "{\"specversion\":\"1.0\",\"id\":\"manual-${now}\",\"source\":\"//pubsub.googleapis.com/projects/${project}/topics/firebase-schedule-sendConsentConfirmations\",\"type\":\"google.cloud.pubsub.topic.v1.messagePublished\",\"time\":\"${now}\",\"data\":{\"message\":{\"data\":\"e30=\",\"messageId\":\"manual\",\"publishTime\":\"${now}\"},\"subscription\":\"projects/${project}/subscriptions/manual\"}}"
echo "Revisa el resultado en la terminal de los emuladores (\"Confirmaciones de consentimiento\")."
