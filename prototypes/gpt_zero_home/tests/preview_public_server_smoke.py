#!/usr/bin/env python3
"""Regression checks for account-free temporary tunnel preview server."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import tempfile
import threading
import urllib.error
import urllib.request

from preview_public_server import make_handler, sanitized_public_snapshot

TEST_ID = "test-resident-id"
PAYLOAD = {
    "schema_version": 1,
    "world_id": "fantasia.first_home.prototype",
    "revision": 11724,
    "residents": [
        {"resident_id": TEST_ID, "name": "测试居民", "zone": "door", "activity": "move",
         "path_progress": {"from": "door", "to": "path", "remaining": ["path", "stone_table"], "progress": 0.0}},
        {"resident_id": "actual-private-resident", "name": "private", "zone": "window", "activity": "stay"}
    ],
}
class FakeUpstream(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass
    def do_GET(self):
        if self.path != "/public/world":
            self.send_error(404)
            return
        body = json.dumps(PAYLOAD, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

def start(handler):
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server

def request(url, method="GET"):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, method=method), timeout=2) as result:
            return result.status, result.read(), dict(result.headers)
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read(), dict(exc.headers)

def main():
    plain = sanitized_public_snapshot(json.dumps(PAYLOAD).encode(), TEST_ID)
    test_public = json.loads(plain)
    assert len(test_public["residents"]) == 1
    assert test_public["residents"][0]["resident_id"] == TEST_ID
    evil = dict(PAYLOAD)
    evil["token"] = "DO-NOT-EVER-LEAK"
    try:
        sanitized_public_snapshot(json.dumps(evil).encode(), TEST_ID)
        raise AssertionError("private top field accepted")
    except ValueError:
        pass
    for bad in [{"schema_version": 2}, {"residents": "not-list"}]:
        modified = dict(PAYLOAD)
        modified.update(bad)
        try:
            sanitized_public_snapshot(json.dumps(modified).encode(), TEST_ID)
            raise AssertionError("malformed packet accepted")
        except ValueError:
            pass

    upstream = start(FakeUpstream)
    try:
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            (folder / "index.html").write_text("STAGING_VIEWER_ONLY")
            (folder / "index.wasm").write_bytes(b"\0asm")
            (folder / "admin.json").write_text('{"token":"SHOULD_NOT_EXPOSE"}')
            (folder / ".env").write_text("TOKEN=SECRET")
            (folder / "secret.js").write_text("const RESIDENT_SECRET = 'SHOULD_NOT_EXPOSE';")
            (folder / "font-license.txt").write_text("SIL OPEN FONT LICENSE - test-only fixture")
            (folder / "private-notes.txt").write_text("DO NOT SERVE THIS FILE")
            preview = start(make_handler(folder, TEST_ID, f"http://127.0.0.1:{upstream.server_port}"))
            try:
                base = f"http://127.0.0.1:{preview.server_port}"
                status, body, headers = request(base + "/public/world")
                assert status == 200 and len(json.loads(body)["residents"]) == 1
                assert headers["Cache-Control"] == "no-store"
                assert b"actual-private-resident" not in body and b"SHOULD_NOT_EXPOSE" not in body
                status, body, _ = request(base + "/")
                assert status == 200 and body == b"STAGING_VIEWER_ONLY"
                status, body, _ = request(base + "/index.wasm")
                assert status == 200 and body == b"\0asm"
                status, body, _ = request(base + "/font-license.txt")
                assert status == 200 and body.startswith(b"SIL OPEN FONT LICENSE")
                for path in ["/intent", "/admin/register", "/observation", "/admin.json", "/secret.js", "/private-notes.txt", "/.env", "/../../../etc/passwd", "/public/world?token=evil"]:
                    status, _, _ = request(base + path)
                    assert status == 404, (path, status)
                for method in ["POST", "PUT", "DELETE", "PATCH"]:
                    status, _, _ = request(base + "/public/world", method)
                    assert status == 405, (method, status)
                print("PREVIEW_TUNNEL_SMOKE_OK: synthetic-only, static allowlist, no private API, no credentials, no-store")
            finally:
                preview.shutdown()
                preview.server_close()
    finally:
        upstream.shutdown()
        upstream.server_close()

if __name__ == "__main__":
    main()
