#!/usr/bin/env python3
"""Decide whether a project's docker-compose.yaml is too complex to adapt.

Prints 1 (complex, preserve the file) or 0 (Podium may use its own template).

Lives in a file rather than a heredoc inside setup_project.sh because bash 3.2 —
what macOS ships — could not parse the `$( ... << 'PYEOF' ... )` form once the
python contained a `.strip('\\'"')`. Its parser scans for the closing paren of
the command substitution and the quote sequence defeated it, so the whole script
failed with "unexpected EOF while looking for matching `)'". bash 5 parsed it
without complaint, so `bash -n` on Linux said nothing was wrong.

Imports nothing beyond the standard library. It used to `import yaml`, which
macOS's python3 does not have, and that import sat outside the try below — so
the check exited non-zero and took setup with it. Worse, its except branch
printed 0 ("not complex"), which tells setup to REPLACE the project's compose
file. A missing module would have silently overwritten cloned projects.

Any trouble now reports complex, so the file is preserved. That is the safe
direction to be wrong in.
"""
import re
import sys


def main():
    try:
        raw = open(sys.argv[1], errors="replace").read()
    except Exception:
        print(1)
        return

    try:
        # Laravel Sail composes need vendor/ to exist before the container can
        # build, so adaptation is impossible — let Podium use its own template.
        if "laravel/sail" in raw:
            print(0)
            return

        lines = raw.split("\n")
        si = next((i for i, l in enumerate(lines)
                   if re.match(r"^services:\s*$", l)), None)
        if si is None:
            print(0)
            return

        # Service keys are the entries exactly one indent level inside
        # `services:`; anything deeper belongs to a service definition.
        names, images, indent = [], [], None
        for line in lines[si + 1:]:
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            width = len(line) - len(line.lstrip())
            if width == 0:
                break                       # back out to a top-level key
            if indent is None:
                indent = width
            if width == indent:
                m = re.match(r"^\s*([A-Za-z0-9._-]+):\s*$", line)
                if m:
                    names.append(m.group(1))
            m = re.match(r"^\s*image:\s*(.+?)\s*$", line)
            if m:
                images.append(m.group(1).strip("\"'"))

        if len(names) > 1:
            print(1)
            return
        for img in images:
            if img and not re.search(r"canebaycomputers/cbc", img, re.I):
                print(1)
                return
        print(0)
    except Exception:
        print(1)


if __name__ == "__main__":
    main()
