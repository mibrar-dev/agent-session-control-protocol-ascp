# Kiro iOS Simulator QA Task

You are an AgentForge subagent. Codex is only reviewer/verifier.

Workspace:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile`

Use the iOS simulator skill scripts from:
`/Users/ibrar/.codex/skills/ios-simulator-skill/ios-simulator-skill/skills/ios-simulator-skill/scripts`

Important:
- Do not use `flutter run --release` on simulator. Use debug/profile-compatible simulator build commands.
- Do not change source code.
- Do not read screenshot binary content into the model. Record screenshot paths only.
- Prefer existing booted simulator `iPhone 16 Pro` if available.

Task:
1. Use the iOS simulator skill to run `sim_health_check.sh`.
2. Use the already installed app if present, or build/install a debug simulator build.
3. Launch `app.continuum.mobile`.
4. Use `screen_mapper.py`, `navigator.py`, `accessibility_audit.py`, and `app_state_capture.py` to inspect:
   - Pairing screen or trusted shell start state
   - Home
   - Sessions
   - Approvals
   - Devices
   - Settings
   - Active session/chat if reachable from Sessions
5. Capture screenshots to files and list absolute paths.
6. Audit visible UI text for stale demo values:
   `Muhammad`, `MacBook Pro · Local`, `Ubuntu Workstation`, `18 ms`, `Paired Apr`, `Last heartbeat 4s ago`, `0.1.0`, `Just now`.
7. If backend endpoints block live verification, record the exact endpoint/status and continue UI QA.

Write only a Markdown report to:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/2026-05-31-kiro-ios-simulator-skill-qa.md`

Include:
- simulator/device used
- backend/admin endpoint observations
- commands run
- per-screen pass/fail table
- accessibility audit summary
- stale-data audit result
- screenshot paths
- final verdict and blockers
