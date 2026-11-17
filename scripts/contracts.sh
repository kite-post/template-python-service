#!/usr/bin/env bash
# Підключає kite-contracts за тегом: make contracts V=0.2.0 розставляє версію в
# Makefile і pyproject.toml і ставить пакет. Без V — ставить поточну версію.
# Цим самим викликом користується CI, коли kite-contracts випускає новий тег.
#
# Python-пакет не публікується в реєстр: pip бере його з git за тегом, з
# підкаталогу python/ (5.6). CONTRACTS_REPO — щоб підставити дзеркало чи форк.
set -euo pipefail

v="${1:?вкажи версію: scripts/contracts.sh 0.2.0}"
printf '%s' "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' \
  || { echo "contracts: версія «$v» має бути вигляду 1.2.3" >&2; exit 1; }
repo="${CONTRACTS_REPO:-https://github.com/${ORG:-kite-post}/kite-contracts.git}"
spec="kite-contracts @ git+${repo}@v${v}#subdirectory=python"
python="${PYTHON:-python3}"

# Правка атомарна: якщо тег не знайдеться, файли повертаються як були, і
# Makefile не розійдеться з pyproject.toml.
backup="$(mktemp -d)"
for f in Makefile pyproject.toml; do cp "$f" "$backup/"; done
restore() { for f in Makefile pyproject.toml; do cp "$backup/$f" "$f"; done; }
trap 'rc=$?; [ $rc -ne 0 ] && restore; exit $rc' EXIT

perl -pi -e "s|^CONTRACTS_VERSION \?= .*|CONTRACTS_VERSION ?= $v|" Makefile
if grep -q '"kite-contracts @ ' pyproject.toml; then
  SPEC="$spec" perl -pi -e 's|"kite-contracts @ [^"]*"|"$ENV{SPEC}"|' pyproject.toml
else
  SPEC="$spec" perl -0pi -e 's|(\ndependencies = \[\n)|$1    "$ENV{SPEC}",\n|' pyproject.toml
  grep -q '"kite-contracts @ ' pyproject.toml \
    || { echo "contracts: не знайшов список dependencies у pyproject.toml" >&2; exit 1; }
fi

# Hatchling відкидає git-залежності без allow-direct-references.
if grep -q 'hatchling' pyproject.toml && ! grep -q 'allow-direct-references' pyproject.toml; then
  printf '\n[tool.hatch.metadata]\nallow-direct-references = true\n' >> pyproject.toml
fi

"$python" -m pip install -q --disable-pip-version-check "$spec"
echo "kite-contracts $v на місці: kite_contracts.models, kite_contracts.registry, parse_event."
