#!/bin/bash
# Capture Stage-1 UI baselines on compact / Pro / Pro Max simulators.
# Fails if DesignBaselineCaptureUITests fails (missing a11y id = no blank shot).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="${DESIGN_REVIEW_DIR:-$ROOT/design-review/baseline}"
mkdir -p "$OUT"
export DESIGN_REVIEW_DIR="$OUT"

# Prefer available iPhones: compact (17e), Pro, Pro Max.
pick_udid() {
  local needle="$1"
  xcrun simctl list devices available -j | python3 -c "
import json,sys
needle=sys.argv[1]
data=json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime: continue
    for d in devices:
        if d.get('isAvailable') and needle in d.get('name',''):
            print(d['udid']); raise SystemExit
" "$needle"
}

DEVICES=(
  "iPhone 17e"
  "iPhone 17 Pro"
  "iPhone 17 Pro Max"
)

FAILED=0
for name in "${DEVICES[@]}"; do
  udid="$(pick_udid "$name" || true)"
  if [ -z "${udid:-}" ]; then
    echo "SKIP: no simulator named like '$name'"
    continue
  fi
  echo "== Capturing on $name ($udid)"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcodebuild \
    -project Apps/Carve.xcodeproj \
    -scheme Carve \
    -destination "platform=iOS Simulator,id=$udid" \
    -derivedDataPath .build/DerivedData \
    -only-testing:CarveUITests/DesignBaselineCaptureUITests \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY= \
    DESIGN_REVIEW_DIR="$OUT" \
    test || FAILED=1
done

echo "Baselines under $OUT"
find "$OUT" -name '*.png' | sort | head -80
exit $FAILED
