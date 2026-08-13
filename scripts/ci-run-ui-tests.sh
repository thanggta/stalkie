#!/bin/bash
# Execute FullLoopUITests on an available iPhone simulator.
# Distinguishes infrastructure failure (no sim, boot, destination) from
# test failure (xcodebuild 65 / failed test cases).
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RESULT_DIR="${ROOT}/TestResults"
RESULT_BUNDLE="${RESULT_DIR}/FullLoop.xcresult"
mkdir -p "$RESULT_DIR"
rm -rf "$RESULT_BUNDLE"

infra() {
  echo "INFRA: $*" >&2
  exit 2
}

testfail() {
  echo "TEST: $*" >&2
  exit 1
}

echo "== Selecting iPhone simulator"

UDID="$(
  python3 - <<'PY'
import json, subprocess, sys

raw = subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "-j"],
    text=True,
)
data = json.loads(raw)
candidates = []
for runtime, devices in data.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        name = d.get("name", "")
        if not d.get("isAvailable", False):
            continue
        if "iPhone" not in name or "iPad" in name:
            continue
        # Prefer modern full-size iPhones; skip SE / Plus / Air when possible.
        score = 0
        if any(tok in name for tok in ("16", "17", "15 Pro", "15")):
            score += 10
        if "Pro" in name:
            score += 1
        if "SE" in name:
            score -= 5
        candidates.append((score, runtime, name, d["udid"]))

if candidates:
    candidates.sort(reverse=True)
    _, runtime, name, udid = candidates[0]
    print(f"{udid}\t{name}\t{runtime}", file=sys.stderr)
    print(udid)
    sys.exit(0)

runtimes = json.loads(
    subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "-j"], text=True)
)
ios = [
    r
    for r in runtimes.get("runtimes", [])
    if r.get("isAvailable") and "iOS" in r.get("name", "")
]
if not ios:
    sys.exit(1)
ios.sort(key=lambda r: r.get("version", ""), reverse=True)
runtime = ios[0]["identifier"]

devicetypes = json.loads(
    subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "-j"], text=True)
)
iphones = [
    t
    for t in devicetypes.get("devicetypes", [])
    if t.get("productFamily") == "iPhone" and "SE" not in t.get("name", "")
]
if not iphones:
    sys.exit(1)
iphones.sort(key=lambda t: t.get("name", ""), reverse=True)
dtype = iphones[0]["identifier"]
name = "CARVE-CI-iPhone"
try:
    udid = subprocess.check_output(
        ["xcrun", "simctl", "create", name, dtype, runtime], text=True
    ).strip()
except subprocess.CalledProcessError:
    sys.exit(1)
print(f"{udid}\t{name} (created)\t{runtime}", file=sys.stderr)
print(udid)
PY
)" || true

if [ -z "${UDID:-}" ]; then
  infra "no available iPhone simulator could be selected or created"
fi

echo "== Booting $UDID"
if ! xcrun simctl boot "$UDID" 2>/tmp/carve-sim-boot.err; then
  # "already booted" and "current state: Booted" are both success.
  if ! grep -Eqi "already booted|current state: Booted" /tmp/carve-sim-boot.err; then
    cat /tmp/carve-sim-boot.err >&2
    infra "failed to boot simulator $UDID"
  fi
fi

if ! xcrun simctl bootstatus "$UDID" -b >/tmp/carve-sim-bootstatus.log 2>&1; then
  cat /tmp/carve-sim-bootstatus.log >&2
  infra "simulator $UDID never reached Booted"
fi

# Isolate free-loop from StoreKit: shared simulator purchase state can
# contaminate either suite when they share one long test process.
run_suite() {
  local label="$1"
  local only="$2"
  local bundle="$3"
  echo "== Running ${label}"
  rm -rf "$bundle"
  set +e
  xcodebuild test \
    -project Apps/Carve.xcodeproj \
    -scheme Carve \
    -testPlan CarveUITests \
    -destination "platform=iOS Simulator,id=${UDID}" \
    -only-testing:"${only}" \
    -resultBundlePath "$bundle" \
    -derivedDataPath .build/DerivedData-UITest \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tee -a "${RESULT_DIR}/xcodebuild.log"
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

: > "${RESULT_DIR}/xcodebuild.log"

FULL_BUNDLE="${RESULT_DIR}/FullLoop.xcresult"
STORE_BUNDLE="${RESULT_DIR}/StoreKit.xcresult"
RESULT_BUNDLE="$FULL_BUNDLE"

run_suite "FullLoopUITests" "CarveUITests/FullLoopUITests" "$FULL_BUNDLE"
FULL_STATUS=$?

run_suite "StoreKitPurchaseUITests" "CarveUITests/StoreKitPurchaseUITests" "$STORE_BUNDLE"
STORE_STATUS=$?

if [ "$FULL_STATUS" -eq 0 ] && [ "$STORE_STATUS" -eq 0 ]; then
  echo "OK: CarveUITests passed (FullLoop + StoreKit)"
  exit 0
fi

# Destination / signing / build-system problems are infrastructure.
if grep -Eqi "Unable to find a destination|xcodebuild: error:|Failed to build|Could not find|No profiles for" \
  "${RESULT_DIR}/xcodebuild.log"; then
  infra "xcodebuild failed before tests ran (FullLoop=${FULL_STATUS} StoreKit=${STORE_STATUS})"
fi

if [ "$FULL_STATUS" -eq 70 ] || [ "$STORE_STATUS" -eq 70 ]; then
  infra "xcodebuild destination error (FullLoop=${FULL_STATUS} StoreKit=${STORE_STATUS})"
fi

testfail "CarveUITests failed (FullLoop=${FULL_STATUS} StoreKit=${STORE_STATUS})"
