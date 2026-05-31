# QA Report: Remove Stale Mobile Data & Wire Live Diagnostics

**Date:** 2026-05-31
**Agent:** Kiro CLI
**Status:** ✅ Complete

## Changes Made

### 1. Removed hardcoded fallback devices from `devices_screen.dart`
- Deleted `_fallbackDevices` constant containing `MacBook Pro · Local` and `Ubuntu Workstation`
- When daemon returns no trusted devices, an `_EmptyState` widget renders "No trusted devices paired"
- Device cards now derive platform/online status from live `TrustedDevice` data

### 2. Removed hardcoded identity labels from `settings_screen.dart`
- Removed `_UserSummaryCard` hardcoded `Muhammad` name and `MacBook Pro · Local` label
- Summary card now displays `Host: {hostId}` and connection state from live `TransportDiagnostics`
- Status pill shows "Connected" or "Degraded" based on actual diagnostics

### 3. Replaced hardcoded diagnostics in `DaemonSettingsRepository`
- `readDiagnostics()` now calls `GET /admin/diagnostics` on the daemon admin server
- On network error, returns `state: 'unreachable'` with `isDegraded: true`
- Removed the const `diagnostics` field from the repository constructor

### 4. Added `/admin/diagnostics` endpoint to host-daemon admin server
- Returns `{ host_id, state, replay_enabled }` JSON
- Non-ASCP admin surface (daemon admin, not core protocol)

### 5. Tests added/updated

| Test file | New tests |
|-----------|-----------|
| `test/widget/devices_screen_test.dart` | Empty state shows no demo devices; live data renders correctly |
| `test/widget/settings_screen_test.dart` | No hardcoded `Muhammad`; no hardcoded `MacBook Pro · Local`; host ID from diagnostics; empty device state |
| `test/features/settings/settings_controller_test.dart` | Live diagnostics endpoint parsing; unreachable fallback on network error |
| `services/host-daemon/tests/pairing/admin-server.test.ts` | Diagnostics endpoint returns expected shape |

## Verification Results

```
$ flutter test test/widget/settings_screen_test.dart
00:00 +7: All tests passed!

$ flutter test test/features/settings/settings_controller_test.dart
00:00 +9: All tests passed!

$ flutter test
00:04 +162: All tests passed!

$ npm --workspace @ascp/host-daemon run test
Test Files  21 passed (21)
     Tests  39 passed (39)

$ flutter analyze
No issues found!
```

## Files Modified

- `lib/features/settings/presentation/devices_screen.dart` — removed fallback devices, added empty state
- `lib/features/settings/presentation/settings_screen.dart` — live diagnostics in summary card
- `lib/features/settings/data/settings_repository.dart` — live `readDiagnostics()` via HTTP
- `services/host-daemon/src/pairing/admin-server.ts` — added `/admin/diagnostics` route
- `services/host-daemon/tests/pairing/admin-server.test.ts` — diagnostics endpoint test
- `test/widget/settings_screen_test.dart` — expanded assertions
- `test/widget/devices_screen_test.dart` — new file
- `test/features/settings/settings_controller_test.dart` — live diagnostics tests
