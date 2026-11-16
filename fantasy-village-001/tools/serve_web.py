#!/usr/bin/env python3
"""Serve the Godot Web export; Android can connect from the same local network."""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import threading
import webbrowser

ROOT = Path(__file__).resolve().parents[1]


class WebHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream",
                      ".js": "application/javascript"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--open-browser", action="store_true")
    args = parser.parse_args()
    directory = ROOT / "builds" / "web"
    if not (directory / "index.html").is_file():
        parser.error("Missing builds/web/index.html. Extract the complete release ZIP or build the Web export first.")
    handler = partial(WebHandler, directory=str(directory))
    try:
        server = ThreadingHTTPServer((args.bind, args.port), handler)
    except OSError as exc:
        parser.error(str(exc))
    print(f"Desktop: http://127.0.0.1:{args.port}/", flush=True)
    print(f"Android (same Wi-Fi): http://<this computer's LAN IPv4>:{args.port}/", flush=True)
    print("Keep this window open. Press Ctrl+C to stop. The Web build uses one thread.", flush=True)
    # The listening socket exists before opening the page, including on Windows.
    if args.open_browser:
        threading.Thread(target=webbrowser.open, args=(f"http://127.0.0.1:{args.port}/",),
                         daemon=True).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

