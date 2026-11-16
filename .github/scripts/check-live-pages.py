#!/usr/bin/env python3
"""Wait for the deployed HTTPS export and check real public asset responses."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import http.client
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import time
from urllib.parse import unquote, urljoin, urlparse
import urllib.request


def validate_url(url: str, base: str | None = None) -> str:
    parsed = urlparse(url)
    decoded_path = unquote(parsed.path)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.query or parsed.fragment
            or "\\" in decoded_path or ".." in decoded_path.split("/")):
        raise ValueError("Expected a credential-free HTTPS URL without query, fragment or parent paths.")
    if base is not None:
        allowed = urlparse(base)
        if ((parsed.hostname.lower(), parsed.port or 443) !=
                (allowed.hostname.lower(), allowed.port or 443)
                or not parsed.path.startswith(allowed.path)):
            raise ValueError("A public resource or redirect left the deployed origin or base path.")
    return url


class SameSiteRedirect(urllib.request.HTTPRedirectHandler):
    def __init__(self, base: str):
        super().__init__()
        self.base = base

    def redirect_request(self, request, response, code, message, headers, new_url):
        # Check before following, including HTTPS downgrades and other origins.
        validate_url(new_url, self.base)
        return super().redirect_request(request, response, code, message, headers, new_url)


class AssetParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        key = "src" if tag in ("script", "img") else "href" if tag == "link" else None
        if key and attributes.get(key):
            self.urls.append(attributes[key])


def asset_url(base: str, reference: str) -> str:
    parsed = urlparse(reference)
    if parsed.scheme or parsed.netloc or reference.startswith("/"):
        raise ValueError(f"Expected a relative exported asset: {reference}")
    return validate_url(urljoin(base, reference), base)


def check_once(base: str, deadline: float) -> list[dict]:
    opener = urllib.request.build_opener(SameSiteRedirect(base))
    resources = []

    def open_response(url: str, method: str = "GET"):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("Live verification readiness deadline expired.")
        validate_url(url, base)
        request = urllib.request.Request(url, method=method, headers={
            "User-Agent": "FantasyVillage001-PagesCheck/1.0",
            "Accept-Encoding": "identity", "Cache-Control": "no-cache"})
        response = opener.open(request, timeout=min(10.0, remaining))
        validate_url(response.geturl(), base)
        if time.monotonic() >= deadline:
            response.close()
            raise TimeoutError("Live verification readiness deadline expired.")
        return response

    with open_response(base) as response:
        if response.status != 200 or response.headers.get_content_type() != "text/html":
            raise RuntimeError("Public index is not an HTTP 200 HTML document.")
        html_bytes = response.read(1024 * 1024 + 1)
        if len(html_bytes) > 1024 * 1024:
            raise RuntimeError("Public index exceeded the HTML size limit.")
        html = html_bytes.decode("utf-8")
        resources.append({"url": response.geturl(), "method": "GET", "status": 200,
                          "mime": "text/html", "body_bytes": len(html_bytes)})
    if "const GODOT_THREADS_ENABLED = false;" not in html:
        raise RuntimeError("The deployed site is not the expected single-thread Godot export.")
    match = re.search(r"const GODOT_CONFIG = (\{[^\n]+\});", html)
    if not match:
        raise RuntimeError("Missing deployed Godot configuration.")
    config = json.loads(match[1])
    sizes = config.get("fileSizes", {})
    if config.get("executable") != "index" or config.get("serviceWorker"):
        raise RuntimeError("Expected the existing index export without a service worker.")
    for filename in ("index.wasm", "index.pck"):
        if not isinstance(sizes.get(filename), int) or sizes[filename] <= 0:
            raise RuntimeError(f"Missing positive export size metadata: {filename}")
    for reference in sizes:
        asset_url(base, reference)
    assets = AssetParser()
    assets.feed(html)
    for reference in assets.urls:
        if urlparse(reference).scheme != "data":
            asset_url(base, reference)
    expected = {
        "index.js": {"application/javascript", "text/javascript"},
        "index.wasm": {"application/wasm"},
        "index.pck": {"application/octet-stream"},
        "index.audio.worklet.js": {"application/javascript", "text/javascript"},
        "index.audio.position.worklet.js": {"application/javascript", "text/javascript"},
    }
    print(f"HTTP 200 text/html {base}", flush=True)
    for filename, allowed in expected.items():
        url = asset_url(base, filename)
        with open_response(url, "HEAD") as response:
            mime = response.headers.get_content_type()
            if response.status != 200 or mime not in allowed:
                raise RuntimeError(f"Unexpected public asset response for {filename}: {response.status} {mime}")
            size = response.headers.get("Content-Length")
            size_checked = filename in sizes and size is not None and not response.headers.get("Content-Encoding")
            if size_checked:
                if int(size) != sizes[filename]:
                    raise RuntimeError(f"The public {filename} length differs from the export metadata.")
            resources.append({"url": response.geturl(), "method": "HEAD", "status": 200,
                              "mime": mime, "content_length": int(size) if size else None,
                              "export_size": sizes.get(filename), "size_checked": size_checked})
            print(f"HTTP 200 {mime} {url}", flush=True)
    # The small 001 PCK is checked in full; the 37 MB WASM uses HEAD metadata.
    if sizes["index.pck"] > 8 * 1024 * 1024:
        raise RuntimeError("The 001 PCK exceeded the bounded live-check size limit.")
    with open_response(asset_url(base, "index.pck")) as response:
        body = response.read(sizes["index.pck"] + 1)
        if (response.status != 200 or response.headers.get_content_type() != "application/octet-stream"
                or len(body) != sizes["index.pck"]):
            raise RuntimeError("The downloaded PCK differs from its exported size metadata.")
        resources.append({"url": response.geturl(), "method": "GET", "status": 200,
                          "body_bytes": len(body), "sha256": hashlib.sha256(body).hexdigest()})
    return resources


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", nargs="?", help="HTTPS page_url returned by deploy-pages")
    parser.add_argument("--url", dest="legacy_url", help=argparse.SUPPRESS)
    parser.add_argument("--output", type=Path, help="Write a JSON success/failure report")
    parser.add_argument("--timeout", type=float, default=170, help="Readiness deadline in seconds (1–170)")
    args = parser.parse_args()
    if bool(args.url) == bool(args.legacy_url) or not 1 <= args.timeout <= 170:
        parser.error("Provide one HTTPS URL and a readiness timeout between 1 and 170 seconds.")
    try:
        base = validate_url(args.url or args.legacy_url).rstrip("/") + "/"
    except ValueError as exc:
        parser.error(str(exc))
    started = time.monotonic()
    deadline = started + args.timeout
    report = {"page_url": base, "passed": False, "attempts": 0,
              "checked_at_utc": datetime.now(timezone.utc).isoformat(),
              "resources": [], "readiness_failures": []}
    # A 170-second readiness deadline plus at most one 10-second in-flight read.
    while time.monotonic() < deadline:
        report["attempts"] += 1
        try:
            report["resources"] = check_once(base, deadline)
            report["passed"] = True
            print("PASS: live HTTPS index, JS, WASM, PCK and audio-worklet responses", flush=True)
            break
        except (OSError, RuntimeError, ValueError, http.client.HTTPException) as exc:
            report["readiness_failures"].append(str(exc))
            print(f"Readiness attempt {report['attempts']}: {exc}", flush=True)
            remaining = deadline - time.monotonic()
            if remaining > 0:
                time.sleep(min(5, remaining))
    report["duration_seconds"] = round(time.monotonic() - started, 3)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if not report["passed"]:
        raise SystemExit("The deployed Web export did not pass live HTTPS checks.")


if __name__ == "__main__":
    main()
