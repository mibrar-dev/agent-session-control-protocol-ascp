# iOS Simulator QA Report — 2026-05-31

## Environment

| Item | Value |
|------|-------|
| Simulator | iPhone 16 Pro (51992D3D-F500-43CB-A594-6B85AF7B1E21) |
| iOS Runtime | 18.5 |
| Xcode | 26.3 |
| macOS | 26.0.1 |
| Python | 3.14 |
| IDB | installed (homebrew) |
| App Bundle ID | app.continuum.mobile |
| App Mode | Memory (no `--dart-define` values; deterministic poll simulator) |
| Build | Debug simulator (`flutter build ios --simulator --debug --no-pub`) |

## Backend / Admin Endpoint Observations

| Endpoint | Status |
|----------|--------|
| `http://127.0.0.1:18787/rpc` (ASCP RPC) | **UNREACHABLE** — no daemon on this port |
| `http://127.0.0.1:18787/admin/pairing/sessions` | **UNREACHABLE** |
| `http://127.0.0.1:8765` (default manual host) | HTTP 404 (partial daemon, no pairing route) |
| `http://127.0.0.1:9876/admin/pairing/sessions` | HTTP 200 — daemon running, 2 pending sessions |
| `http://127.0.0.1:8767/admin/pairing/sessions` | HTTP 200 — daemon running, many historical sessions |

**Note:** The app was rebuilt without `--dart-define` values to use memory mode. In memory mode, code `111111` triggers `DeterministicPairingPollSimulator.approved` and bypasses the network entirely. Live daemon verification was not possible because the ASCP RPC endpoint (18787) is not running.

## Commands Run

```bash
# Health check
bash scripts/sim_health_check.sh

# Build & install (memory mode, no dart-defines)
flutter build ios --simulator --debug --no-pub
xcrun simctl install 51992D3D-F500-43CB-A594-6B85AF7B1E21 build/ios/iphonesimulator/Runner.app
xcrun simctl launch 51992D3D-F500-43CB-A594-6B85AF7B1E21 app.continuum.mobile

# Skill scripts
python3 scripts/screen_mapper.py --udid $UDID --json
python3 scripts/navigator.py --udid $UDID --list
python3 scripts/navigator.py --udid $UDID --find-text "Continue" --tap
python3 scripts/accessibility_audit.py --udid $UDID --verbose
python3 scripts/app_state_capture.py --udid $UDID --app-bundle-id app.continuum.mobile --inline

# IDB navigation
idb ui tap --udid $UDID <x> <y>
idb ui text --udid $UDID "1" (×6)
idb ui describe-all --udid $UDID

# Screenshots
xcrun simctl io $UDID screenshot <path>
```

## Per-Screen Pass/Fail

| Screen | Renders | Navigation | Content Correct | Stale Data | Verdict |
|--------|---------|------------|-----------------|------------|---------|
| Pairing (first-run) | ✅ | N/A (entry point) | ✅ QR frame + 6-digit code entry + instructions | None | **PASS** |
| Pairing (approved) | ✅ | Continue button works | ✅ "Host approved this device." | None | **PASS** |
| Home / Dashboard | ✅ | Bottom nav visible | ✅ host_1, 0 live sessions, summary counters | None | **PASS** |
| Sessions | ✅ | Tab tap works | ✅ "No active sessions" empty state | None | **PASS** |
| Approvals | ✅ | Tab tap works | ✅ "No pending approvals" + guidance text | None | **PASS** |
| Devices | ✅ | Tab tap works | ✅ "No trusted devices paired" + trust explanation | None | **PASS** |
| Settings | ✅ | Tab tap works | ✅ Full settings tree: appearance, notifications, connection, security, diagnostics | None | **PASS** |
| Active Session/Chat | ⚠️ | Not reachable | Memory mode has 0 sessions; no session detail to navigate to | N/A | **BLOCKED** |

## Accessibility Audit Summary

| Screen | Elements | Issues | Critical | Warnings |
|--------|----------|--------|----------|----------|
| Pairing | 14 | 20 | 0 | 20 |
| Home | 14 | 14 | 0 | 14 |
| Settings | 22 | 22 | 0 | 22 |

**Primary issue:** `missing_traits` (all elements lack `accessibilityTraits`). Flutter's iOS accessibility bridge exposes all elements as `StaticText` without semantic roles. Interactive elements (buttons, nav items) are not distinguished from static labels.

**Recommendation:** Add `Semantics` widgets with `button: true`, `header: true`, or `label` properties to interactive and structural elements.

## Stale-Data Audit

| Value | Found? | Screen |
|-------|--------|--------|
| `Muhammad` | ❌ Not found | — |
| `MacBook Pro · Local` | ❌ Not found | — |
| `Ubuntu Workstation` | ❌ Not found | — |
| `18 ms` | ❌ Not found | — |
| `Paired Apr` | ❌ Not found | — |
| `Last heartbeat 4s ago` | ❌ Not found | — |
| `0.1.0` | ❌ Not found | — |
| `Just now` | ❌ Not found | — |

**Result:** All stale demo values have been removed. The app shows only dynamic/generic content (`host_1`, `development`, `connected`, `ASCP`).

## Screenshot Paths

| # | Screen | Path |
|---|--------|------|
| 1 | Pairing (initial) | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/01-initial-screen.png` |
| 2 | Pairing (approved) | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/02-pairing-approved.png` |
| 3 | Home / Dashboard | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/03-home-dashboard.png` |
| 4 | Sessions | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/04-sessions.png` |
| 5 | Approvals | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/05-approvals.png` |
| 6 | Devices | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/06-devices.png` |
| 7 | Settings | `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/screenshots/07-settings.png` |

## Final Verdict

**PASS with caveats**

All reachable screens render correctly, navigate properly, and contain no stale demo data. The app launches, completes memory-mode pairing via `111111`, transitions to the trusted shell, and all 5 bottom-nav tabs are functional.

### Blockers

1. **Active Session/Chat not testable** — Memory mode provides 0 sessions. Testing session detail/chat requires either a live ASCP daemon on port 18787 or pre-seeded memory session data.
2. **ASCP RPC endpoint not running** — `http://127.0.0.1:18787/rpc` is unreachable. Live-mode verification requires starting the host daemon with matching port configuration.

### Recommendations

1. Add `Semantics` annotations to interactive elements (buttons, nav items, cards) to resolve the 56 `missing_traits` accessibility warnings.
2. Consider adding a `--dart-define=CONTINUUM_SEED_SESSIONS=true` flag for memory mode that pre-populates mock sessions, enabling session-detail QA without a live daemon.
3. The pairing code text fields lack accessibility labels — each should have a label like "Digit 1 of 6" for VoiceOver users.
