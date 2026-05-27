#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

from decode_bin import decode_file


TABLES_DIR_NAMES = {
    "ACTIVITY_INHERITANCE_CONF",
    "EGG_TYPE_CONF",
    "HOME_PET_LAY_EGG_RATE_CONF",
    "PETBASE_CONF",
    "PET_BLOOD_CONF",
    "PET_CLASSIS_CONF",
    "PET_EGG_CONF",
    "PET_EVOLUTION_CONF",
    "PET_HANDBOOK",
    "PET_RANDOM_EGG_CONF",
    "PET_TALENT_CONF",
    "SKILL_CONF",
}


def find_bin_root(temp_dir: Path) -> Path:
    candidates = [
        temp_dir / "Content" / "ScriptC" / "Data" / "Bin",
        temp_dir / "Data" / "Bin",
    ]
    candidates.extend(path for path in temp_dir.rglob("Bin") if path.is_dir())
    for path in candidates:
        if (path / "BinConf").is_dir():
            return path
    raise FileNotFoundError(f"Bin root not found under {temp_dir}")


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def resolve_loc_dir(bin_root: Path, language: str | None) -> Path | None:
    loc_root = bin_root / "BinLocalize"
    if not loc_root.is_dir():
        return None

    loc_dirs = sorted(path for path in loc_root.iterdir() if path.is_dir())
    if language:
        loc_dir = loc_root / language
        if loc_dir.is_dir():
            print(f"Localization: {loc_dir.name}")
            return loc_dir
        fallback = next((path for path in loc_dirs if path.name == "dev_CN"), None)
        if fallback:
            print(f"Localization '{language}' not found; using {fallback.name}")
            return fallback
        if loc_dirs:
            print(f"Localization '{language}' not found; using {loc_dirs[0].name}")
            return loc_dirs[0]
        return None

    preferred = next((path for path in loc_dirs if path.name == "dev_CN"), None)
    loc_dir = preferred or (loc_dirs[0] if loc_dirs else None)
    if loc_dir:
        print(f"Localization: {loc_dir.name}")
    return loc_dir


def decode_tables(bin_root: Path, output_dir: Path, language: str | None) -> tuple[int, int]:
    schema_dir = bin_root / "BinConf"
    loc_dir = resolve_loc_dir(bin_root, language)
    data_out = output_dir / "data" / "BinData"
    tables_out = output_dir / "data" / "tables"
    data_out.mkdir(parents=True, exist_ok=True)
    tables_out.mkdir(parents=True, exist_ok=True)

    decoded = 0
    failed = 0
    seen: set[str] = set()
    sources = [
        ("BinDataCompressed", bin_root / "BinDataCompressed"),
        ("BinData", bin_root / "BinData"),
    ]

    for bin_type, source_dir in sources:
        if not source_dir.is_dir():
            continue
        for bytes_path in sorted(source_dir.glob("*.bytes")):
            name = bytes_path.stem
            if name in seen:
                continue
            schema_path = schema_dir / f"{name}.non"
            if not schema_path.exists():
                schema_path = schema_dir / f"{name}.json"
            if not schema_path.exists():
                continue

            loc_path = loc_dir / bytes_path.name if loc_dir else None
            try:
                payload = decode_file(
                    str(bytes_path),
                    schema_path=str(schema_path),
                    bin_type=bin_type,
                    loc_path=str(loc_path) if loc_path and loc_path.exists() else None,
                )
            except Exception as exc:
                failed += 1
                if failed <= 20:
                    print(f"  SKIP {name}: {exc}")
                continue

            out_path = data_out / f"{name}.json"
            write_json(out_path, payload)
            if name in TABLES_DIR_NAMES:
                write_json(tables_out / f"{name}.json", payload)
            seen.add(name)
            decoded += 1
            print(f"  OK {name}")

    return decoded, failed


def copy_assets(temp_dir: Path, output_dir: Path) -> int:
    copied = 0
    generated_assets = temp_dir / "assets"
    assets_out = output_dir / "assets"
    if assets_out.exists():
        shutil.rmtree(assets_out)
    if not generated_assets.is_dir():
        return 0
    for path in sorted(generated_assets.rglob("*")):
        if not path.is_file():
            continue
        suffix = path.suffix.lower()
        if suffix != ".webp":
            continue
        rel = path.relative_to(generated_assets)
        dest = assets_out / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            stem = dest.stem
            counter = 2
            while dest.exists():
                dest = dest.with_name(f"{stem}_{counter}{dest.suffix}")
                counter += 1
        shutil.copy2(path, dest)
        copied += 1
    return copied


def copy_static_data(output_dir: Path) -> None:
    static_types = Path(__file__).with_name("types.json")
    if static_types.exists():
        shutil.copy2(static_types, output_dir / "data" / "types.json")


def sync_pet_data(output_dir: Path) -> None:
    script = Path(__file__).with_name("sync-pet-data.mjs")
    if not script.exists():
        return
    subprocess.run(["node", str(script), str(output_dir / "data")], check=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export extracted data and assets.")
    parser.add_argument("temp_dir", help="Directory produced by extract_paks")
    parser.add_argument("output_dir", help="Output directory")
    parser.add_argument("--language", default=None, help="Localization folder under BinLocalize; auto-detects when omitted")
    parser.add_argument("--skip-assets", action="store_true", help="Only export JSON data")
    parser.add_argument("--skip-pets", action="store_true", help="Only export raw BinData and table mirrors")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    temp_dir = Path(args.temp_dir)
    output_dir = Path(args.output_dir)
    bin_root = find_bin_root(temp_dir)
    print(f"Bin root: {bin_root}")
    decoded, failed = decode_tables(bin_root, output_dir, args.language)
    copy_static_data(output_dir)
    assets = 0 if args.skip_assets else copy_assets(temp_dir, output_dir)
    if not args.skip_pets:
        sync_pet_data(output_dir)
    print(f"Decoded tables: {decoded}")
    print(f"Skipped tables: {failed}")
    print(f"Assets copied: {assets}")
    return 0 if decoded else 1


if __name__ == "__main__":
    sys.exit(main())
