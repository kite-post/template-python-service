SERVICE ?= $(notdir $(CURDIR))
ORG     ?= kite-post
IMAGE   ?= ghcr.io/$(ORG)/$(SERVICE)
TAG     ?= dev
VENV    ?= .venv
PY      := $(VENV)/bin/python
# Тег kite-contracts, за яким закріплений сервіс. Той самий номер стоїть у
# pyproject.toml; contracts-check стежить, щоб вони не розійшлися.
CONTRACTS_VERSION ?= 0.2.1
# Python для contracts: venv, якщо він є, інакше той, що в PATH (так у CI).
PYTHON  := $(if $(wildcard $(PY)),$(PY),python3)

.DEFAULT_GOAL := help
.PHONY: help venv build lint fmt types test test-it verify image run up down clean contracts contracts-check rename

help: ## Показати цілі
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

venv: ## Створити venv і поставити залежності
	python3 -m venv $(VENV)
	$(PY) -m pip install --upgrade pip
	$(PY) -m pip install -e '.[dev]'

build: venv ## Те саме, що venv: для Python збірки як такої немає
	@echo "Python не компілюється — артефакт збірки це образ: make image"

lint: ## ruff: правила і формат
	$(VENV)/bin/ruff check .
	$(VENV)/bin/ruff format --check .

fmt: ## Відформатувати і виправити те, що виправляється
	$(VENV)/bin/ruff check --fix .
	$(VENV)/bin/ruff format .

types: ## mypy у строгому режимі
	$(VENV)/bin/mypy .

test: ## Швидкі тести
	$(VENV)/bin/pytest -q -m 'not integration'

test-it: ## Усі тести, включно з інтеграційними
	$(VENV)/bin/pytest -q

verify: lint types test-it ## Усе, що робить CI

image: ## Зібрати образ локально
	docker build -t $(IMAGE):$(TAG) .

run: ## Запустити локально з перезавантаженням
	$(VENV)/bin/uvicorn service_template.app:app --reload --port 8080

up: image ## Підняти образ у контейнері на 8080
	docker run --rm -p 8080:8080 --name $(SERVICE) $(IMAGE):$(TAG)

down: ## Зупинити контейнер
	-docker rm -f $(SERVICE)

clean: ## Прибрати кеші й артефакти
	rm -rf .pytest_cache .mypy_cache .ruff_cache dist build test-results.xml
	find . -name '__pycache__' -type d -prune -exec rm -rf {} +

contracts: ## Підключити kite-contracts за тегом; нова версія — make contracts V=0.2.0
	@ORG=$(ORG) PYTHON=$(PYTHON) bash scripts/contracts.sh "$(if $(V),$(V),$(CONTRACTS_VERSION))"

contracts-check: ## Перевірити, що контракти підключені за тегом і копій схем немає
	@PYTHON=$(PYTHON) bash scripts/contracts-check.sh "$(CONTRACTS_VERSION)"

rename: ## Перейменувати шаблон: make rename NAME=ai-service
	@test -n "$(NAME)" || (echo "Вкажи ім'я: make rename NAME=ai-service"; exit 1)
	@bash scripts/rename.sh "$(NAME)"
