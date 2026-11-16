"""Конфіг сервіса: усе з оточення, нічого з файлів поряд з кодом."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Налаштування, які compose у kite-infra передає через оточення."""

    model_config = SettingsConfigDict(env_prefix="", extra="ignore")

    service_name: str = "service-template"
    # Тег образу, з якого піднявся контейнер (12.6).
    kite_image_tag: str = "dev"
    port: int = 8080
    log_level: str = "info"


settings = Settings()
