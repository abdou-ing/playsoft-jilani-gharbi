#!/bin/bash
WATCH_DIR="/home/<candidate_lab_user>/workspace"
TARGET_USER="<candidate_lab_user>"

inotifywait -m -r -e create,moved_to,close_write --format '%w%f' "${WATCH_DIR}" | while read FILE; do
    chown ${TARGET_USER}:${TARGET_USER} "${FILE}" 2>/dev/null || true
done