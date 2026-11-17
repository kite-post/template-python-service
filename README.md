# template-python-service

Шаблон репозиторію для Python-сервіса Kite: FastAPI, Python 3.15, ruff, mypy у
строгому режимі. Із нього створюються `ai-service` і `simulator` (5.6).

## Новий сервіс

```bash
gh repo create kite-post/ai-service --public --template kite-post/template-python-service
cd ai-service
make rename NAME=ai-service
git add -A && git commit -m "Перейменувати шаблон у ai-service" && git push
```

`make rename` перейменовує пакет (`service_template` → `ai_service`),
дистрибутив та ім'я образу. Без нього репозиторій теж збирається і проходить
CI — просто під іменем шаблону.

## Що всередині

```
pyproject.toml            залежності, ruff, mypy strict, pytest — усе в одному файлі
src/service_template/     app.py (роутер), settings.py (конфіг з оточення), __main__.py
tests/                    тести на TestClient, без мережі
Dockerfile                venv у стадії збірки, slim-образ без компілятора
Makefile                  той самий набір цілей, що й у решти репозиторіїв
.github/workflows/ci.yml  п'ять рядків: виклик спільного workflow із .github
```

Конфіг — `pydantic-settings`: усе з оточення, нічого з файлів поряд з кодом.
`KITE_IMAGE_TAG` compose підставляє з `versions.env`, тож `/api/v1/info`
показує, з якого саме образу піднявся сервіс.

## Команди

```bash
make venv       # створити .venv і поставити залежності
make lint       # ruff: правила і формат
make fmt        # виправити те, що виправляється
make types      # mypy strict
make test       # швидкі тести
make test-it    # усі тести, включно з позначеними integration
make verify     # усе, що робить CI
make image      # зібрати образ локально
make up         # підняти образ на 8080
make run        # uvicorn з перезавантаженням
```

## Контракти

Pydantic-моделі REST і подій та реєстр топіків приходять пакетом
`kite-contracts`, закріпленим за тегом — своїх копій `openapi.yaml` і JSON
Schema сервіс не тримає (5.4, п. 6). У реєстр пакет не публікується: pip бере
його з git за тегом, тож у `pyproject.toml` стоїть

```toml
"kite-contracts @ git+https://github.com/kite-post/kite-contracts.git@v0.2.1#subdirectory=python",
```

```bash
make contracts            # поставити пакет за поточним тегом
make contracts V=0.3.0    # перейти на нову версію: Makefile + pyproject.toml
make contracts-check      # версія закріплена, копій схем немає, пакет імпортується
```

```python
from kite_contracts import parse_event
from kite_contracts.registry import EVENT_REGISTRY

event = parse_event(raw)  # ShipmentStatusChangedEvent тощо
topic = EVENT_REGISTRY[event.type].topic
```

Нова версія приходить сама: після релізу `kite-contracts` розсилає подію
всім репозиторіям із топіком `kite-contracts`, і workflow `contracts-bump`
відкриває PR з `make contracts V=<версія>`. Версія одна на всі репозиторії.
Руками те саме: `make contracts V=0.3.0`. Якщо тегу немає, `Makefile` і
маніфест лишаються як були.

Через git-залежність у збірковому шарі образу стоїть `git`; в образ, що
запускається, він не потрапляє.

## CI

Увесь пайплайн — виклик спільного workflow з
[kite-post/.github](https://github.com/kite-post/.github): ruff, mypy, pytest,
збірка образу, публікація в `ghcr.io/kite-post/<сервіс>` і PR у `kite-infra`
з новою версією (12.6).

Тести з позначкою `@pytest.mark.integration` у CI проганяються теж; щоб
вимкнути їх для важкого сервіса, у `ci.yml` достатньо `with: { integration-tests: false }`.

## Для ai-service окремо

Моделі не лежать у git: образ тягне їх з MinIO на старті або отримує
змонтованим томом (5.3). Строгий mypy на це не впливає, а ось розмір образу —
так: `torch` і подібне ставиться в стадії збірки і копіюється разом з venv,
тому зміна коду не перезбирає залежності.
