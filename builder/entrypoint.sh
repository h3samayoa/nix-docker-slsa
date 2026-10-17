#!/usr/bin/env bash
# ephemeral host keys are generated at container start
set -euo pipefail

if [ $# -ne 1 ] || [ -z "$1" ]; then
  echo "usage: $0 '<ssh public key>'" >&2
  exit 64
fi

install -d -m 700 /root/.ssh
printf '%s\n' "$1" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  ssh-keygen -q -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key
fi
chmod 600 /etc/ssh/ssh_host_ed25519_key

sshd="$(readlink -f "$(command -v sshd)")"
"$sshd" -t
exec "$sshd" -D -e
