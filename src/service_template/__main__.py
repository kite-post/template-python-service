"""Запуск сервіса: python -m service_template."""

import uvicorn

from service_template.settings import settings


def main() -> None:
    uvicorn.run(
        "service_template.app:app",
        host="0.0.0.0",  # у контейнері інакше не дістатися
        port=settings.port,
        log_level=settings.log_level,
    )


if __name__ == "__main__":
    main()
