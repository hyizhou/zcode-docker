#!/bin/bash
# Shared readiness gate for s6-rc oneshots: block until a unix socket exists.

socket_path="$1"
service_name="${2:-service}"

for _ in $(seq 1 100); do
  if [[ -S "$socket_path" ]]; then
    exit 0
  fi
  sleep 0.1
done

echo "ERROR: ${service_name} did not create ${socket_path} within 10 seconds." >&2
exit 1
