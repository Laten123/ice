#!/usr/bin/env python3
"""Fetch only required members from the official Godot template ZIP over HTTPS."""
from __future__ import annotations

import hashlib
import argparse
import io
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.6.3"
URL = ("https://github.com/godotengine/godot-builds/releases/download/"
       f"{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz")
DEST = ROOT / ".build-tools" / "templates"
MEMBERS = ("web_nothreads_debug.zip", "web_nothreads_release.zip",
           "windows_debug_x86_64.exe", "windows_release_x86_64.exe")


class RemoteZip(io.RawIOBase):
    """A seekable HTTPS file; zipfile reads only its directory and chosen entries."""
    def __init__(self, url: str):
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=60) as response:
            self.url = response.geturl()
            self.size = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        if whence == 0:
            self.position = offset
        elif whence == 1:
            self.position += offset
        elif whence == 2:
            self.position = self.size + offset
        return self.position

    def tell(self):
        return self.position

    def read(self, size=-1):
        end = self.size if size < 0 else min(self.position + size, self.size)
        if end <= self.position:
            return b""
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{end - 1}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError("Server did not honor byte ranges; refusing a full archive download.")
            data = response.read()
        if len(data) != end - self.position:
            raise RuntimeError("Incomplete range response.")
        self.position = end
        return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, help="Use a local official .tpz archive instead of HTTPS.")
    args = parser.parse_args()
    DEST.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.archive if args.archive else RemoteZip(URL)) as archive:
        for member in MEMBERS:
            destination = DEST / member
            if destination.is_file():
                print(f"{member}: already downloaded.")
                continue
            data = archive.read("templates/" + member)
            destination.write_bytes(data)
            print(f"{member}: {len(data)} bytes; SHA256 {hashlib.sha256(data).hexdigest()}")
    print("Official Godot 4.6.3 export templates are ready in .build-tools/templates.")


if __name__ == "__main__":
    main()
