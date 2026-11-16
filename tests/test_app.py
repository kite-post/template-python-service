"""Тести HTTP-поверхні: без мережі, без контейнерів."""

from fastapi.testclient import TestClient

from service_template.app import create_app
from service_template.settings import Settings


def test_info_vidpovidae() -> None:
    settings = Settings(service_name="service-template", kite_image_tag="v1.2.3")
    client = TestClient(create_app(settings))

    response = client.get("/api/v1/info")

    assert response.status_code == 200
    assert response.json() == {
        "service": settings.service_name,
        "version": settings.kite_image_tag,
    }


def test_healthz_kazhe_up() -> None:
    client = TestClient(create_app())

    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json()["status"] == "UP"
