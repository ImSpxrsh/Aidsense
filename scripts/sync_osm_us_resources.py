#!/usr/bin/env python3
"""
Sync AidSense resources from OpenStreetMap (all US states + DC) into Supabase.

Required env:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY

Optional env:
  OVERPASS_ENDPOINT (default: https://overpass-api.de/api/interpreter)
  OSM_SYNC_STATE_LIMIT (int, for testing)
"""

from __future__ import annotations

import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Iterable, List, Optional, Tuple

# macOS SSL certificate workaround
_ssl_context = ssl.create_default_context()
_ssl_context.check_hostname = False
_ssl_context.verify_mode = ssl.CERT_NONE

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
OVERPASS_ENDPOINT = os.environ.get(
    "OVERPASS_ENDPOINT", "https://overpass-api.de/api/interpreter"
).strip()
STATE_LIMIT_ENV = os.environ.get("OSM_SYNC_STATE_LIMIT", "").strip()

OVERPASS_FALLBACKS = [
    OVERPASS_ENDPOINT,
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.openstreetmap.ru/api/interpreter",
]

BATCH_SIZE = 300
HTTP_TIMEOUT = 180
MAX_RETRIES = 4


def fail(msg: str) -> None:
    print(f"[ERROR] {msg}", file=sys.stderr)
    sys.exit(1)


def http_post_json(url: str, payload: Any, headers: Dict[str, str]) -> Tuple[int, str]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    for k, v in headers.items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT, context=_ssl_context) as resp:
            status = resp.getcode()
            body = resp.read().decode("utf-8", errors="replace")
            return status, body
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return exc.code, body


def overpass_query(query: str) -> Dict[str, Any]:
    payload = urllib.parse.urlencode({"data": query}).encode("utf-8")
    last_error: Optional[Exception] = None

    for endpoint in OVERPASS_FALLBACKS:
        for attempt in range(1, MAX_RETRIES + 1):
            req = urllib.request.Request(endpoint, data=payload, method="POST")
            req.add_header("Content-Type", "application/x-www-form-urlencoded")
            try:
                with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT, context=_ssl_context) as resp:
                    raw = resp.read().decode("utf-8", errors="replace")
                    if resp.getcode() != 200:
                        raise RuntimeError(
                            f"Overpass status {resp.getcode()} from {endpoint}: {raw[:300]}"
                        )
                    return json.loads(raw)
            except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, RuntimeError) as e:
                last_error = e
                backoff = attempt * 3
                print(
                    f"[WARN] Overpass failed (endpoint={endpoint}, attempt={attempt}/{MAX_RETRIES}): {e}. Retrying in {backoff}s"
                )
                time.sleep(backoff)

    raise RuntimeError(f"Overpass failed on all endpoints: {last_error}")


def chunked(items: List[Dict[str, Any]], size: int) -> Iterable[List[Dict[str, Any]]]:
    for i in range(0, len(items), size):
        yield items[i : i + size]


def get_us_state_areas() -> List[Dict[str, str]]:
    query = """
[out:json][timeout:120];
area["ISO3166-1"="US"][admin_level=2]->.usa;
relation(area.usa)["boundary"="administrative"]["admin_level"="4"]["ISO3166-2"~"^US-[A-Z]{2}$"];
out ids tags;
""".strip()

    data = overpass_query(query)
    elements = data.get("elements", [])
    states: List[Dict[str, str]] = []

    for element in elements:
        if element.get("type") != "relation":
            continue
        rel_id = element.get("id")
        tags = element.get("tags", {})
        iso = tags.get("ISO3166-2", "")
        name = tags.get("name", "")
        if not rel_id or not iso.startswith("US-"):
            continue
        state_code = iso.split("-", 1)[1]
        area_id = str(3600000000 + int(rel_id))
        states.append({"state_code": state_code, "name": name, "area_id": area_id})

    states.sort(key=lambda s: s["state_code"])
    return states


