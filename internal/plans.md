# ASCP Task Plan

This file tracks the active scoped work for the current branch.

## Planning Rules

- One active feature per branch.
- Update this file before implementation starts.
- Keep the plan scoped to the current feature only.
- Record the source documents that define the work.
- Mark task status as work progresses so a new session can resume cleanly.

## Active State

- Feature name: Mobile companion Flutter architecture and build plan
- Branch: `codex/mobile-live-real-data-qa`
- Goal: build the Flutter-first mobile companion app foundation with feature-first folders, shadcn UI primitives, exact ASCP core models, JSON-RPC transports, pairing/trust foundations, app shell, feature domain slices, and replay cursor persistence
- Source inputs:
  - `AGENTS.md`
  - `internal/plans.md`
  - `internal/status.md`
  - `README.md`
  - `protocol/ASCP_Protocol_Detailed_Spec_v0_1.md`
  - `protocol/ASCP_Protocol_PRD_and_Build_Guide.md`
  - `docs/superpowers/specs/2026-04-28-mobile-companion-design.md`
  - `docs/superpowers/plans/2026-04-28-mobile-companion.md`
  - `apps/mobile/index.html`
  - `apps/mobile/sessio.html`
  - `/Users/ibrar/Desktop/infinora.noworkspace/Continuum App/Continuum Design System/BUILD_ORDER.md`

## Scope

Included in this planning slice:

- define the Flutter app architecture under `apps/mobile`
- define feature-first folder ownership and boundaries
- choose default state management and allowed alternatives
- choose current Flutter/Dart packages for HTTP, WebSocket, routing, models, security, persistence, QR scanning, and tests
- translate the Continuum Design System build order into Flutter implementation phases
- require Flutter shadcn CLI initialization, dry-run-first component installation, validation, audit, and dependency checks
- require test-driven development, widget tests, golden tests, and integration tests before implementation is considered done

Explicitly out of scope:

- protocol redesign
- implementation code in this planning slice
- daemon backend changes
- host-console changes
- TLS network transport
- relay transport auth
- runtime-specific trust policy
- product UI behavior that changes ASCP semantics

## Planned Files

Files expected to be added or modified in this slice:

- `docs/superpowers/specs/2026-04-28-mobile-companion-design.md`
- `docs/superpowers/plans/2026-04-28-mobile-companion.md`
- `internal/plans.md`
- `internal/status.md` after the planning checkpoint is committed

## Tasks

