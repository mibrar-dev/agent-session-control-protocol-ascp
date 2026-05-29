# Continuum Mobile Live iOS QA Report

Date: 2026-05-29

Device: iPhone 16 Plus Simulator, iOS 18.5

Backend: ASCP host daemon on `127.0.0.1:8765`, pairing admin on `127.0.0.1:8767`

Build: Flutter debug, live mode, WebSocket ASCP transport

## Summary

The mobile app was tested against the real local ASCP daemon. Pairing completed through manual code entry, host approval, iOS credential confirmation, and trusted-shell navigation. Main app surfaces were exercised: Home, Sessions, live session detail and input, Approvals, Inspect, and Settings.

The adaptive UI pass removed the disconnected white/dark split by applying the Continuum dark surface, elevated surface, border, accent, success, and muted text tokens consistently across the shell, session list, and live detail screens.

## Agent Routing

Codex acted as orchestrator and QA reviewer.

Kiro CLI handled the adaptive UI implementation using `deepseek-3.2`.

Blackbox CLI produced the broad QA matrix using its default configured model after explicit external model names were rejected by the local Blackbox configuration.

## Test Matrix

| ID | Area | Action | Result |
| --- | --- | --- | --- |
| ENV-01 | Backend | Confirmed daemon listeners on `8765` and `8767`; created full-scope pairing session. | Pass |
| PAIR-01 | Pairing | Entered manual code, verified claim, approved on host, entered simulator passcode. | Pass |
| PAIR-02 | Pairing retry | Reproduced stale manual input after failed pairing, fixed retry clearing, added widget coverage. | Pass |
| DASH-01 | Home | Confirmed connected shell, active session count, recent sessions, trusted devices. | Pass |
| SESS-01 | Sessions | Opened live sessions list from backend data. | Pass |
| LIVE-01 | Live detail | Opened a live ASCP session detail feed. | Pass |
| LIVE-02 | Send input | Sent `hello from simulator after fix`; observed user bubble and live events over WebSocket. | Pass |
| APPR-01 | Approvals | Opened approvals queue; confirmed no pending approval empty state. | Pass |
| INSP-01 | Inspect | Relaunched with the active live session id and confirmed artifact metadata loads. | Pass |
| SET-01 | Settings | Opened settings and trusted device list from daemon admin data. | Pass |
| VIS-01 | Adaptive theme | Checked screenshots for cohesive dark surfaces, readable text, and visible controls. | Pass |

## Defects Fixed During QA

Manual pairing retry retained stale text after a failed attempt, causing subsequent entries to append into hidden previous input. The retry action now clears the manual text controller and unfocuses the field before returning to idle. A focused widget test covers this path.

The first Inspect run used a placeholder active session id and showed an unable-to-load state. Relaunching with the actual active session id loaded artifact metadata successfully. This is a configuration requirement for live mode rather than a UI regression.

## Verification Commands

```bash
flutter test test/widget/pairing_screen_test.dart
flutter test
flutter analyze
```

