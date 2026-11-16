SERVICE ?= $(notdir $(CURDIR))
ORG     ?= kite-post
IMAGE   ?= ghcr.io/$(ORG)/$(SERVICE)
TAG     ?= dev
VENV    ?= .venv
PY      := $(VENV)/bin/python

.DEFAULT_GOAL := help
.PHONY: help venv build lint fmt types test test-it verify image run up down clean contracts rename

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

contracts: ## Згенерувати моделі подій з kite-contracts
	@echo "kite-contracts ще не підключено до цього сервіса."
	@echo "Підключення: пакет kite-contracts, закріплений за тегом (5.4, п. 6),"
	@echo "далі розкоментуй ціль contracts-check нижче — CI почне її проганяти."

# contracts-check: ## Перевірити сумісність зі схемами kite-contracts
# 	$(VENV)/bin/python -m kite_contracts.verify src

rename: ## Перейменувати шаблон: make rename NAME=ai-service
	@test -n "$(NAME)" || (echo "Вкажи ім'я: make rename NAME=ai-service"; exit 1)
	@bash scripts/rename.sh "$(NAME)"
