# OpenCode iOS Simulator QA Task

You are an AgentForge subagent. Codex is only the reviewer/verifier for this task.

Workspace:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile`

Repository root:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp`

Use the iOS simulator skill scripts from:
`/Users/ibrar/.codex/skills/ios-simulator-skill/ios-simulator-skill/skills/ios-simulator-skill/scripts`

Goal:
Run live QA against the Flutter iOS app using the real local backend/daemon path. Do not modify source code. Write a Markdown report only.

Required checks:
1. Confirm iOS simulator tooling health using the skill script health check.
2. Build or run the Flutter iOS app on an available booted simulator.
3. Run or reuse the local ASCP host daemon/admin backend needed for live pairing and settings diagnostics.
4. Launch the app with live configuration, including localhost/loopback URLs needed for the simulator.
5. Capture structured UI evidence using `screen_mapper.py` and `accessibility_audit.py`.
6. Exercise at least these surfaces semantically where possible:
   - Home
   - Sessions
   - Active session/chat if reachable
   - Approvals
   - Devices
   - Settings
   - Pairing/manual pair-code entry if reachable
7. Verify there are no visible stale demo values such as:
   - `Muhammad`
   - `MacBook Pro · Local`
   - `Ubuntu Workstation`
   - `18 ms`
   - `Paired Apr`
   - `Last heartbeat 4s ago`
8. Capture screenshots only as files. Do not paste or read binary screenshots into the conversation. Include absolute screenshot paths in the report.
9. Record exact commands run, pass/fail outcome, blockers, and any runtime errors/log warnings.

If a surface cannot be reached, report the exact blocker and continue to the next surface. Prefer accessibility-tree navigation over image analysis.

Output:
Write the report to:
`/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/agent-session-control-protocol-ascp/apps/mobile/qa-reports/2026-05-31-opencode-ios-simulator-skill-qa.md`

The report must include:
- Environment and simulator used
- Backend process/ports used
- App launch configuration
- Per-screen QA results
- Accessibility audit summary
- Screenshot paths
- Stale-data audit result
- Final pass/fail verdict

Do not commit changes.
