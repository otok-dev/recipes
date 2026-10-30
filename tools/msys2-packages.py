#!/usr/bin/env python3
# Pins MSYS2 packages as resources of a recipe: the packages a recipe names and the packages they depend on, each with
# its URL and SHA-256, as the database of the MSYS2 repository gives them, checked against the downloaded files.
#
#     python tools/msys2-packages.py make/4.4/recipe.toml
#
# The resources are the lines of recipe.toml between
#
#     # BEGIN MSYS2 packages: make bash coreutils
#     # END MSYS2 packages
#
# and the packages after the colon are the ones the recipe needs; the script rewrites the lines between with the
# packages of today's repository. msys2-runtime is always among them: every package needs it without saying so.
# Needs Python 3.14 (compression.zstd).

import hashlib
import io
import re
import sys
import tarfile
import textwrap
import urllib.request

REPOSITORY = "https://repo.msys2.org/msys/x86_64/"
HOSTS = '["windows-x86_64", "windows-arm64"]'
BEGIN = re.compile(r"^# BEGIN MSYS2 packages:(.*)$")
END = "# END MSYS2 packages"


def fetch(url):
    with urllib.request.urlopen(url) as response:
        return response.read()


def read_database():
    packages, provided = {}, {}
    with tarfile.open(fileobj=io.BytesIO(fetch(REPOSITORY + "msys.db")), mode="r:zst") as db:
        for member in db:
            if not member.name.endswith("/desc"):
                continue
            fields, key = {}, None
            for line in db.extractfile(member).read().decode().splitlines():
                if line.startswith("%") and line.endswith("%"):
                    key = line.strip("%")
                    fields[key] = []
                elif line:
                    fields[key].append(line)
            name = fields["NAME"][0]
            packages[name] = fields
            for p in fields.get("PROVIDES", []):
                provided.setdefault(re.split("[<>=]", p)[0], name)
    return packages, provided


def closure(roots, packages, provided):
    chosen, pending = set(), ["msys2-runtime", *roots]
    while pending:
        wanted = re.split("[<>=]", pending.pop())[0]
        name = wanted if wanted in packages else provided.get(wanted)
        if name is None:
            sys.exit(f"no MSYS2 package is or provides '{wanted}'")
        if name not in chosen:
            chosen.add(name)
            pending.extend(packages[name].get("DEPENDS", []))
    return sorted(chosen)


def resource(fields):
    name, file, sha256 = fields["NAME"][0], fields["FILENAME"][0], fields["SHA256SUM"][0]
    data = fetch(REPOSITORY + file)
    if hashlib.sha256(data).hexdigest() != sha256:
        sys.exit(f"{file} does not match the SHA-256 of the database")
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:zst") as package:
        # hard links are files once unpacked; a symbolic link needs a privilege on Windows
        links = [m.name for m in package if m.issym()]
    if links:
        sys.exit(f"{file} has symbolic links: {', '.join(links)}")
    return "\n".join([
        "[[resource]]",
        f'name = "msys2_{re.sub("[^a-z0-9]", "_", name)}"',
        f'url = "{REPOSITORY}{file}"',
        f'sha256 = "{sha256}"',
        f"when = {{ host = {HOSTS} }}",
    ])


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: msys2-packages.py <recipe.toml>")
    path = sys.argv[1]
    with open(path, encoding="utf-8", newline="") as f:
        lines = f.read().splitlines()
    begin = next((i for i, line in enumerate(lines) if BEGIN.match(line)), None)
    if begin is None or END not in lines[begin:]:
        sys.exit(f"{path} has no lines '# BEGIN MSYS2 packages: …' and '{END}'")
    end = lines.index(END, begin)
    roots = BEGIN.match(lines[begin]).group(1).split()
    packages, provided = read_database()
    chosen = closure(roots, packages, provided)
    blocks = [resource(packages[name]) for name in chosen]
    listed = ", ".join(f"{name} {packages[name]['VERSION'][0]}" for name in chosen)
    text = [lines[begin], *("# " + line for line in textwrap.wrap(listed, 118)), "", "\n\n".join(blocks), "", END]
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines[:begin] + text + lines[end + 1:]) + "\n")
    print(f"{len(chosen)} packages: {listed}")


if __name__ == "__main__":
    main()
