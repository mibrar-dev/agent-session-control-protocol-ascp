# AgentForge Task: iOS Simulator Live QA Using ios-simulator-skill

You are an external CLI subagent. Codex is the orchestrator/reviewer only.

Working directory:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile`

Repo root:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp`

iOS simulator skill scripts root:
`/Users/ibrar/.codex/skills/ios-simulator-skill/ios-simulator-skill/skills/ios-simulator-skill/scripts`

## Goal

Run live QA against the Flutter iOS simulator app with the real ASCP host daemon, using the iOS simulator skill scripts for environment checks, app lifecycle, screen mapping, accessibility, and state capture.

## Rules

- Do not modify source code.
- Use scripts from the iOS simulator skill where possible:
  - `sim_health_check.sh`
  - `app_launcher.py`
  - `screen_mapper.py`
  - `navigator.py`
  - `keyboard.py`
  - `accessibility_audit.py`
  - `app_state_capture.py`
  - `log_monitor.py`
- Prefer accessibility-tree mapping over screenshots for navigation.
- Create only this report:
  `qa-reports/2026-05-31-gemini-ios-simulator-live-qa.md`
- If a step cannot be completed, state the exact command and error.

## Backend setup

Start or reuse the host daemon:

```bash
ASCP_HOST=127.0.0.1 ASCP_PORT=9875 ASCP_ADMIN_PORT=9876 \
ASCP_DATABASE_PATH=/private/tmp/continuum-mobile-gemini-live-qa.sqlite \
npm --workspace @ascp/host-daemon run start
```

Generate a fresh pairing code:

```bash
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"requested_scopes":["read:hosts","read:runtimes","read:sessions","write:sessions","read:approvals","write:approvals","read:artifacts"]}' \
  http://127.0.0.1:9876/admin/pairing/sessions
```

## App build/run

Build the app for iOS simulator with live dart-defines:

```bash
flutter build ios --simulator --debug \
  --dart-define=CONTINUUM_MOBILE_MODE=live \
  --dart-define=CONTINUUM_ASCP_RPC_ENDPOINT=http://127.0.0.1:9875/rpc \
  --dart-define=CONTINUUM_ASCP_WS_ENDPOINT=ws://127.0.0.1:9875/rpc \
  --dart-define=CONTINUUM_DAEMON_ADMIN_BASE_URL=http://127.0.0.1:9876 \
  --dart-define=CONTINUUM_HOST_ID=host_local \
  --dart-define=CONTINUUM_ACTIVE_SESSION_ID=sess_active \
  --dart-define=CONTINUUM_DEVICE_ID=device_mobile
```

Install/launch with the skill:

```bash
python /Users/ibrar/.codex/skills/ios-simulator-skill/ios-simulator-skill/skills/ios-simulator-skill/scripts/app_launcher.py --install build/ios/iphonesimulator/Runner.app --json
python /Users/ibrar/.codex/skills/ios-simulator-skill/ios-simulator-skill/skills/ios-simulator-skill/scripts/app_launcher.py --launch app.continuum.mobile --json
```

## QA coverage

Test and report:

1. Environment health.
2. App launches in live mode.
3. Pairing screen shows six OTP fields and no stale sample host/user data.
4. Try entering the fresh six-digit code using semantic navigation/keyboard.
5. If claim succeeds, approve host through admin endpoint and verify trusted shell.
6. Map Home, Sessions, Approvals, Devices, Settings screens if reachable.
7. Verify no visible hardcoded `Muhammad`, `MacBook Pro · Local`, `Ubuntu Workstation`, fake latency, fake CPU/memory/agent stats.
8. Run accessibility audit on current visible screen.
9. Capture final app state with screenshot/logs.

## Report format

Use:

```markdown
# Gemini iOS Simulator Live QA

## Environment
## Backend
## Build And Launch
## Pairing Flow
## Screen Coverage
## Stale Data Audit
## Accessibility
## Logs And Screenshots
## Failures / Blockers
## Recommendations
```
