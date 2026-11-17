#!/usr/bin/env bash
# Перевіряє, що сервіс підключає kite-contracts як залежність, закріплену за
# тегом, і не тримає копій схем у себе (5.4, п. 6). Цю ціль проганяє CI.
set -euo pipefail

want="${1:?вкажи версію: scripts/contracts-check.sh 0.2.0}"
python="${PYTHON:-python3}"

fail() {
  echo "contracts-check: $1" >&2
  exit 1
}

# 1. Залежність оголошена і закріплена за тим самим тегом, що в Makefile.
dep="$(grep -o '"kite-contracts @ [^"]*"' pyproject.toml | head -1 || true)"
[ -n "$dep" ] || fail "залежності kite-contracts немає в pyproject.toml — проганяй make contracts V=…"
case "$dep" in
  *"@v$want#subdirectory=python\"") ;;
  *) fail "pyproject.toml закріплений не за тегом v$want: $dep" ;;
esac

# 2. Своїх копій схем у репозиторії бути не повинно.
copies="$(find . \( -path ./.venv -o -path ./.git -o -path '*/node_modules' \) -prune -o \
  \( -name '*.schema.json' -o -name 'openapi.yaml' -o -name 'openapi.yml' -o -name 'asyncapi.yaml' \) \
  -print 2>/dev/null || true)"
[ -z "$copies" ] || fail "у репозиторії лежать копії схем, а мають приходити залежністю:
$copies"

# 3. Встановлено саме цю версію, і пакет імпортується.
have="$("$python" -c 'import importlib.metadata as m; print(m.version("kite-contracts"))' 2>/dev/null || true)"
[ -n "$have" ] || fail "kite-contracts не встановлений — проганяй make contracts"
[ "$have" = "$want" ] || fail "встановлено kite-contracts $have, а закріплено $want — проганяй make contracts"
"$python" -c 'import kite_contracts.models, kite_contracts.registry' \
  || fail "kite_contracts не імпортується"

echo "contracts-check: kite-contracts $want підключений за тегом, копій схем немає."
