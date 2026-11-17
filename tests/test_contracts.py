"""Контракти приходять пакетом kite-contracts, а не копіями схем (5.4, п. 6).

Якщо цей тест падає на імпорті — проганяй make contracts.
"""

from __future__ import annotations

import json

from kite_contracts import EVENT_REGISTRY, parse_event
from kite_contracts.models import ShipmentStatus, ShipmentStatusChangedEvent


def test_event_parses_with_contract_models() -> None:
    raw = {
        "specversion": "1.0",
        "id": "0193c2f4-2f4a-7a7e-9c3d-2f1b8a6e4d11",
        "source": "/kite/shipment-service",
        "type": "kite.shipment.status-changed.v1",
        "time": "2026-11-16T09:14:03Z",
        "data": {
            "shipmentId": "0193c2f4-1111-7a7e-9c3d-2f1b8a6e4d00",
            "trackingNumber": "KT123456785UA",
            "parcelId": "0193c2f4-2222-7a7e-9c3d-2f1b8a6e4d02",
            "statusBefore": "IN_TRANSIT",
            "statusAfter": "READY_FOR_PICKUP",
            "eventCode": "KT30",
            "transition": "T7",
        },
    }

    event = parse_event(json.dumps(raw))

    assert isinstance(event, ShipmentStatusChangedEvent)
    assert event.data.status_after is ShipmentStatus.READY_FOR_PICKUP


def test_registry_knows_topics() -> None:
    meta = EVENT_REGISTRY["kite.shipment.status-changed.v1"]
    assert meta.topic == "shipment.events"
    assert meta.partition_key == "shipmentId"
