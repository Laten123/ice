#!/usr/bin/env python3
"""Rebuild the user-approved 002 UI glyph subset from an existing Noto CJK font.

Development-only dependency: fonttools. No download occurs; pass the font file
explicitly. Runtime and exports use the checked-in subset directly.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--font", type=Path, required=True)
    parser.add_argument("--font-number", type=int, default=2,
                        help="Simplified Chinese face is index 2 in the installed Noto CJK TTC.")
    args = parser.parse_args()
    characters = set(chr(value) for value in range(32, 127))
    for directory in (ROOT / "scripts", ROOT / "data"):
        for source in directory.rglob("*.gd"):
            characters.update(source.read_text(encoding="utf-8"))
    characters.update((ROOT / "project.godot").read_text(encoding="utf-8"))
    font = TTFont(args.font, fontNumber=args.font_number, recalcTimestamp=False)
    options = subset.Options()
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14]
    options.name_legacy = True
    options.name_languages = [0x409]
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes={ord(character) for character in characters})
    subsetter.subset(font)
    # Give this modified subset a separate name; retain original copyright/license.
    for name_id, value in {
        1: "FV002 Placeholder UI", 2: "Regular", 3: "FV002PlaceholderUI-Regular-002",
        4: "FV002 Placeholder UI Regular", 6: "FV002PlaceholderUI-Regular",
    }.items():
        font["name"].setName(value, name_id, 3, 1, 0x409)
    if "CFF " in font:
        cff = font["CFF "].cff
        cff.fontNames = ["FV002PlaceholderUI-Regular"]
        cff.topDictIndex[0].FamilyName = "FV002 Placeholder UI"
        cff.topDictIndex[0].FullName = "FV002 Placeholder UI Regular"
    destination = ROOT / "assets" / "ui" / "placeholder_ui.otf"
    destination.parent.mkdir(parents=True, exist_ok=True)
    font.save(destination)
    available = set(font.getBestCmap())
    required = {ord(character) for character in characters if character.isprintable()}
    missing = required - available
    if missing:
        raise RuntimeError("Missing printable glyphs: " + repr("".join(chr(value) for value in sorted(missing))))
    print(f"{destination.name}: {len(available)} glyphs, {destination.stat().st_size} bytes; all 002 UI text covered.")


if __name__ == "__main__":
    main()
