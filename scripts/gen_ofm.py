#!/usr/bin/env python3
"""Generate a Swift output-file-map for incremental compilation.

Usage:  python3 gen_ofm.py <build_dir> <module_name> [source files...]

Outputs valid JSON to stdout with per-file .o and .swiftdeps paths.
"""

import json, os, sys


def main() -> None:
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <build_dir> <module_name> [sources...]",
              file=sys.stderr)
        sys.exit(1)

    build_dir = sys.argv[1]
    module_name = sys.argv[2]
    sources = sys.argv[3:]

    d: dict[str, dict[str, str]] = {
        "": {
            "swift-dependencies": os.path.join(
                build_dir, module_name + ".swiftdeps"
            )
        }
    }

    for src in sources:
        base = os.path.splitext(os.path.basename(src))[0]
        d[src] = {
            "object": os.path.join(build_dir, base + ".o"),
            "swift-dependencies": os.path.join(build_dir, base + ".swiftdeps"),
        }

    json.dump(d, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
