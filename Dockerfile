# syntax=docker/dockerfile:1

# ── Збірка ────────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS build
WORKDIR /build

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Залежності окремим шаром: pyproject змінюється рідше за код.
COPY pyproject.toml ./
COPY src ./src
RUN python -m venv /venv \
    && /venv/bin/pip install --upgrade pip \
    && /venv/bin/pip install .

# ── Запуск ────────────────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

RUN groupadd -r kite && useradd -r -g kite kite \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /venv /venv
ENV PATH="/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER kite
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=5 \
    CMD curl -fsS http://localhost:8080/readyz || exit 1

ENTRYPOINT ["python", "-m", "service_template"]