def normalize_type(tags: Dict[str, str]) -> str:
    amenity = tags.get("amenity", "").lower()
    healthcare = tags.get("healthcare", "").lower()
    social = tags.get("social_facility", "").lower()
    office = tags.get("office", "").lower()

    if amenity in {"shelter"}:
        return "shelter"
    if social in {"shelter", "group_home", "assisted_living", "homeless"}:
        return "shelter"

    if amenity in {"food_bank", "soup_kitchen"}:
        return "food"
    if social in {"food_bank", "food_kitchen"}:
        return "food"

    if healthcare in {"mental_health", "psychiatry", "psychology"}:
        return "mental_health"
    if "mental" in tags.get("name", "").lower() or "counsel" in tags.get("name", "").lower():
        return "mental_health"

    if healthcare in {"clinic", "doctor", "hospital", "community_health_worker"}:
        return "clinic"
    if amenity in {"clinic", "hospital", "doctors"}:
        return "clinic"

    if office == "social_facility":
        return "other"

    return "other"


def should_keep_resource(tags: Dict[str, str]) -> bool:
    amenity = tags.get("amenity", "").lower()
    healthcare = tags.get("healthcare", "").lower()
    social = tags.get("social_facility", "").lower()

    # Hard filter for high-signal aid resources.
    if amenity in {"shelter", "social_facility"}:
        return True
    if social in {"homeless", "food_bank", "group_home", "assisted_living"}:
        return True
    if healthcare in {"clinic", "doctor", "hospital", "mental_health", "psychiatry", "psychology", "community_health_worker"}:
        return True
    if amenity in {"clinic", "hospital", "doctors", "food_bank", "soup_kitchen"}:
        return True
    return False


def compute_confidence_score(
    *,
    phone: str,
    opening_hours: str,
    website: str,
    from_verified_dataset: bool,
    enriched_by_google: bool,
) -> int:
    score = 0
    if phone:
        score += 1
    if opening_hours:
        score += 1
    if website:
        score += 1
    if from_verified_dataset:
        score += 2
    if enriched_by_google:
        score += 1
    return score


def extract_lat_lng(element: Dict[str, Any]) -> Tuple[Optional[float], Optional[float]]:
    if "lat" in element and "lon" in element:
        return float(element["lat"]), float(element["lon"])
    center = element.get("center")
    if isinstance(center, dict) and "lat" in center and "lon" in center:
        return float(center["lat"]), float(center["lon"])
    return None, None


