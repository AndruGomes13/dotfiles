#!/usr/bin/env bash
# Start an Ubuntu container with these dotfiles (working tree) installed and sshd on
# localhost:2222, to try the setup over SSH.
#   connect: ssh -p 2222 dev@localhost
#   remove:  docker rm -f dotfiles-ssh
set -euo pipefail
cd "$(dirname "$0")/.."

keys=$(cat ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub 2>/dev/null || true)
[[ -n $keys ]] || { echo "error: no ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub" >&2; exit 1; }

docker build -q -t dotfiles-ssh - >/dev/null <<'EOF'
FROM ubuntu:24.04
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git openssh-server \
  && rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd
RUN useradd --create-home --shell /bin/bash dev
CMD ["/usr/sbin/sshd", "-D", "-e"]
EOF

docker rm -f dotfiles-ssh >/dev/null 2>&1 || true
docker run -d --name dotfiles-ssh --hostname devbox -p 127.0.0.1:2222:22 -v "$PWD:/src:ro" dotfiles-ssh >/dev/null
docker exec dotfiles-ssh install -d -m 700 -o dev -g dev /home/dev/.ssh
printf '%s\n' "$keys" | docker exec -i dotfiles-ssh install -m 600 -o dev -g dev /dev/stdin /home/dev/.ssh/authorized_keys

docker exec -u dev -e HOME=/home/dev -w /home/dev dotfiles-ssh bash -c '
  cp -R /src ~/origin && rm -rf ~/origin/.git
  git -C ~/origin init -q && git -C ~/origin add -A
  git -C ~/origin -c user.name=dev -c user.email=dev@example.com commit -qm snapshot
  DOTFILES_REPO=~/origin bash ~/origin/install.sh'

echo
echo "Ready: ssh -p 2222 dev@localhost"