| Status | Task | Acceptance Criteria |
| --- | --- | --- |
| completed | research current Flutter packages | package matrix includes current pub.dev versions for state, HTTP, WebSocket, routing, models, security, persistence, QR, and tests |
| completed | define Flutter architecture | plan defines feature-first folder structure, ASCP core client boundary, transport model, design-system layer, and route map |
| completed | define Flutter shadcn CLI workflow | plan requires `flutter_shadcn init`, dry-run-first installs, validation, audit, and dependency checks |
| completed | define TDD execution flow | plan requires failing tests first, widget/golden coverage, integration tests, docs, and tracker updates |
| completed | scaffold Flutter app | Flutter project exists under `apps/mobile`, runtime/dev dependencies resolve, bootstrap and token tests pass, and `flutter analyze` is clean |
| completed | initialize Flutter shadcn foundation | `flutter_shadcn init`, local registry fallback, dry-run, and app/card/button/badge installs completed; audit and deps pass |
| completed | resolve shadcn registry validation gap | local registry manifest now includes the missing markdown live preview dependency and `flutter_shadcn validate --json` passes |
| completed | build ASCP model foundation | exact ASCP method enums, JSON-RPC envelopes, errors, session statuses, event names, and extension-safe event parsing are implemented with tests |
| completed | build JSON-RPC transport foundation | HTTP and WebSocket JSON-RPC clients, protocol error mapping, event emission, and reconnect policy have focused tests |
| completed | build app shell and feature domain foundations | trusted/untrusted shell, route guard, home priority ordering, pairing state/parser, session ordering, approvals actionability, inspect ordering, settings revoke rule, and replay cursor persistence pass tests |
| completed | add pairing controller and widget flow | manual/QR scanner abstraction, claim/poll state, secure write gate, trusted/error widget states, and focused widget/domain tests pass |
| completed | add session controllers | in-memory session repository, session list ordering/filtering, detail timeline ordering, and send-input delegation tests pass |
| completed | add approval queue controller | queue ordering, non-actionable visibility, response delegation, and status update tests pass |
| completed | add ASCP and daemon-backed repository adapters | sessions, approvals, and inspect have ASCP JSON-RPC adapters; pairing and settings have loopback daemon REST adapters; focused adapter tests pass |
| completed | restore iOS simulator destination support | Runner supports both `iphoneos` and `iphonesimulator`; smoke coverage prevents regressing to physical-device-only builds; README documents the Xcode simulator runtime check |
| completed | add live session subscription adapter | WebSocket `sessions.subscribe` maps replay/live events into timeline events, filters by session id, and exposes `sessions.unsubscribe` cleanup |
| completed | add Drift-backed replay cursor persistence | replay cursors are stored in a generated Drift `replay_cursors` table with host/session primary key coverage and focused tests |
| completed | add offline metadata cache | Drift stores cached session summaries, artifact metadata, and diff metadata per host/session for reconnect recovery |
| completed | wire controller-backed feature screens | session list/detail, approval queue, inspect list, and settings device/diagnostics screens render controller state and delegate user actions |
| completed | add live integration and production hardening | default memory/live dependency containers wire ASCP, daemon, WebSocket, pairing, settings, and scanner boundaries; integration-style shell tests and golden smoke coverage pass |
| completed | add Riverpod provider graph | `mobileRuntimeConfigProvider` and `mobileDependenciesProvider` provide default DI with test overrides while preserving explicit constructor injection for focused widgets |
| completed | add production security adapters | live dependencies use Flutter secure storage for trust material and local_auth for local confirmation while memory dependencies remain deterministic for tests |
| completed | add dart-define live runtime config | default Riverpod runtime config can boot live mode from explicit build/run defines while incomplete live config falls back to deterministic memory mode |
| completed | expand trusted shell golden matrix | trusted approvals, inspect, and settings tab states have deterministic golden baselines in addition to first-run and sessions coverage |
| completed | harden platform capability config | Android and iOS platform shells declare the network, camera, biometric, Face ID, and app identity settings required by live pairing and trusted-device flows |
| completed | replace scaffold packaging metadata | pubspec, web metadata, and Android Gradle release comments identify Continuum explicitly and are guarded by smoke coverage |
| completed | fix simulator pairing continuation and live ASCP auth | first-run pairing Continue transitions into the trusted shell, stored trust material restores trusted startup state, live ASCP repositories use authenticated WebSocket JSON-RPC with paired device credentials, and simulator verification loads live sessions from the daemon |
| completed | add live session detail navigation and WebSocket feed rendering | sessions list opens a detail feed, subscribes through `sessions.subscribe`, renders user/agent/tool/approval/terminal-style rows from ASCP event payloads, sends protocol-valid `sessions.send_input`, and simulator verification shows bidirectional live events |
| completed | harden live inspect empty states | artifact/diff list calls degrade to an empty inspect state for unsupported or missing live metadata instead of showing a load failure |
| completed | align pairing and composer UI with HTML design system | first-run pairing card matches `component-pairing.html` state structure, removes nested card framing, improves manual code input styling, and updates the live session send composer with focus-aware field/button styling |
| completed | rebuild mobile screens from HTML design system | external OpenCode/Kiro/Blackbox routes were exercised with Codex as reviewer; Home, Sessions, session detail, Approvals, Inspect, and Settings were restyled toward the HTML references, duplicate shell headers were removed, approval empty-state counts were corrected, widget coverage was added, and simulator QA verified the trusted tab flow |
| completed | run live iOS simulator QA and produce evidence report | real daemon pairing, trusted-shell navigation, sessions, live WebSocket input, approvals, inspect, settings, adaptive dark UI, screenshot evidence, and PDF report are verified; stale pairing retry input bug is fixed with widget coverage |
| completed | align attached mobile screen designs | Agent Forge routes were used for review/implementation attempts with Codex as orchestrator and QA; the shell now exposes Home, Sessions, Approvals, Devices, and Settings; Home, Approvals, Settings, Trusted devices, and Pairing were rebuilt toward the attached screenshots; pairing uses the dark scanner/code-entry layout; tests and simulator screenshot verification pass |
| completed | compact pairing and chat screen parity | OpenCode/Qwen was used through Agent Forge for implementation guidance while Codex reviewed and merged; pairing is now a single-screen layout using Flutter shadcn `InputOTP`, manual pairing accepts six-digit code-only entry against the configured host, active session detail is restyled as a warm chat surface, QA HTML/PDF evidence was generated, and tests/shadcn/simulator checks pass |
| completed | run Agent Forge live QA and align pairing/chat live data | XcodeBuildMCP was exposed to OpenCode/Kiro/Claude/Blackbox config surfaces, iOS skills were copied into global agent skill folders, OpenCode audited live readiness, timeline rendering now preserves structured ASCP event payloads, the home dashboard no longer leaks demo session/host/health values into live mode, daemon pairing codes are six-digit numeric OTPs, and QA HTML/PDF evidence was generated |
| completed | run subagent live QA with iOS debugger access | Agent Forge routed live QA through OpenCode/Qwen and Kiro while Codex reviewed; OpenCode used its configured XcodeBuildMCP connection to run the daemon, generate a numeric pairing code, build/install/launch the live iOS simulator app, and capture screenshot evidence before stalling during report generation; Kiro produced a live-readiness audit; Blackbox failed to produce its requested report after two attempts; Codex consolidated the evidence into markdown/HTML/PDF QA reports |
| completed | remove stale settings/device demo data and run subagent simulator QA | AgentForge routed the stale-data implementation to Kiro and simulator QA to OpenCode/Kiro while Codex reviewed; settings/devices now render repository and diagnostics data instead of demo values, daemon diagnostics has a live endpoint, Flutter/daemon tests pass, iOS simulator QA captured seven screenshots, and a consolidated markdown/HTML/PDF QA report documents the remaining live RPC/chat blocker |

## Acceptance Criteria

This slice is done only when all of the following are true:

- `docs/superpowers/plans/2026-04-28-mobile-companion.md` is Flutter-first rather than React-first
- the plan explicitly selects Riverpod as the default state management layer and constrains BLoC use
- the plan includes current package choices for HTTP and WebSocket real-time communication
- the plan references Flutter shadcn CLI as the source of truth for registry UI components
- the plan maps `BUILD_ORDER.md` phases into Flutter design-system implementation order
- the plan requires TDD, widget tests, golden tests, integration tests, `flutter analyze`, and shadcn validation/audit/deps checks

## Next Likely Step

Mobile Flutter foundation is ready for the next backend-connected interaction slice. The latest pass removed stale settings/devices demo data, added daemon diagnostics, verified Flutter and daemon tests, and produced subagent simulator QA evidence. The next likely work is starting the daemon with a stable app-matching ASCP RPC/admin configuration, seeding or creating at least one active session, and rerunning simulator QA against the live chat/session path.
