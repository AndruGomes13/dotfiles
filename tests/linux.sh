#!/usr/bin/env bash
# Install in a fresh Ubuntu container as a non-root user without sudo, twice, then verify.
# PLATFORM=linux/amd64 tests/linux.sh to test the other architecture.
set -euo pipefail
cd "$(dirname "$0")/.."
platform=${PLATFORM:-linux/$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')}
docker build -q --platform "$platform" -t "dotfiles-test:${platform#linux/}" tests >/dev/null
docker run --rm --platform "$platform" ${GITHUB_TOKEN:+-e GITHUB_TOKEN} -v "$PWD:/src:ro" \
  "dotfiles-test:${platform#linux/}" bash /src/tests/verify.sh
