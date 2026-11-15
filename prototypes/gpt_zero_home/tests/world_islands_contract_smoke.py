#!/usr/bin/env python3
"""Protect the world-design boundary: compact home != paid-only world.

Static contract test; does not claim to implement teleportation or server ACLs.
"""
from pathlib import Path
import json

BASE = Path(__file__).resolve().parents[1]
policy = json.loads((BASE / "contracts/first_home_land_policy_v1.json").read_text("utf-8"))
scope = (BASE / "scripts/home_scope.gd").read_text("utf-8")
guide = (BASE / "WORLD_ARCHIPELAGO_POLICY_V1.md").read_text("utf-8")

assert policy["starter_island"]["scope"] == "first_home_only"
assert policy["starter_island"]["newly_created_extra_buildable_lots"] == 0
assert policy["world"]["topology"] == "disconnected_floating_islands"
assert policy["world"]["allows_additional_free_islands"] is True
assert policy["world"]["additional_islands_independent_of_starter_home"] is True
assert policy["world"]["inter_island_travel"] == "instant"
assert policy["world"]["paths_or_bridges_between_islands_required"] is False
assert policy["world"]["transfers_require_server_validation"] is True
assert policy["demo"]["adds_free_island_allocations"] is False
assert policy["demo"]["creates_public_activity_zones"] is False

assert 'const WORLD_LAYOUT := "disconnected_islands"' in scope
assert 'const INTER_ISLAND_TRAVEL := "instant"' in scope
assert 'static func world_may_offer_other_free_islands() -> bool:' in scope
assert 'static func islands_are_connected_by_land() -> bool:' in scope
assert 'static func observer_can_instant_travel_to_another_island() -> bool:' in scope
assert 'static func can_create_unowned_extra_lot(_profile: String) -> bool:' in scope
assert "离散空岛" in guide and "免费" in guide and "瞬间" in guide

print("WORLD_ISLANDS_CONTRACT_OK: compact first home; other free disconnected islands allowed; server-authorized instant visits reserved")
