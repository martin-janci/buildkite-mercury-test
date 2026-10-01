set -eu
to='git@github-snapshots:martin-janci/mercury-snapshots.git'
git config --global --unset-all "url.$to.insteadOf" || true
for from in https://github.com/martin-janci/mercury-snapshots.git \
            https://github.com/martin-janci/mercury-snapshots \
            git@github.com:martin-janci/mercury-snapshots.git; do
  git config --global --add "url.$to.insteadOf" "$from"
done
git config --global --get-all "url.$to.insteadOf"
GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/martin-janci/mercury-snapshots.git refs/heads/main
