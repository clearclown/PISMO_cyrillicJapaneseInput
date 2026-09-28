#!/usr/bin/env python3
"""Fetch pinned upstream assets; never replace a verified local asset."""
import hashlib
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MODELS = [
    ("xsmall", "5c0c4db8c8cc66a6ef01520475bebd56b41f6236", "189638370c43292fd54ba5e83854b24887ddd57e8914e19095514e663f60c7f5"),
    ("small", "ddf6e44b2e05ab7ea9a3e31559c5e7948761365c", "4de930c06bef8c263aa1aa40684af206db4ce1b96375b3b8ed0ea508e0b14f6c"),
]
EMOJI_REVISION = "eb15a8d1ea7c0688932d468024e62aa9c2d961c4"


def download(url, target, checksum=None):
    if target.exists() and (checksum is None or hashlib.sha256(target.read_bytes()).hexdigest() == checksum):
        print(f"Verified {target.relative_to(ROOT)}", flush=True)
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(target.suffix + ".download")
    print(f"Fetching {target.relative_to(ROOT)}", flush=True)
    request = urllib.request.Request(url, headers={"User-Agent": "Pismo-resource-setup/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=120) as response, temporary.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
        if checksum and hashlib.sha256(temporary.read_bytes()).hexdigest() != checksum:
            raise RuntimeError(f"Checksum mismatch: {target}")
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)


def main():
    for size, revision, checksum in MODELS:
        folder = f"zenz-v3.1-{size}-gguf"
        download(f"https://huggingface.co/Miwa-Keita/{folder}/resolve/{revision}/ggml-model-Q5_K_M.gguf",
                 ROOT / "iOS" / folder / "ggml-model-Q5_K_M.gguf", checksum)
    # These files are copied into both app and keyboard extension by Xcode.
    for version in ["13.1", "14.0", "15.0", "15.1", "16.0", "17.0"]:
        for kind in ["all", "dict", "genre"]:
            name = f"emoji_{kind}_E{version}.txt"
            download(f"https://raw.githubusercontent.com/azooKey/azooKey_emoji_dictionary_storage/{EMOJI_REVISION}/EmojiDictionary/{name}",
                     ROOT / "iOS/pismo_emoji_dictionary_storage/EmojiDictionary" / name)
    print("iOS resources ready.", flush=True)


if __name__ == "__main__":
    main()
