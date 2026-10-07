#!/usr/bin/env bash
set -euo pipefail
DOCS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$DOCS_DIR/build/html"
DESTINATION="$DOCS_DIR/html"
if [[ ! -f "$SOURCE/index.html" ]]; then
  echo "Chưa có bản build đầy đủ. Chạy bash calibration/docs/build.sh trước." >&2
  exit 1
fi
rm -rf -- "$DESTINATION"
cp -R -- "$SOURCE" "$DESTINATION"
# Keep generated HTML diffs clean across Sphinx versions.
python3 - "$DESTINATION" <<'PYTHON'
from pathlib import Path
import sys
for path in Path(sys.argv[1]).rglob('*.html'):
    text = path.read_text()
    path.write_text('\n'.join(line.rstrip() for line in text.split('\n')))
PYTHON
echo "Đã cập nhật $DESTINATION"
