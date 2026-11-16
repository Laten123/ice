#!/usr/bin/env python3
"""Check the existing single-thread export under a Pages-style URL subpath."""
from __future__ import annotations

import argparse
from functools import partial
from html.parser import HTMLParser
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import threading
from urllib.parse import urljoin, urlparse
import urllib.request


class AssetParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag in ("script", "img") and attributes.get("src"):
            self.urls.append(attributes["src"])
        if tag == "link" and attributes.get("href"):
            self.urls.append(attributes["href"])


class WebHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream",
                      ".js": "application/javascript"}

    def log_message(self, format, *args):
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    web = args.directory.resolve()
    html = (web / "index.html").read_text(encoding="utf-8")
    if "const GODOT_THREADS_ENABLED = false;" not in html:
        raise RuntimeError("Expected the existing single-thread Web export.")
    match = re.search(r"const GODOT_CONFIG = (\{[^\n]+\});", html)
    if not match:
        raise RuntimeError("Godot Web configuration was not found.")
    config = json.loads(match[1])
    for filename, size in config["fileSizes"].items():
        if (web / filename).stat().st_size != size:
            raise RuntimeError(f"Missing or incomplete engine file: {filename}")
    for filename in ("index.js", "index.wasm", "index.pck",
                     "index.audio.worklet.js", "index.audio.position.worklet.js"):
        if not (web / filename).is_file():
            raise RuntimeError(f"Missing Web artifact: {filename}")
    assets = AssetParser()
    assets.feed(html)
    handler = partial(WebHandler, directory=str(web.parent))
    with ThreadingHTTPServer(("127.0.0.1", 0), handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        base = f"http://127.0.0.1:{server.server_port}/{web.name}/"
        try:
            with urllib.request.urlopen(base, timeout=10) as response:
                if response.status != 200:
                    raise RuntimeError("The Pages-style subpath did not serve index.html.")
                response.read()
            for reference in assets.urls:
                if urlparse(reference).scheme == "data":
                    continue
                if urlparse(reference).scheme or reference.startswith("/"):
                    raise RuntimeError(f"Expected a relative Pages asset path: {reference}")
                request = urllib.request.Request(urljoin(base, reference), method="HEAD")
                with urllib.request.urlopen(request, timeout=10) as response:
                    if response.status != 200:
                        raise RuntimeError(f"Failed Web asset: {reference}")
            for suffix, mime in (("wasm", "application/wasm"),
                                 ("js", "application/javascript"),
                                 ("pck", "application/octet-stream")):
                request = urllib.request.Request(base + "index." + suffix, method="HEAD")
                with urllib.request.urlopen(request, timeout=10) as response:
                    if response.headers.get_content_type() != mime:
                        raise RuntimeError(f"Wrong {suffix} MIME type.")
        finally:
            server.shutdown()
            thread.join(timeout=5)
    print("PASS: single-thread Web files, size metadata, relative subpath assets and HTTP MIME types")


if __name__ == "__main__":
    main()
