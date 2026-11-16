"""HTTP-поверхня сервіса."""

from fastapi import FastAPI
from pydantic import BaseModel

from service_template.settings import Settings, settings


class Info(BaseModel):
    """Відповідь /api/v1/info."""

    service: str
    version: str


class Health(BaseModel):
    """Відповідь проб готовності."""

    status: str


def create_app(config: Settings | None = None) -> FastAPI:
    """Збирає застосунок. Конфіг приймається аргументом, щоб тест міг свій."""
    config = config or settings
    app = FastAPI(title=config.service_name, version=config.kite_image_tag)

    @app.get("/healthz", response_model=Health)
    async def healthz() -> Health:
        return Health(status="UP")

    @app.get("/readyz", response_model=Health)
    async def readyz() -> Health:
        return Health(status="UP")

    @app.get("/api/v1/info", response_model=Info)
    async def info() -> Info:
        return Info(service=config.service_name, version=config.kite_image_tag)

    return app


app = create_app()
