"""Check archived artifact integrity, local links and field-data exclusions."""
import csv
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
listed = subprocess.run(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
    cwd=ROOT, check=True, capture_output=True,
).stdout.decode().split("\0")
paths = sorted({name for name in listed if name})
errors = []

with (ROOT / "data/review_artifact_manifest.csv").open(newline="") as stream:
    artifacts = list(csv.DictReader(stream))
for artifact in artifacts:
    path = ROOT / artifact["path"]
    if not path.is_file():
        errors.append(f"Missing artifact: {artifact['path']}")
        continue
    content = path.read_bytes()
    sha = hashlib.sha1(f"blob {len(content)}\0".encode() + content).hexdigest()
    if len(content) != int(artifact["size_bytes"]) or sha != artifact["git_blob_sha1"]:
        errors.append(f"Artifact differs from original: {artifact['path']}")

link_count = 0
for name in paths:
    path = ROOT / name
    if path.suffix.lower() == ".json":
        json.loads(path.read_text(encoding="utf-8"))
    if path.suffix.lower() == ".md":
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            target = target.strip().split()[0].strip("<>")
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            destination = (path.parent / unquote(parsed.path)).resolve()
            if not destination.is_relative_to(ROOT) or not destination.exists():
                errors.append(f"Broken local link in {name}: {target}")
            link_count += 1
    if path.suffix.lower() == ".csv" and "venezuela" in name.lower():
        with path.open(newline="", encoding="utf-8") as stream:
            fields = {field.lower() for field in next(csv.reader(stream))}
        coordinate_fields = {"longitude", "latitude", "decimallongitude", "decimallatitude", "lon", "lat"}
        if fields & coordinate_fields:
            errors.append(f"Coordinate-bearing Venezuelan CSV in public tree: {name}")

if errors:
    raise SystemExit("Repository checks failed:\n" + "\n".join(errors))
print(f"Verified {len(artifacts)} original artifacts, {link_count} local Markdown links, JSON syntax and Venezuelan CSV exclusions.")
