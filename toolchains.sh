#!/usr/bin/env bash
# Install per-user toolchains for buildkite-agent on mercury, no sudo:
# Rust (rustup, minimal + clippy + rustfmt) in ~/.cargo, Node LTS in
# ~/.local/node, pnpm through corepack in ~/.local/bin. Idempotent.
#
# The root disk is nearly full, so ~/.cargo, ~/.rustup, ~/.local and
# ~/.cache live on the big disk under $DATA_DIR and are symlinked from home.
# DATA_DIR has to exist and belong to buildkite-agent (one sudo, once):
#   sudo install -d -o buildkite-agent -g buildkite-agent /mnt/sda4/buildkite-agent
#
#   cd ~/projects/github.com/martin-janci/mercury-snapshots
#   mercury-run --timeout 30 bash setup/toolchains.sh
set -euo pipefail

data=${DATA_DIR:-/mnt/sda4/buildkite-agent}
if [[ ! -w $data ]]; then
  echo "$data is missing or not writable by $(id -un); create it once with:" >&2
  echo "  sudo install -d -o $(id -un) -g $(id -gn) $data" >&2
  exit 1
fi
for d in cargo rustup local cache; do
  if [[ -d ~/.$d && ! -L ~/.$d ]]; then
    mkdir -p "$data/$d" && cp -a ~/."$d"/. "$data/$d"/ && rm -rf ~/."$d"
  fi
  mkdir -p "$data/$d"
  ln -sfn "$data/$d" ~/."$d"
done

need_gb=${NEED_FREE_GB:-10}
free_gb=$(df -Pk "$data" | awk 'NR == 2 { print int($4 / 1024 / 1024) }')
if ((free_gb < need_gb)); then
  echo "only ${free_gb} GB free on $data; need ${need_gb} GB (NEED_FREE_GB overrides)" >&2
  exit 1
fi

mkdir -p ~/.local/bin
if [[ ! -x ~/.cargo/bin/rustup ]]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --profile minimal --no-modify-path --component clippy,rustfmt
fi
~/.cargo/bin/rustup update stable --no-self-update
~/.cargo/bin/rustc --version

arch=$(uname -m); case $arch in x86_64) arch=x64 ;; aarch64) arch=arm64 ;; esac
index=https://nodejs.org/dist/latest-v22.x
file=$(curl -fsS "$index/SHASUMS256.txt" | awk -v a="linux-$arch.tar.xz" '$2 ~ a"$" { print $2 }')
if [[ ! -d ~/.local/node || $(~/.local/node/bin/node --version) != "$(echo "$file" | cut -d- -f2)" ]]; then
  tmp=$(mktemp -d)
  curl -fsS -o "$tmp/$file" "$index/$file"
  (cd "$tmp" && curl -fsS "$index/SHASUMS256.txt" | grep " $file\$" | sha256sum -c -)
  rm -rf ~/.local/node.new && mkdir -p ~/.local/node.new
  tar -xJf "$tmp/$file" -C ~/.local/node.new --strip-components=1
  rm -rf ~/.local/node && mv ~/.local/node.new ~/.local/node && rm -rf "$tmp"
fi
~/.local/node/bin/node --version
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 ~/.local/node/bin/corepack enable --install-directory ~/.local/bin pnpm
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 ~/.local/bin/pnpm --version

df -h "$data" | tail -1