def fetch_state_resources(state: Dict[str, str]) -> List[Dict[str, Any]]:
    area_id = state["area_id"]
    state_code = state["state_code"]

    query = f"""
[out:json][timeout:240];
area({area_id})->.region;
(
  nwr(area.region)["amenity"~"^(shelter|food_bank|soup_kitchen|clinic|hospital|doctors)$"];
  nwr(area.region)["healthcare"~"^(clinic|doctor|hospital|mental_health|psychiatry|psychology|community_health_worker)$"];
  nwr(area.region)["social_facility"~"^(shelter|group_home|assisted_living|homeless|food_bank|food_kitchen)$"];
  nwr(area.region)["office"="social_facility"];
);
out center tags;
""".strip()

    data = overpass_query(query)
    elements = data.get("elements", [])
    rows: List[Dict[str, Any]] = []

    for e in elements:
        tags = e.get("tags", {})
        if not isinstance(tags, dict):
            continue

        if not should_keep_resource(tags):
            continue

        lat, lng = extract_lat_lng(e)
        if lat is None or lng is None:
            continue

        name = str(tags.get("name", "")).strip()
        if not name:
            continue

        osm_type = e.get("type", "")
        osm_id = e.get("id")
        if osm_type not in {"node", "way", "relation"} or osm_id is None:
            continue

        website = str(tags.get("website", tags.get("contact:website", ""))).strip()
        phone = str(tags.get("phone", tags.get("contact:phone", ""))).strip()
        opening_hours = str(tags.get("opening_hours", "")).strip()
        address_parts = [
            tags.get("addr:housenumber", ""),
            tags.get("addr:street", ""),
            tags.get("addr:city", ""),
            tags.get("addr:state", ""),
            tags.get("addr:postcode", ""),
        ]
        address = " ".join(str(x).strip() for x in address_parts if str(x).strip())

        from_verified_dataset = False
        enriched_by_google = False
        confidence_score = compute_confidence_score(
            phone=phone,
            opening_hours=opening_hours,
            website=website,
            from_verified_dataset=from_verified_dataset,
            enriched_by_google=enriched_by_google,
        )

        row = {
            "source": "osm",
            "source_id": f"osm:{osm_type}/{osm_id}",
            "name": name,
            "type": normalize_type(tags),
            "address": address,
            "state_code": state_code,
            "latitude": lat,
            "longitude": lng,
            "opening_hours": opening_hours,
            "open_now": False,
            "walk_in": False,
            "appointment_required": False,
            "id_required": False,
            "cost": "unknown",
            "families_welcome": False,
            "women_only": False,
            "youth_friendly": False,
            "phone": phone,
            "website": website,
            "tags": [],
            "from_verified_dataset": from_verified_dataset,
            "enriched_by_google": enriched_by_google,
            "confidence_score": confidence_score,
            "metadata": {
                "osm_type": osm_type,
                "osm_id": osm_id,
                "raw_tags": tags,
            },
            "last_verified_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        rows.append(row)

    unique: Dict[str, Dict[str, Any]] = {}
    for row in rows:
        unique[row["source_id"]] = row

    return list(unique.values())


def upsert_resources(rows: List[Dict[str, Any]]) -> None:
    if not rows:
        return

    endpoint = (
        f"{SUPABASE_URL}/rest/v1/resources"
        "?on_conflict=source,source_id"
    )
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }

    total = 0
    for batch in chunked(rows, BATCH_SIZE):
        status, body = http_post_json(endpoint, batch, headers)
        if status not in (200, 201, 204):
            snippet = body[:500].replace("\n", " ")
            raise RuntimeError(
                f"Supabase upsert failed ({status}) for batch of {len(batch)} rows: {snippet}"
            )
        total += len(batch)

    print(f"[INFO] Upserted {total} rows to Supabase")


def main() -> None:
    if not SUPABASE_URL:
        fail("SUPABASE_URL is required")
    if not SUPABASE_SERVICE_ROLE_KEY:
        fail("SUPABASE_SERVICE_ROLE_KEY is required")

    print("[INFO] Discovering US state areas from OSM...")
    states = get_us_state_areas()
    if not states:
        fail("No states returned from OSM. Try again later or change OVERPASS_ENDPOINT.")

    if STATE_LIMIT_ENV:
        try:
            limit = int(STATE_LIMIT_ENV)
            if limit > 0:
                states = states[:limit]
                print(f"[INFO] Limiting to first {limit} states for test run")
        except ValueError:
            print(f"[WARN] Ignoring invalid OSM_SYNC_STATE_LIMIT: {STATE_LIMIT_ENV}")

    print(f"[INFO] Syncing {len(states)} states...")

    grand_total = 0
    for idx, state in enumerate(states, start=1):
        label = f"{state['state_code']} ({state['name']})"
        print(f"[INFO] [{idx}/{len(states)}] Fetching {label}")
        rows = fetch_state_resources(state)
        print(f"[INFO] [{idx}/{len(states)}] {label}: {len(rows)} resources")
        upsert_resources(rows)
        grand_total += len(rows)

    print(f"[DONE] OSM sync complete. Processed {grand_total} resources across {len(states)} states.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        fail("Interrupted by user")
    except Exception as exc:
        fail(str(exc))
