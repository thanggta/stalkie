# Design review artifacts

Baseline and after-slice screenshots for the UI/UX redesign effort.

| Path | Contents |
|---|---|
| `baseline/<device>/` | Simulator captures from `DesignBaselineCaptureUITests` |
| `before/` | Snapshot of early Pro captures (if present) |
| `*.log` | Local xcodebuild logs (not required for CI) |

## Capture

```bash
scripts/capture-design-baseline.sh
# or single device:
xcodebuild -project Apps/Carve.xcodeproj -scheme Carve \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CarveUITests/DesignBaselineCaptureUITests \
  CODE_SIGNING_ALLOWED=NO test
```

The harness **fails** if a required accessibility identifier is missing (no blank wrong-screen shots).

PNGs may be large; keep them for design review. They are not required for CI green.
