set -eu
mkdir -p -m 700 ~/.ssh
key=~/.ssh/mercury_snapshots
[ -f "$key" ] || ssh-keygen -q -t ed25519 -N '' -C 'buildkite-agent@mercury: mercury-snapshots (read-only)' -f "$key"
if ! grep -q '^Host github-snapshots$' ~/.ssh/config 2>/dev/null; then
  cat >> ~/.ssh/config <<'CFG'
Host github-snapshots
  HostName github.com
  User git
  IdentityFile ~/.ssh/mercury_snapshots
  IdentitiesOnly yes
  HostKeyAlias github.com
CFG
fi
chmod 600 ~/.ssh/config
# Pin GitHub's published ed25519 host key instead of trusting whatever answers.
want='SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'
if ! ssh-keygen -F github.com -f ~/.ssh/known_hosts >/dev/null 2>&1; then
  ssh-keyscan -t ed25519 github.com 2>/dev/null > /tmp/gh_hostkey.$$
  got=$(ssh-keygen -lf /tmp/gh_hostkey.$$ | awk '{print $2}')
  [ "$got" = "$want" ] || { echo "github.com host key mismatch: $got"; exit 1; }
  cat /tmp/gh_hostkey.$$ >> ~/.ssh/known_hosts; rm -f /tmp/gh_hostkey.$$
fi
ssh-keygen -lf ~/.ssh/known_hosts | grep -c "$want" | sed 's/^/pinned github.com keys: /'
echo "PUBKEY $(cat "$key.pub")"
