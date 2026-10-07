#!/usr/bin/env python3
"""Build AR glTF Material Forge as an Autodesk 3ds Max MZP package."""

from __future__ import annotations

import argparse
from pathlib import Path
import zipfile


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
DEFAULT_VERSION = "1.3.1"


def build(version: str = DEFAULT_VERSION) -> Path:
    required = [
        SRC / "mzp.run",
        SRC / "install.ms",
        SRC / "payload" / "ar_gltf_material_forge.py",
        SRC / "payload" / "open_panel.py",
        SRC / "payload" / "startup.py",
    ]

    missing = [path for path in required if not path.exists()]
    if missing:
        formatted = "\n".join(str(p) for p in missing)
        raise SystemExit(f"Missing required package files:\n{formatted}")

    dist = ROOT / "dist"
    dist.mkdir(parents=True, exist_ok=True)

    out = dist / f"AR_glTF_Material_Forge_{version.replace('.', '_')}.mzp"

    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(SRC.rglob("*")):
            if not path.is_file():
                continue
            if "__pycache__" in path.parts or path.suffix == ".pyc":
                continue
            archive.write(path, path.relative_to(SRC).as_posix())

    with zipfile.ZipFile(out, "r") as archive:
        names = set(archive.namelist())
        if "mzp.run" not in names or "install.ms" not in names:
            raise SystemExit("Built archive is missing required MZP root files.")

    print(out)
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default=DEFAULT_VERSION)
    args = parser.parse_args()
    build(args.version)


if __name__ == "__main__":
    main()
