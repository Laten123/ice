#!/usr/bin/env python3
"""TEMPORARY PUBLIC-WORLD WEB PREVIEW, NOT A PRODUCTION SERVER.

Binds 127.0.0.1 only. Never proxy the resident/admin API or resident tokens.
Set --test-resident-id to a synthetic resident, even if the upstream contains
real consented residents. Never point cloudflared directly to port 8200.
"""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import mimetypes
from pathlib import Path
import urllib.error
import urllib.request
from urllib.parse import urlsplit

MAX_JSON = 65_536
MAX_PUBLIC_RESIDENTS = 32
STATIC_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".wasm": "application/wasm",
    ".pck": "application/octet-stream",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".css": "text/css; charset=utf-8",
    ".ico": "image/x-icon",
    ".webmanifest": "application/manifest+json",
    ".txt": "text/plain; charset=utf-8",
}
PUBLIC_KEYS = {"schema_version", "world_id", "revision", "residents"}
RESIDENT_KEYS = {"resident_id", "name", "zone", "activity", "path_progress", "scene_id"}
SCENE_ZONES = {
    "exterior": {"door", "path", "garden", "window", "old_tree", "book_corner", "stone_table", "riverside", "riverbank"},
    "interior": {"house_entry", "window_corner", "writing_desk", "bookcase", "rest_corner"},
}
ROUTE_KEYS = {"from", "to", "remaining", "progress"}

def sanitized_public_snapshot(body, test_id):
    if len(body) > MAX_JSON:
        raise ValueError("oversized snapshot")
    packet = json.loads(body)
    if not isinstance(packet, dict) or set(packet) - PUBLIC_KEYS:
        raise ValueError("unknown top-level field")
    if packet.get("schema_version") != 1 or packet.get("world_id") != "fantasia.first_home.prototype":
        raise ValueError("invalid world contract")
    if isinstance(packet.get("revision"), bool) or not isinstance(packet.get("revision"), int) or packet["revision"] < 0:
        raise ValueError("invalid revision")
    people = packet.get("residents")
    if not isinstance(people, list) or len(people) > MAX_PUBLIC_RESIDENTS:
        raise ValueError("invalid residents")
    result = []
    for person in people:
        if not isinstance(person, dict) or set(person) - RESIDENT_KEYS:
            raise ValueError("unapproved public resident field")
        if person.get("resident_id") != test_id:
            continue  # Do not expose consented real residents in an ad hoc tunnel.
        for key in ("resident_id", "name", "zone", "activity"):
            if not isinstance(person.get(key), str):
                raise ValueError("missing public field")
        scene = person.get("scene_id", "exterior")
        if not isinstance(scene, str) or scene not in SCENE_ZONES:
            raise ValueError("invalid public scene")
        if person["zone"] not in SCENE_ZONES[scene]:
            raise ValueError("resident zone mismatches the public scene")
        route = person.get("path_progress")
        if route is not None:
            if not isinstance(route, dict) or set(route) - ROUTE_KEYS or set(route) != ROUTE_KEYS:
                raise ValueError("invalid route metadata")
            if not isinstance(route["from"], str) or not isinstance(route["to"], str):
                raise ValueError("invalid route endpoints")
            if not isinstance(route["remaining"], list) or len(route["remaining"]) > 24:
                raise ValueError("invalid route path")
            if any(not isinstance(node, str) or node not in SCENE_ZONES[scene] for node in route["remaining"]):
                raise ValueError("invalid waypoint")
            if route["from"] != person["zone"] or route["to"] not in SCENE_ZONES[scene]:
                raise ValueError("cross-room or inconsistent route")
            if not route["remaining"] or route["remaining"][0] != route["to"]:
                raise ValueError("next route step does not match the current edge")
            progress = route["progress"]
            if isinstance(progress, bool) or not isinstance(progress, (float, int)) or not 0 <= progress <= 1:
                raise ValueError("invalid progress")
        result.append(person)
    return json.dumps({
        "schema_version": 1,
        "world_id": "fantasia.first_home.prototype",
        "revision": packet["revision"],
        "residents": result,
    }, ensure_ascii=False).encode("utf-8")

