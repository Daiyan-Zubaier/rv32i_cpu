#!/usr/bin/env python3
import os
import re
import sys
import tempfile


VAR_RE = re.compile(r"^(\s*\$var\s+\S+\s+\d+\s+)(\S+)(.*\$end\s*)$")
SCALAR_RE = re.compile(r"^([01xXzZ])(\S+)(\s*)$")
VECTOR_RE = re.compile(r"^([bBrR]\S*)\s+(\S+)(\s*)$")


def make_id(index, used_ids):
    while True:
        candidate = f"__alias{index}"
        index += 1
        if candidate not in used_ids:
            used_ids.add(candidate)
            return candidate, index


def dealias_lines(lines):
    var_lines = []
    used_ids = set()

    for line in lines:
        match = VAR_RE.match(line)
        if match:
            old_id = match.group(2)
            used_ids.add(old_id)
            var_lines.append((line, old_id))

    counts = {}
    for _, old_id in var_lines:
        counts[old_id] = counts.get(old_id, 0) + 1

    remap = {}
    next_id = 0
    for _, old_id in var_lines:
        if counts[old_id] <= 1:
            continue
        new_id, next_id = make_id(next_id, used_ids)
        remap.setdefault(old_id, []).append(new_id)

    if not remap:
        return lines

    seen_var = {}
    out = []
    for line in lines:
        match = VAR_RE.match(line)
        if match:
            old_id = match.group(2)
            if old_id in remap:
                index = seen_var.get(old_id, 0)
                seen_var[old_id] = index + 1
                out.append(f"{match.group(1)}{remap[old_id][index]}{match.group(3)}")
            else:
                out.append(line)
            continue

        match = SCALAR_RE.match(line)
        if match and match.group(2) in remap:
            value = match.group(1)
            suffix = match.group(3)
            for new_id in remap[match.group(2)]:
                out.append(f"{value}{new_id}{suffix}")
            continue

        match = VECTOR_RE.match(line)
        if match and match.group(2) in remap:
            value = match.group(1)
            suffix = match.group(3)
            for new_id in remap[match.group(2)]:
                out.append(f"{value} {new_id}{suffix}")
            continue

        out.append(line)

    return out


def main():
    if len(sys.argv) not in (2, 3):
        print("usage: dealias_vcd.py INPUT [OUTPUT]", file=sys.stderr)
        return 2

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) == 3 else input_path

    with open(input_path, "r", encoding="utf-8") as file:
        output = dealias_lines(file.readlines())

    directory = os.path.dirname(os.path.abspath(output_path)) or "."
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=directory, delete=False) as file:
        temp_path = file.name
        file.writelines(output)

    os.replace(temp_path, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
