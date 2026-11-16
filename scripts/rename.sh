#!/usr/bin/env bash
# Перетворює шаблон у репозиторій конкретного сервіса: ім'я пакета, імпорти,
# ім'я дистрибутива та ім'я образу.
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Вкажи ім'я сервіса, наприклад ai-service" >&2
  exit 1
fi
name="$1"

if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Ім'я сервіса — малі літери, цифри і дефіси: ai-service" >&2
  exit 1
fi

# ai-service -> ai_service (ім'я пакета Python)
pkg="$(printf '%s' "$name" | tr '-' '_')"

echo "Сервіс: $name"
echo "Пакет:  $pkg"

if [ -d "src/service_template" ] && [ "$pkg" != "service_template" ]; then
  git mv "src/service_template" "src/$pkg" 2>/dev/null || mv "src/service_template" "src/$pkg"
fi

while IFS= read -r f; do
  perl -pi -e "
    s/service_template/$pkg/g;
    s/service-template/$name/g;
  " "$f"
done < <(find . -type f \
  \( -name '*.py' -o -name '*.toml' -o -name '*.yml' -o -name '*.yaml' -o -name '*.md' -o -name 'Dockerfile' \) \
  -not -path './.git/*' -not -path './.venv/*' -not -path './dist/*')

# Коротше або довше ім'я може зсунути перенос рядка — хай ruff вирівняє одразу.
if [ -x .venv/bin/ruff ]; then
  .venv/bin/ruff format . >/dev/null
elif command -v ruff >/dev/null 2>&1; then
  ruff format . >/dev/null
fi

echo
echo "Готово. Далі:"
echo "  make venv lint types test"
echo "  git add -A && git commit -m \"Перейменувати шаблон у $name\""
