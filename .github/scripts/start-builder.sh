#!/usr/bin/env bash
# - ephemeral client key, generated here and discarded with the runner
# - the container generates its host key at start; it is pinned into
#   /root/.ssh/known_hosts (nix-daemon runs as root and does the SSH itself)
set -euo pipefail

ref="$1"
port=3083
key="$RUNNER_TEMP/builder_key"

docker pull --platform linux/amd64 "$ref"
ssh-keygen -q -t ed25519 -N "" -f "$key"
docker run -d --rm --name builder --platform linux/amd64 -p "127.0.0.1:${port}:22" \
  --security-opt no-new-privileges "$ref" "$(cat "${key}.pub")"

for _ in $(seq 1 60); do
  docker exec builder test -f /etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null \
    && ssh-keyscan -p "$port" 127.0.0.1 >/dev/null 2>&1 && break
  sleep 2
done

sudo install -d -m 700 /root/.ssh
docker exec builder cat /etc/ssh/ssh_host_ed25519_key.pub \
  | awk '{ print "builder " $1 " " $2 }' | sudo tee /root/.ssh/known_hosts >/dev/null
sudo install -m 600 "$key" /root/.ssh/builder_key
sudo tee /root/.ssh/config >/dev/null <<EOF
Host builder
  HostName 127.0.0.1
  Port ${port}
  User root
  IdentityFile /root/.ssh/builder_key
  IdentitiesOnly yes
  HostKeyAlias builder
  UserKnownHostsFile /root/.ssh/known_hosts
  StrictHostKeyChecking yes
EOF
sudo chmod 600 /root/.ssh/config /root/.ssh/known_hosts

# test
echo "--- builder smoke test"
docker exec builder uname -m || true
docker exec builder /root/.nix-profile/bin/nix-store --version || echo "nix-store via docker exec: FAILED ($?)"
sudo -H ssh -F /root/.ssh/config builder 'echo ssh-ok; echo "PATH=$PATH"' || echo "ssh plain command: FAILED ($?)"
sudo -H ssh -F /root/.ssh/config builder 'nix-store --version' || echo "nix-store via ssh: FAILED ($?)"
sudo -H ssh -F /root/.ssh/config builder 'nix-store --serve --write </dev/null' || echo "nix-store --serve via ssh: FAILED ($?)"
