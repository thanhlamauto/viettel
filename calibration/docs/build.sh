#!/usr/bin/env bash
set -euo pipefail
DOCS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$DOCS_DIR/.venv/bin/sphinx-build" -W --keep-going -b html "$DOCS_DIR/source" "$DOCS_DIR/build/html"
