# AgentForge Task: Remove Stale Mobile Data And Wire Live Diagnostics

You are an external CLI subagent. Codex is the orchestrator/reviewer only.

Working directory:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile`

Repo root:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp`

## Goal

Fix stale/hardcoded visible data in the Flutter mobile app so live mode shows real daemon/app state instead of fake sample values.

## Required fixes

1. Remove hardcoded fallback device rows from `lib/features/settings/presentation/devices_screen.dart`.
   - Do not show `MacBook Pro · Local` or `Ubuntu Workstation` when the daemon returns no trusted devices.
   - Show an empty state instead.

2. Remove visible hardcoded identity/device labels from `lib/features/settings/presentation/settings_screen.dart`.
   - Do not hardcode `Muhammad` or `MacBook Pro · Local`.
   - Use live controller/repository data where available.
   - If no user/profile name exists in the protocol yet, use neutral device/session labels derived from live data or show a real empty/unknown state. Do not invent a person name.

3. Replace hardcoded connected diagnostics in live settings.
   - `DaemonSettingsRepository.readDiagnostics()` currently returns a const `TransportDiagnostics(state: 'connected')`.
   - Add a daemon admin diagnostics endpoint if needed, or compute diagnostics from actual daemon/admin reachability.
   - Keep ASCP protocol semantics intact; do not invent core ASCP methods.

4. Add/adjust tests.
   - Add focused tests proving empty trusted devices do not render demo devices.
   - Add focused tests proving settings does not render hardcoded `Muhammad` / `MacBook Pro · Local` without live data.
   - Add tests for live diagnostics behavior or daemon diagnostics endpoint.

## Constraints

- Do not touch unrelated dirty files such as root `package-lock.json` unless truly required.
- Keep changes scoped to mobile settings/devices and host-daemon admin diagnostics if needed.
- Preserve protocol-first ASCP method names.
- Update `internal/plans.md` / `internal/status.md` only if your changes are complete.
- Create a short subagent report at:
  `qa-reports/2026-05-31-kiro-real-data-fix-report.md`

## Verification to run

```bash
flutter test test/widget/settings_screen_test.dart
flutter test test/features/settings/settings_controller_test.dart
flutter test
npm --workspace @ascp/host-daemon run test
flutter analyze
```

Report all commands and results.