def make_handler(web_dir, test_id, upstream):
    class PreviewHandler(BaseHTTPRequestHandler):
        server_version = "FantasiaPreview/0.1"
        sys_version = ""

        def log_message(self, fmt, *args):
            # No path, cookies, addresses, tokens, private fields in logs.
            pass

        def _reply(self, status, body, content_type="application/json; charset=utf-8"):
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):
            self._reply(405, b'{"error":"read_only"}')

        do_PUT = do_POST
        do_DELETE = do_POST
        do_PATCH = do_POST

        def do_GET(self):
            parsed = urlsplit(self.path)
            if parsed.query or parsed.fragment:
                self._reply(404, b'{"error":"not_found"}')
                return
            if parsed.path == "/health":
                self._reply(200, b'{"status":"ok","mode":"temporary_public_preview"}')
                return
            if parsed.path == "/public/world":
                try:
                    request = urllib.request.Request(
                        upstream + "/public/world",
                        headers={"Accept": "application/json"},
                        method="GET",
                    )
                    with urllib.request.urlopen(request, timeout=3.0) as response:
                        if response.status != 200:
                            raise ValueError("unexpected origin response")
                        data = response.read(MAX_JSON + 1)
                    sanitized = sanitized_public_snapshot(data, test_id)
                    self._reply(200, sanitized)
                except (OSError, ValueError, TypeError, urllib.error.URLError, json.JSONDecodeError):
                    self._reply(502, b'{"error":"public_snapshot_unavailable"}')
                return
            if web_dir is None:
                self._reply(404, b'{"error":"not_found"}')
                return
            if parsed.path == "/":
                filename = "index.html"
            else:
                filename = parsed.path.lstrip("/")
            # Flat staging export only. No directories, dotfiles or symlinks.
            if "/" in filename or "\\" in filename or filename.startswith("."):
                self._reply(404, b'{"error":"not_found"}')
                return
            # Only a flat Godot export bundle named index.* and a few
            # unprivileged icon files may be served. Merely having a safe
            # extension must not expose unrelated local JavaScript or assets.
            if not (filename.startswith("index.") or filename in (
                "favicon.ico", "favicon.png", "apple-touch-icon.png", "icon.png",
                "font-license.txt"
            )):
                self._reply(404, b'{"error":"not_found"}')
                return
            filepath = web_dir / filename
            mime = STATIC_TYPES.get(filepath.suffix)
            if mime is None or not filepath.is_file() or filepath.is_symlink():
                self._reply(404, b'{"error":"not_found"}')
                return
            try:
                length = filepath.stat().st_size
                self.send_response(200)
                self.send_header("Content-Type", mime)
                self.send_header("Content-Length", str(length))
                self.send_header("Cache-Control", "no-store")
                self.send_header("X-Content-Type-Options", "nosniff")
                self.send_header("Cross-Origin-Opener-Policy", "same-origin")
                self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
                self.end_headers()
                with filepath.open("rb") as source:
                    while chunk := source.read(65536):
                        self.wfile.write(chunk)
            except OSError:
                return  # Cannot send a second HTTP response once headers were sent.

    return PreviewHandler

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8211)
    parser.add_argument("--upstream", default="http://127.0.0.1:8200")
    parser.add_argument("--web-dir", default=None)
    parser.add_argument("--test-resident-id", required=True)
    args = parser.parse_args()
    if not (1024 <= args.port <= 65535):
        parser.error("port out of range")
    if args.upstream != "http://127.0.0.1:8200":
        parser.error("preview only supports the isolated loopback P1 server")
    if not (args.test_resident_id.startswith("test-") or args.test_resident_id.startswith("path-test")):
        parser.error("forbid any non-test resident identity")
    web_dir = Path(args.web_dir).resolve() if args.web_dir else None
    if web_dir is not None and (
        not web_dir.is_dir()
        or not (web_dir / "index.html").is_file()
        or not any(web_dir.glob("index*.wasm"))
        or not any(web_dir.glob("index*.pck"))
    ):
        parser.error("--web-dir must be a dedicated Godot Web export with index.html, WASM and PCK")
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(web_dir, args.test_resident_id, args.upstream))
    print("TEMP PREVIEW: loopback only, no credentials, test resident only", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

if __name__ == "__main__":
    main()
