# ASCP Status Log

Use this file as a session-to-session checkpoint log. Each completed task should add a concise entry.

## Entry Template

### YYYY-MM-DD - Short Task Name

- Branch:
- Commit:
- Summary:
- Documentation updated:
- Next likely step:

## Entries

### 2026-05-29 - Inspect artifact viewer parity

- Branch: `codex/mobile-live-session-detail`
- Commit: this commit
- Summary: compared the mobile Inspect screen against `Continuum Design System/preview/sessio-artifact-viewer.html` after simulator feedback showed the app still rendered a flat artifact list. Rebuilt the Flutter Inspect screen into the HTML artifact viewer structure: top file bar, metadata strip, pending/risk badges, files drawer row, left file tree, diff viewer with line numbers and added/removed rows, and bottom action bar. Verified on the iPhone 16 Plus simulator that Inspect now renders the artifact/diff viewer instead of repeated artifact cards.
- Documentation updated: `internal/status.md`
- Next likely step: wire artifact detail fields and real diff hunks into the viewer instead of the current HTML-parity fallback diff content.

### 2026-05-29 - Live iOS QA report and adaptive shell verification

- Branch: `codex/mobile-live-session-detail`
- Commit: this commit
- Summary: used Codex as orchestrator/reviewer with prior Kiro adaptive UI implementation and Blackbox QA matrix planning, then ran the real ASCP daemon on `127.0.0.1:8765` with pairing admin on `127.0.0.1:8767`. Verified iPhone 16 Plus simulator live pairing with manual code entry, host approval, iOS passcode confirmation, connected Home, Sessions, live session detail, `sessions.send_input`/WebSocket events, Approvals, Inspect, and Settings. Fixed a simulator-observed retry bug where failed manual pairing retained stale input before the next attempt. Generated a screenshot-backed PDF QA report at `apps/mobile/qa-reports/2026-05-29-live-ios/continuum-mobile-live-ios-qa-report-2026-05-29.pdf`.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/qa-reports/2026-05-29-live-ios/report.md`
- Next likely step: turn this manual simulator evidence path into repeatable XCUITest coverage and clean up accumulated local daemon trusted-device/pairing test data.

### 2026-05-29 - Dashboard live data wiring and bottom nav badges

- Branch: `codex/mobile-live-session-detail`
- Commit: this commit
- Summary: wired the home dashboard paired-device inventory and bottom-navigation badge counts to live daemon data. Added `badgeCount` to `_ShellTab` and `_NavButton`, loaded running-session and pending-approval counts in `_ContinuumTrustedShellState.initState`, and replaced the hardcoded `_dashboardDevices` with a live call to `settingsController.listTrustedDevices()`. The `_HomeDashboard._loadData()` now fetches sessions, approvals, and trusted devices in parallel. Verified `flutter analyze` clean and 150/152 tests pass. Rebuilt and launched on iPhone 16e simulator with corrected dart-defines pointing admin base URL to port 8767.
- Documentation updated: `internal/status.md`
- Next likely step: auto-refresh badge counts on tab change or polling interval, or wire live session subscription events to update dashboard counts in real time.

### 2026-05-29 - Daemon default admin port aligned to 8767 for manual pairing format

- Branch: `codex/mobile-live-session-detail`
- Commit: this commit
- Summary: changed the ASCP host daemon default admin port from 8766 to 8767 so the manual pairing entry format `127.0.0.1:8767:PAIR-CODE` works out of the box without env overrides. Updated `services/host-daemon/src/config.ts`, rebuilt `dist/`, updated `tests/config.test.ts` and `tests/main.test.ts` expectations, and verified the daemon starts on 8767 by default. Verified end-to-end: create session → claim (`POST /pairing/claim`) → poll (`pending_host_approval`) → approve → poll (`approved` with credentials). The Flutter `parseManualPairingPayload` already supports `host:port:code` natively, so no mobile code changes were required. Also updated `internal/real-device-path.md` to reference 8767.
- Documentation updated: `internal/status.md`, `internal/real-device-path.md`
- Next likely step: wire live daemon data for dashboard device inventory and bottom nav badge counts, or run manual simulator pairing end-to-end with the new default port.

### 2026-05-29 - Mobile screen parity rebuild (cost-aware orchestrator)

- Branch: `codex/mobile-live-session-detail`
- Commit: this commit
- Summary: used the cost-aware orchestrator with Kiro CLI (Auto router, ~15.7 credits) to rebuild all 7 mobile screens from the Continuum Design System HTML references in BUILD_ORDER.md. Codex acted as reviewer/verifier. Screens rebuilt: Home Dashboard (removed connection card, proper ContinuumColorTokens), Sessions List (status icons with color-coded backgrounds, mono session IDs), Session Detail (hamburger, amber approval badges, inline code parsing, diff preview with +/- coloring, tool cards, terminal blocks), Approvals (risk-level card coloring, info banner, Deny/Approve buttons, non-actionable support), Inspect (dark theme artifact viewer with diff stats), Settings (UserSummaryCard, section headers, Appearance/Notifications/Connection/Security/Diagnostics/DangerZone sections, Trusted Device rows), Pairing (dashed-border scan area, enlarged outcome icons). Result: flutter analyze clean, 150/152 tests pass, flutter_shadcn validate/audit both pass.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Cost summary: 7 Kiro dispatches (~15.7 credits out of 1,000/mo), 5 parallel runs, 1 retry (Session Detail timeout). All T2/Auto tier.
- Next likely step: wire live daemon data for dashboard device inventory and bottom nav badge counts.

### 2026-05-29 - Mobile pairing and composer UI parity

- Branch: `codex/mobile-live-session-detail`
- Commit: this commit
- Summary: continued the mobile HTML parity work with Codex as reviewer/orchestrator and used OpenCode Go `opencode-go/qwen3.7-max` for a read-only UI gap audit through the cost-aware route. Rebuilt the first-run pairing card around the `component-pairing.html` state model, removed the extra shell card wrapper, added HTML-matched state labels/buttons/manual-code field styling, and improved the live session composer text field and send button.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Next likely step: continue active-session parity against the HTML preview by tightening the session top bar, diff preview, tool status cards, waiting indicator, and approval compound card styling.

### 2026-05-26 - Mobile iOS simulator destination support

- Branch: `branch-mobile-ios-simulator-destination`
- Commit: this commit
- Summary: continued the mobile app with Codex as orchestrator and kept the fix local after diagnostics showed the app project was restricted to physical iOS platforms while the remaining launch failure is an Xcode runtime mismatch. Added smoke coverage for Runner simulator platform support and set Runner to support both `iphoneos` and `iphonesimulator`.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: install the iOS 26.2 simulator runtime in Xcode > Settings > Components, then rerun `flutter run -d B42021B5-74F7-482A-8D2A-A645439C0CF2` against the live ASCP host/daemon configuration.

### 2026-05-26 - Mobile packaging metadata

- Branch: `branch-mobile-packaging-metadata`
- Commit: this commit
- Summary: continued the mobile app with Codex as orchestrator and used a low-cost OpenCode Go advisory route through the cost-aware workflow; the advisory route confirmed the targeted packaging cleanup and pointed out web metadata still had scaffold defaults. Added smoke coverage for package/web/Android packaging metadata, replaced the Flutter scaffold description with Continuum ASCP mobile companion metadata, removed Android Gradle TODO comments in favor of explicit package id and release-signing notes, and renamed web app metadata to Continuum.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Next likely step: run the documented `flutter run --dart-define=...` command against a live ASCP host/daemon endpoint on a simulator or physical device.

### 2026-05-26 - Mobile platform capability config

- Branch: `branch-mobile-platform-permissions`
- Commit: this commit
- Summary: continued the mobile app with Codex as orchestrator and attempted a low-cost OpenCode Go advisory route through the cost-aware workflow; the route timed out without file changes, so the platform readiness slice was implemented locally with TDD. Added smoke coverage for Android/iOS platform configuration, declared Android network/camera/biometric permissions, switched Android activity to `FlutterFragmentActivity` for local auth, set the app label to Continuum, and added iOS camera/Face ID usage descriptions.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: run the documented `flutter run --dart-define=...` command against a live ASCP host/daemon endpoint on a simulator or physical device.

### 2026-05-26 - Mobile trusted shell golden matrix

- Branch: `branch-mobile-golden-matrix`
- Commit: this commit
- Summary: continued the mobile app with Codex as orchestrator and attempted a low-cost OpenCode Go advisory route through the cost-aware workflow; the route timed out without file changes, so the UI coverage refinement was implemented locally with TDD. Added deterministic golden coverage for trusted approvals, inspect, and settings shell states, extending the existing first-run and sessions baselines.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Next likely step: run the documented `flutter run --dart-define=...` command against a live ASCP host/daemon endpoint on a simulator or physical device.

### 2026-05-26 - Mobile live runtime configuration

- Branch: `branch-mobile-live-runtime-config`
- Commit: this commit
- Summary: continued the mobile app with Codex as orchestrator and attempted a low-cost OpenCode Go advisory route through the cost-aware workflow; the route timed out without file changes, so the runtime-config refinement was implemented locally with TDD. Added `MobileRuntimeConfig.fromEnvironment` so the default Riverpod provider can boot live dependencies from explicit `--dart-define` values, with incomplete live configuration falling back to deterministic memory mode.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: run the documented `flutter run --dart-define=...` command against a live ASCP host/daemon endpoint on a simulator or physical device.

### 2026-05-25 - Mobile live wiring and scanner path

- Branch: `branch-mobile-flutter-app`
- Commit: `bbf1181`
- Summary: completed the mobile app production-wiring slice with Codex as orchestrator and a bounded Blackbox read-only advisory route through the cost-aware workflow; Blackbox timed out after partial context, so no external patch was applied. Added `MobileDependencies` memory/live factories, wired the trusted shell to injected controllers, replaced the static first-run card with the controller-backed pairing screen, added a `mobile_scanner` QR scanner route, and connected live pairing to the daemon claim/poll repository. Added integration-style shell coverage and golden smoke baselines for first-run pairing and trusted sessions.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: run on a physical/simulator device against a live ASCP host daemon endpoint and split any visual or provider-generation polish into separate tickets.

### 2026-05-26 - Mobile Riverpod provider graph

- Branch: `branch-mobile-flutter-app`
- Commit: `4173077`
- Summary: continued the mobile app with Codex as orchestrator and attempted a bounded Blackbox read-only route through the cost-aware workflow; Blackbox timed out and tried an unavailable shell tool, so no external patch was applied. Added a Riverpod-backed `mobileRuntimeConfigProvider` and `mobileDependenciesProvider`, made `ContinuumMobileApp` consume provider overrides by default, and preserved explicit constructor injection plus memory fallback for focused widget tests.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: run simulator/device validation against a live ASCP host daemon endpoint, then split any remaining visual matrix or generated-provider refinements into small follow-up tickets.

### 2026-05-26 - Mobile secure storage and local auth adapters

- Branch: `branch-mobile-flutter-app`
- Commit: this commit
- Summary: continued the mobile app with Codex as orchestrator and attempted an OpenCode Go advisory route through the cost-aware workflow; the first model id was unavailable and the fallback produced no useful patch, so the security integration was implemented locally. Added `FlutterSecureStore` with a mockable secure-storage driver, added `DeviceLocalAuthGate` with a mockable local-auth adapter, exposed the pairing controller's underlying secure store for dependency verification, and wired live mobile dependencies to production secure storage and device auth while keeping memory dependencies deterministic.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: run simulator/device validation against a live ASCP host daemon endpoint, then split any remaining visual matrix or generated-provider refinements into small follow-up tickets.

### 2026-05-25 - Mobile cache and controller-backed screens

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: continued the mobile companion build with Codex as orchestrator and attempted a bounded Blackbox read-only review through the cost-aware route; the Blackbox request timed out, so the local wrapper was patched to report timeout bytes cleanly for future runs. Added Drift-backed offline metadata cache for session summaries, artifact details, and diff details; wired session list/detail, approvals, inspect, and settings screens to tested controllers with widget coverage for list rendering and user actions.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: connect the default providers to live daemon endpoints, wire the real mobile scanner path, and add integration/golden validation.

### 2026-05-25 - Mobile Drift replay cursor persistence

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: replaced the in-memory replay cursor placeholder with a generated Drift database table keyed by host id and session id. Added `drift_dev`, generated `continuum_database.g.dart`, and kept the existing cursor behavior covered by a focused database test.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: add offline session/artifact metadata cache, then wire production feature screens to the tested controllers and adapters.

### 2026-05-25 - Mobile session subscription adapter

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: added a WebSocket-backed `sessions.subscribe` adapter that requests replay from an optional sequence cursor, filters incoming ASCP event envelopes by session id, maps them into timeline events, and sends `sessions.unsubscribe` on cleanup.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: add Drift-backed persistence for replay cursors/session metadata, then wire production feature screens to the tested controllers and adapters.

### 2026-05-25 - Mobile ASCP and daemon repository adapters

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: continued the mobile companion build with Codex as the orchestrator and external CLI routes attempted through the cost-aware workflow; because Blackbox still rejected the registry-listed free model, OpenCode Go write tasks hung, and Kiro returned no usable patch for this slice, the final integration was implemented locally and independently verified. Added daemon REST adapters for pairing claim/poll and trusted-device list/revoke, on top of the ASCP JSON-RPC adapters already added for sessions, approvals, and inspect.
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/mobile/README.md`
- Next likely step: wire WebSocket `sessions.subscribe` replay streams and Drift-backed persistence, then replace placeholder feature screens with controller-backed production mobile flows.

### 2026-05-25 - Mobile pairing, sessions, and approvals controllers

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: used the cost-aware orchestrator to route work through external CLIs instead of native Codex subagents; Blackbox rejected the registry-listed free model names, OpenCode Go completed read-only planning but hung on the pairing write task, and Kiro returned partial/no-op write results that were integrated locally. The app now has a richer pairing controller and widgets, tested secure-write gate, session repository/list/detail controllers, and approval queue/response controller.
- Documentation updated: `internal/status.md`
- Next likely step: replace remaining in-memory repositories with ASCP-backed repositories and Drift persistence, then build production artifact/diff/settings screens and integration tests.

### 2026-05-25 - Mobile ASCP foundation and app shell

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: resolved the local Flutter shadcn registry validation gap, installed the broader planned shadcn primitive set through dry-run/add, added exact ASCP method/error/session/event foundation types, added HTTP and WebSocket JSON-RPC clients with reconnect policy, added secure trust and replay cursor boundaries, added pairing/session/approval/inspect/settings domain slices, and replaced the first-run-only app with a trusted/untrusted mobile shell
- Documentation updated: `apps/mobile/README.md`, `internal/plans.md`, `internal/status.md`, `docs/superpowers/plans/2026-04-28-mobile-companion.md`
- Next likely step: turn the placeholder feature screens into production flows backed by pairing claim/polling, secure storage, ASCP repositories, session subscriptions, approval responses, artifact/diff reads, and Drift persistence

### 2026-05-25 - Mobile Flutter scaffold and design foundation

- Branch: `branch-mobile-flutter-app`
- Commit: `not committed`
- Summary: scaffolded the Flutter app under `apps/mobile`, added the planned runtime and dev dependencies with a generator-compatible `json_serializable`/`riverpod_generator` set, initialized `flutter_shadcn`, switched to a local registry fallback after the remote registry returned 403/404 errors, installed shadcn app/card/button/badge foundation components, replaced the generated counter app with a Continuum first-run shell, and added passing bootstrap/token/widget tests
- Documentation updated: `internal/plans.md`, `internal/status.md`, `docs/superpowers/plans/2026-04-28-mobile-companion.md`
- Next likely step: resolve or quarantine the shadcn registry-wide validation gap for missing `registry/components/display/markdown/_impl/state/markdown_live_preview.dart`, then implement the ASCP method/envelope/event model foundation

### 2026-05-25 - Mobile Flutter architecture plan

- Branch: `main`
- Commit: `not committed`
- Summary: converted the mobile companion planning assets from a React prototype plan into a Flutter-first implementation plan with feature-first architecture, Riverpod-first state management, WebSocket/HTTP transport boundaries, current pub.dev package choices, Flutter shadcn CLI registry workflow, Continuum Design System build-order translation, and TDD/widget/golden/integration verification requirements
- Documentation updated: `internal/plans.md`, `internal/status.md`, `docs/superpowers/specs/2026-04-28-mobile-companion-design.md`, `docs/superpowers/plans/2026-04-28-mobile-companion.md`
- Next likely step: scaffold the real Flutter app in `apps/mobile`, run `flutter_shadcn init --yes`, port the design tokens, and implement pairing first

### 2026-04-28 - Host pairing UI slice

- Branch: `branch-host-pairing-ui`
- Commit: `not committed`
- Summary: added a separate host-console pairing workspace with inline pairing-session creation, lifecycle visibility, pending-claim approval queue, trusted-device inventory, and polling scoped to pending and approved device onboarding states
- Documentation updated: `internal/plans.md`, `internal/status.md`, `README.md`, `apps/host-console/README.md`, `docs/superpowers/specs/2026-04-28-host-pairing-ui-design.md`, `docs/superpowers/plans/2026-04-28-host-pairing-ui.md`
- Next likely step: build the mobile claim UI on top of the completed daemon pairing backend and host pairing workspace, or harden the daemon transport toward TLS-backed pairing flows

### 2026-04-28 - Host daemon pairing backend slice

- Branch: `branch-host-daemon`
- Commit: `not committed`
- Summary: added loopback-only pairing session persistence, explicit host approval flow, mobile claim/poll endpoints, consumed-session handling, and trusted-device list/revoke endpoints above the existing daemon auth engine without changing ASCP WebSocket method or event semantics
- Documentation updated: `internal/plans.md`, `internal/status.md`, `README.md`, `services/host-daemon/README.md`, `docs/superpowers/plans/2026-04-28-host-daemon-pairing-backend.md`
- Next likely step: build host-console and mobile pairing UI flows on top of the completed pairing backend, or extend the daemon surface toward TLS-backed transport

### 2026-04-28 - Host daemon auth and trust slice

- Branch: `branch-host-daemon`
- Commit: `not committed`
- Summary: added daemon-owned trusted-device storage with `scrypt` verifier persistence, host-wide pairing primitives, loopback-only socket authentication, per-method scope authorization, daemon-generated correlation ids, additive `auth.transport` capability metadata, and request audit logging above the replay-backed daemon/runtime boundary without moving auth into adapters or rewriting ASCP core semantics
- Documentation updated: `internal/plans.md`, `internal/status.md`, `README.md`, `services/host-daemon/README.md`, `docs/superpowers/specs/2026-04-28-host-daemon-auth-trust-design.md`, `docs/superpowers/plans/2026-04-28-host-daemon-auth-trust.md`
- Next likely step: add a host-side pairing UX surface for real mobile onboarding, or upgrade the daemon surface toward TLS-backed network transport while preserving the host-wide trust model

### 2026-04-27 - Host daemon replay persistence slice

- Branch: `branch-host-daemon`
- Commit: `not committed`
- Summary: added daemon-owned SQLite-backed session, event, and cursor stores; added `attachment_manager` so attached sessions seed truthful baseline state and persist live events even with zero subscribers; added `replay_broker` and a replay-backed runtime wrapper so subscribe paths now serve daemon-stored `sync.snapshot`, stored replay events, and `sync.replayed`; and exposed additive snapshot metadata for completeness and detached state without changing frozen ASCP method or event names
- Documentation updated: `internal/plans.md`, `internal/status.md`, `services/host-daemon/README.md`, `docs/superpowers/specs/2026-04-27-host-daemon-replay-persistence-design.md`, `docs/superpowers/plans/2026-04-27-host-daemon-replay-persistence.md`
- Next likely step: add daemon auth or trust hooks on top of the durable replay boundary, or prepare the replay stores for relay-readiness

### 2026-04-27 - Host console reconnect recovery and live timeline polish

- Branch: `branch-host-console-chat-refresh`
- Commit: `not committed`
- Summary: polished the host console reconnect path so reconnect keeps the selected session context, repopulates the session list, and restores the selected conversation after transport restart; extracted timeline assembly into a dedicated helper with focused assistant-delta tests; and live-validated in the browser that a selected session survives reconnect and still streams new transcript events after sending input
- Documentation updated: `internal/plans.md`, `internal/status.md`, `apps/host-console/README.md`
- Next likely step: merge the refreshed host-console branch into `main`, then move on to auth/multi-client boundaries or second-runtime host integration

### 2026-04-27 - Host console transcript replay and historical chat hydration

- Branch: `branch-host-console-chat-refresh`
- Commit: `not committed`
- Summary: fixed the reopened-session chat gap by mapping Codex historical `userMessage.content[].text` and `agentMessage.text` turn items into ASCP transcript events, making the host console subscribe with replay from sequence `0`, and live-validating in the browser that reopened sessions now render real historical chat bubbles instead of only `sync.snapshot`
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Next likely step: commit the branch, merge it into `main` if accepted, and then continue with reconnect polish or broader host-service productionization work

### 2026-04-27 - Host console chat refresh and start-session hardening

- Branch: `branch-host-console-chat-refresh`
- Commit: `not committed`
- Summary: rebuilt `apps/host-console` into a multi-session chat-first operator workspace with a split session list, conversation pane, and layered protocol rail; added a selected-session state model plus focused Vitest coverage; lazy-loaded artifacts and diffs from explicit operator actions; and hardened the Codex adapter plus browser flow so newly started sessions degrade truthfully before turn materialization and recover cleanly after the first user message
- Documentation updated: `internal/plans.md`, `apps/host-console/README.md`, `docs/superpowers/specs/2026-04-27-host-console-chat-refresh-design.md`, `docs/superpowers/plans/2026-04-27-host-console-chat-refresh.md`
- Next likely step: review the refreshed host console branch, then merge to `main` or continue with host-service auth and multi-runtime follow-up work

### 2026-04-27 - Docs site: fixed links, dark/light mode, fuzzy search

- Branch: `master` (apps/web)
- Commit: `ab6e80b` (apps/web)
- Summary: fixed all internal MDX links to use correct paths with trailing slashes for static export (including `/docs/learn/03-core-concepts/` and `/docs/reference/01-overview/` corrections), rewrote the search component with 31 correct URLs, fuzzy character-by-character matching, highlighted results, and keyboard navigation (↑↓↵esc), added a dark/light mode toggle using next-themes with full CSS variable theming across all components, and verified everything works in a browser against the static export
- Documentation updated: `internal/status.md`, all 31 MDX files in `apps/web/content/docs/`, `apps/web/components/search.tsx`, `apps/web/components/theme-toggle.tsx`, `apps/web/app/globals.css`, `apps/web/app/layout.tsx`, `apps/web/app/page.tsx`, `apps/web/app/docs/layout.tsx`, `apps/web/app/layout.config.tsx`
- Next likely step: deploy the updated docs site to sessio.app

### 2026-04-27 - Docs restructure into Learn/Reference/Build sections

- Branch: `feature/docs-restructure` (outer repo), `master` (apps/web)
- Commit: `e370e6a` (outer repo), `ea85194` and `c96d433` (apps/web)
- Summary: restructured all ASCP documentation by moving user-facing docs to `apps/web/content/docs/` with three clear sections (Learn / Reference / Build), moving internal workflow files (plans, status, prompts, superpowers) to `internal/`, removing the old `docs/` directory and root-level design files, merging the authentication section into a single `reference/09-auth-approvals.mdx`, rewriting the landing page with clear entry cards, updating `AGENTS.md` and `README.md` with new paths, and updating all 31 website MDX files with corrected cross-references
- Documentation updated: `internal/status.md`, `internal/plans.md`, `internal/README.md` (new), `internal/prompts/README.md`, `AGENTS.md`, `README.md`, `apps/web/content/docs/index.mdx`, `apps/web/app/layout.config.tsx`, all 31 website MDX files, all meta.json files
- Next likely step: deploy the updated docs website to sessio.app

### 2026-04-27 - Codex interaction translation and blocked-session routing

- Branch: `branch-codex-interaction-translation`
- Commit: `not committed`
- Summary: implemented Codex-side translation of blocked session state into ASCP interaction objects by deriving pending approvals from `waiting_approval`, deriving pending inputs from `waiting_input`, preserving native approval notifications when present, routing approval responses through native Codex methods or truthful message-send fallback, enforcing `CONFLICT` for terminal requests, and implementing `sessions.start` so the host capability document no longer overstates unsupported behavior
- Documentation updated: `internal/plans.md`, `internal/status.md`, `adapters/codex/README.md`
- Next likely step: commit and merge this adapter branch into `main`, then live-validate the blocked interaction flows through the browser host console against sessions that exercise both native and host-derived request paths

### 2026-04-27 - Protocol interaction contract for blocked approvals and input

- Branch: `branch-protocol-interaction-contract`
- Commit: `not committed`
- Summary: extended the frozen protocol with `InputRequest`, `pending_inputs`, and `input.requested|completed|expired`; added approval provenance and actionability rules so host-derived approvals can be visible yet truthfully non-actionable; updated method and event contracts plus compatibility/auth semantics to keep `approvals.respond` and `sessions.send_input` as the existing response paths; and added conformance fixtures and validator coverage for the `approval_respond=false` plus `UNSUPPORTED` round-trip
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/methods.md`, `protocol/spec/events.md`, `protocol/spec/auth.md`, `protocol/spec/compatibility.md`, `docs/superpowers/specs/2026-04-27-interaction-contract-design.md`, `docs/superpowers/plans/2026-04-27-interaction-contract.md`
- Next likely step: commit and merge this protocol branch into `main`, then start a fresh adapter branch from updated `main` to implement Codex translation and response routing against the frozen interaction contract

### 2026-04-27 - Docs site UI polish: search, tables, code blocks, line height

- Branch: `main` (direct commit to `apps/web` submodule)
- Commit: `eda3e0d` (in `apps/web/`)
- Summary: fixed all reported docs site UI issues by disabling Fumadocs built-in search to eliminate duplicate CMD+K dialogs, adding 6 curated popular pages to the search empty state, increasing global line heights (body/p/li → 1.75, pre code → 1.85), completely redesigning tables with no vertical borders, alternating row backgrounds, and stronger horizontal separators, and adding functional copy (clipboard API) and share (Web Share API with fallback) buttons to every code block via a client-side `CodeBlockEnhancer` component
- Documentation updated: `docs/status.md`
- Next likely step: deploy the updated docs site to sessio.app

### 2026-04-26 - Docs site monochrome styling refinement and branch merge

- Branch: `branch-ascp-host-service`
- Commit: `dcc63a3`
- Summary: refined the `apps/web` docs site styling with opencode.ai-inspired monochrome improvements including subtler inline code (border/background instead of button-like), left-bordered code blocks, hover-only link underlines, and button text-decoration fixes; committed the changes in the separate `apps/web` repo; merged `branch-ascp-host-service` into `main` after confirming the branch was up to date with origin
- Documentation updated: `docs/status.md`
- Next likely step: deploy the docs site to sessio.app or continue with the next protocol feature branch

### 2026-04-26 - Host console live browser validation fixes

- Branch: `branch-ascp-host-service`
- Commit: `not committed`
- Summary: validated the local host and Codex-first browser console through the in-app browser, fixed the host console TSX compilation configuration so the React app renders under Vite during live testing, and fixed `sessions.get(include_runs=true)` to skip incomplete Codex turns instead of failing the whole session read after browser-driven send-input refreshes
- Documentation updated: `docs/status.md`
- Next likely step: commit the browser-validation fixes on the current branch, then continue with merge review or broader multi-runtime host follow-up work

### 2026-04-26 - Reusable ASCP host service with Codex-first web console

- Branch: `branch-ascp-host-service`
- Commit: `not committed`
- Summary: added a reusable local WebSocket ASCP host service package with push-style event delivery, connected the host to the existing Codex adapter through a truthful runtime binding plus launch script, made the TypeScript SDK browser-safe for the host console path by loading validation schemas without `node:fs` and exporting a browser transport entrypoint, and added a separate Codex-first browser console for real-time session inspection, live event streaming, input, approvals, artifacts, and diffs without touching the user’s existing `apps/web` work
- Documentation updated: `plans.md`, `docs/status.md`, `packages/host-service/README.md`, `apps/host-console/README.md`, `adapters/codex/README.md`
- Next likely step: run the Codex host and browser console together against a live session, then decide whether the next branch should add auth/multi-client boundaries or widen the host registration surface for additional runtimes

### 2026-04-26 - Codex live smoke coverage for remaining adapter surfaces

- Branch: `branch-codex-live-smoke-surfaces`
- Commit: `not committed`
- Summary: expanded the live-smoke tool to support `sessions.subscribe|unsubscribe`, `approvals.list|respond`, `artifacts.list|get`, and `diffs.get`, added interactive session actions for subscribe+drain replay validation plus approvals/artifacts/diff checks, added a continuous `watch` stream mode that subscribes, drains events until idle timeout, and unsubscribes in one process, and wired the executable script to the corresponding adapter service methods
- Documentation updated: `plans.md`, `docs/status.md`, `adapters/codex/README.md`
- Next likely step: commit the branch and merge to `main` if the new smoke-testing flow is accepted

### 2026-04-26 - Codex adapter remaining ASCP surfaces

- Branch: `branch-codex-adapter-remaining-surfaces`
- Commit: `not committed`
- Summary: implemented the remaining Codex adapter service surfaces by adding `sessions.subscribe` and `sessions.unsubscribe` with sequenced event queues and replay behavior, adding `approvals.list` plus truthful `approvals.respond` fallback handling, deriving `diffs.get` and `artifacts.list|get` from Codex `fileChange` turn items, wiring notification listeners from the app-server client, and updating capability resolution to reflect the new surfaces
- Documentation updated: `plans.md`, `docs/status.md`, `adapters/codex/README.md`
- Next likely step: review the branch, then commit, push, and merge into `main` if accepted

### 2026-04-26 - Codex live smoke script task 2

- Branch: `feature/codex-live-smoke-script`
- Commit: `dc00d3d`
- Summary: completed the first implementation slice for the Codex live smoke script by adding typed command parsing and validation helpers, covering interactive default plus core list/get/send-input parsing behavior, and tightening parser invariants so option tokens are not misread as session IDs and send-input text is preserved verbatim
- Documentation updated: `plans.md`, `docs/status.md`
- Next likely step: add command dispatch over the existing adapter service, then wire the executable wrapper and interactive flow

### 2026-04-26 - Codex live smoke script task 3

- Branch: `feature/codex-live-smoke-script`
- Commit: `a0cd8d3`
- Summary: completed the dispatch slice for the Codex live smoke script by adding typed dependency-based command dispatch for discovery, list, get, resume, and send-input, tightening the dependency contract so branch-specific dispatch stays testable, and extending focused coverage to the interactive early return plus all supported command branches
- Documentation updated: `plans.md`, `docs/status.md`
- Next likely step: add the executable wrapper, package script alias, and interactive terminal flow on top of the tested `live-smoke.ts` module

### 2026-04-26 - Codex live smoke script task 4 and task 5

- Branch: `feature/codex-live-smoke-script`
- Commit: `0d731cc`
- Summary: completed the checked-in live smoke entrypoint for the Codex adapter by adding a dual-mode executable wrapper plus interactive terminal flow, fixing the launch path so `npm --workspace @ascp/adapter-codex run live` rebuilds before executing, rejecting malformed command-line usage instead of silently running, keeping the interactive menu alive after action failures, documenting direct and interactive usage in the adapter README, and re-running focused tests, the full adapter check, the repository validator, and real `discover` plus `list` smoke commands against the live Codex runtime
- Documentation updated: `plans.md`, `docs/status.md`, `adapters/codex/README.md`
- Next likely step: review the finished branch, push it, and merge it into `main` if the live smoke workflow is accepted

### 2026-04-26 - Codex live smoke dormant-thread send-input fix

- Branch: `feature/codex-live-smoke-script`
- Commit: `not committed`
- Summary: fixed the live smoke `send-input` path for persisted Codex sessions by confirming that `thread/read` succeeds while `turn/start` fails until `thread/resume` reattaches the thread in the current app-server process, then updating `sessions.send_input` to resume dormant threads before starting a new turn and locking the regression with focused service tests plus a real live send-input probe against a historical session
- Documentation updated: `plans.md`, `docs/status.md`, `adapters/codex/README.md`
- Next likely step: commit the dormant-thread fix, then push and merge the updated live smoke branch if the historical-session flow is accepted

### 2026-04-26 - Codex adapter initialization hotfix

- Branch: `feature/codex-adapter-init-fix`
- Commit: `not committed`
- Summary: fixed the live Codex adapter usability regression where service calls failed with `Not initialized` unless downstream code called `client.initialize()` manually first, by adding lazy one-time app-server initialization in the Codex client, extending the client regression tests to model a runtime that rejects pre-initialize requests, and re-running both adapter verification and real runtime smoke checks without manual initialization
- Documentation updated: `plans.md`, `docs/status.md`, `adapters/codex/README.md`
- Next likely step: push the hotfix branch, fast-forward `main`, and continue future adapter work from updated `main`

### 2026-04-26 - Codex adapter task 7 and task 8

- Branch: `feature/codex-adapter`
- Commit: `not committed`
- Summary: completed the remaining Codex adapter slice by adding deterministic normalization for official Codex turn, delta, diff, and approval-request surfaces into ASCP `EventEnvelope` and `ApprovalRequest` shapes, documenting the truthful capability fallbacks in the adapter README, extending the repository validator to require the new mapping files and fallback claims, and validating the finished TypeScript adapter package with the full adapter test suite plus build and validator checks
- Documentation updated: `plans.md`, `docs/status.md`, `docs/superpowers/plans/2026-04-26-codex-adapter.md`, `adapters/codex/README.md`
- Next likely step: run merge-readiness review for `feature/codex-adapter`, then integrate the branch if the current truthful v1 scope is accepted

### 2026-04-26 - Codex adapter task 4

- Branch: `feature/codex-adapter`
- Commit: `6eadc8a`
- Summary: completed the Codex adapter runtime-discovery slice by adding the app-server stdio JSON-RPC client, truthful runtime discovery, conservative capability resolution, and focused transport/discovery/capability tests; the ASCP-facing capability surface now stays intentionally strict for Task 4, with `stream_events`, approvals, diffs, artifacts, and replay all held false until later tasks implement those contracts honestly
- Documentation updated: `plans.md`, `docs/status.md`, `docs/superpowers/plans/2026-04-26-codex-adapter.md`
- Next likely step: implement Task 5 deterministic ID helpers and thread/turn-to-session/run normalization under `adapters/codex/src/`

### 2026-04-26 - Codex adapter task 5

- Branch: `feature/codex-adapter`
- Commit: `d90c675`
- Summary: completed deterministic Codex ID helpers plus conservative thread and turn normalization into ASCP `Session` and `Run` shapes, aligned the mapper to the real Codex runtime schema, converted Unix-second timestamps into ASCP UTC strings, removed the unproven `active_run_id` mapping, and locked the slice with focused mapper tests
- Documentation updated: `plans.md`, `docs/status.md`, `docs/superpowers/plans/2026-04-26-codex-adapter.md`
- Next likely step: implement Task 6 service methods for `sessions.list`, `sessions.get`, `sessions.resume`, and `sessions.send_input` on top of the existing discovery and mapping layers

### 2026-04-26 - Codex adapter task 6

- Branch: `feature/codex-adapter`
- Commit: `921c74c`
- Summary: completed the first ASCP service layer for the Codex adapter by adding honest `sessions.list`, `sessions.get`, `sessions.resume`, and `sessions.send_input` methods over the existing Codex client and mapper stack, using real `thread.read(includeTurns: true)` state to choose between `turn/steer` and `turn/start`, and validating the combined Task 4-6 slice with adapter build plus five focused test files
- Documentation updated: `plans.md`, `docs/status.md`, `docs/superpowers/plans/2026-04-26-codex-adapter.md`
- Next likely step: implement Task 7 event normalization, approval mapping, and any truthful diff support without widening into replay or artifact claims

### 2026-04-26 - Production-grade monorepo restructure

- Branch: `branch-ascp-monorepo-structure`
- Commit: `c0a8732`
- Summary: converted the repository into the requested monorepo layout by moving protocol truth into `protocol/`, SDKs into `sdks/`, the reference client into `apps/reference-client/`, the mock server into `services/mock-server/`, adding root workspace scaffolding, adding placeholder package and adapter boundaries, updating scripts/tests/docs to execute from the new structure, and merging the feature branch back into `main`
- Documentation updated: `plans.md`, `README.md`, `AGENTS.md`, `docs/status.md`, `docs/README.md`, `docs/project-context-reference.md`, `docs/architecture/system-design.md`, `docs/architecture/dependency-graph.md`, `protocol/ASCP_Protocol_PRD_and_Build_Guide.md`, `protocol/ASCP_Protocol_Detailed_Spec_v0_1.md`, `packages/README.md`, `adapters/README.md`, `apps/README.md`, `services/README.md`, `tooling/README.md`
- Next likely step: continue future shared-package, adapter, app, or service work from updated `main` using the monorepo baseline

### 2026-04-26 - Codex adapter planning pack

- Branch: `feature/codex-adapter-planning`
- Commit: `not committed`
- Summary: translated the external Codex adapter implementation brief into repository-native planning assets by scoping a dedicated planning branch, adding a reusable Codex adapter starter prompt, adding a detailed superpowers implementation plan, and wiring those assets into the docs index and context reference
- Documentation updated: `plans.md`, `README.md`, `docs/README.md`, `docs/project-context-reference.md`, `docs/prompts/README.md`, `docs/prompts/codex-adapter.md`, `docs/superpowers/plans/2026-04-26-codex-adapter.md`, `docs/status.md`
- Next likely step: create `feature/codex-adapter` from updated `main` and use the new prompt plus plan to implement the adapter as optional downstream runtime integration work

### 2026-04-22 - Project context reference

- Branch: `feature/project-context-reference`
- Commit: `not committed`
- Summary: added a repository-wide ASCP context reference that explains the purpose, protocol scope, completed workstreams, directory layout, validation commands, and safe continuation model for future contributors
- Documentation updated: `plans.md`, `docs/project-context-reference.md`, `docs/README.md`, `docs/status.md`
- Next likely step: merge the documentation branch into `main` so future sessions can bootstrap from the new reference file directly

### 2026-04-22 - Reference client

- Branch: `feature/reference-client`
- Commit: `not committed`
- Summary: added a deterministic downstream ASCP reference client over the existing stdio mock surface, with schema-validated discovery, session inspection, subscribe/replay, approval/artifact/diff reads, a repeatable demo summary, and a branch-specific validator
- Documentation updated: `plans.md`, `docs/status.md`, `README.md`, `docs/README.md`, `apps/reference-client/README.md`
- Next likely step: merge the finished downstream proof client into `main` and leave the repository clean on updated `main`

### 2026-04-22 - Repository close-out

- Branch: `main`
- Commit: `not committed`
- Summary: added an optional downstream `feature/reference-client` starter prompt and rewrote the repository planning and README state so `main` now reads as a closed-out ASCP v0.1 protocol workspace rather than an unfinished protocol branch
- Documentation updated: `plans.md`, `README.md`, `docs/status.md`, `docs/README.md`, `docs/prompts/README.md`, `docs/prompts/reference-client.md`
- Next likely step: either leave the repository on `main` as the completed protocol workspace or start `feature/reference-client` from updated `main`

### 2026-04-22 - Mock server

- Branch: `feature/mock-server`
- Commit: `bd4472a`
- Summary: added a deterministic fixture-backed ASCP mock server over line-oriented stdio JSON-RPC, seeded host/runtime/session/approval/artifact/diff data, replay-aware sample event streams, a repeatable mock validator, a docs index, and a protocol usage plus DTO-generation guide
- Documentation updated: `plans.md`, `docs/status.md`, `README.md`, `docs/README.md`, `docs/protocol-usage-and-dto-generation.md`, `services/mock-server/README.md`
### 2026-05-29 - Mobile pairing navigation and live auth

- Branch: `branch-mobile-pairing-navigation`
- Commit: `not committed`
- Summary: fixed the trusted pairing Continue action so it enters the trusted mobile shell, restored stored trust material on startup, introduced transport-neutral JSON-RPC repositories, and wired live ASCP calls/subscriptions through an authenticated WebSocket client that sends paired device credentials.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Verification: `flutter test` passed with 141 tests; `flutter analyze` passed; iOS simulator pairing was exercised through the debugger agent and live Sessions loaded from the daemon after paired device scopes matched the daemon authorizer.
- Next likely step: handle Inspect when `CONTINUUM_ACTIVE_SESSION_ID` is missing or stale by deriving it from a selected live session or showing a non-error empty state.

- Next likely step: build a protocol-consumer reference or deeper interoperability checks on top of the mock without reopening the frozen ASCP v0.1 contracts

### 2026-04-22 - Conformance

- Branch: `feature/conformance`
- Commit: `not committed`
- Summary: added a normative compatibility spec, a machine-readable compatibility matrix, golden example manifests spanning requests, responses, events, replay flows, auth failures, and extension handling, and a repeatable top-level conformance harness that composes the existing method, event, replay, auth, and extension validators into evidence-backed ASCP compatibility claims
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/compatibility.md`
- Next likely step: build `feature/mock-server` against the frozen compatibility matrix and golden conformance fixtures instead of redefining protocol behavior in the mock

### 2026-04-22 - Extensions

- Branch: `feature/extensions`
- Commit: `not committed`
- Summary: added the normative extensions spec, documented namespacing and capability advertisement rules, created namespaced method, event, field, and capability examples, and added a repeatable validator plus ignore-behavior fixtures that make the open-versus-closed schema boundary explicit for later conformance work
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/extensions.md`, `docs/superpowers/specs/2026-04-22-extensions-design.md`, `docs/superpowers/plans/2026-04-22-extensions.md`
- Next likely step: build `feature/conformance` or `feature/mock-server` using the frozen extension rules instead of reopening namespacing semantics

### 2026-04-22 - Auth and approvals

- Branch: `feature/auth-approvals`
- Commit: `not committed`
- Summary: added the normative auth and approvals spec, documented the method scope matrix and audit-attribution hooks, created approval lifecycle fixtures for approved, rejected, and expired outcomes, expanded auth failure examples to distinguish `UNAUTHORIZED` from `FORBIDDEN`, and added a repeatable validator for auth-specific invariants against the frozen method and event contracts
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/auth.md`, `docs/superpowers/specs/2026-04-22-auth-approvals-design.md`, `docs/superpowers/plans/2026-04-22-auth-approvals.md`
- Next likely step: build `feature/extensions` or widen into the broader `conformance` slice using the auth and approval rules from this branch as fixed inputs

### 2026-04-22 - Replay semantics

- Branch: `feature/replay-semantics`
- Commit: `not committed`
- Summary: added the normative replay semantics spec, created replay-focused conformance fixtures for snapshot, from-seq, from-event-id, opaque-cursor, and retention-limited recovery paths, and added a repeatable validator that checks replay-specific ordering, boundary, and fallback rules against the frozen method and event contracts
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/replay.md`, `docs/superpowers/specs/2026-04-22-replay-semantics-design.md`, `docs/superpowers/plans/2026-04-22-replay-semantics.md`
- Next likely step: build `feature/auth-and-approvals` or widen into the broader `conformance` slice using the replay rules and replay fixtures as fixed inputs

### 2026-04-22 - Event contracts

- Branch: `feature/event-contracts`
- Commit: `not committed`
- Summary: added the ASCP event-contract schema, one schema-valid `EventEnvelope` fixture for every core event type, a normative event support spec, and a repeatable validator that confirms the full event surface against the frozen schema foundation
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/events.md`, `docs/superpowers/specs/2026-04-22-event-contracts-design.md`, `docs/superpowers/plans/2026-04-22-event-contracts.md`
- Next likely step: build `feature/replay-semantics` from the locked event stream surface, without redefining event payload shapes

### 2026-04-22 - Method contracts

- Branch: `feature/method-contracts`
- Commit: `not committed`
- Summary: added the ASCP method-contract schema, a normative method surface spec, and request/success/error example envelopes for every core method; documented capability gating and method-specific error mapping; and added a repeatable validator that confirms the full method-contract example set against the shared schema foundation
- Documentation updated: `plans.md`, `docs/status.md`, `protocol/spec/methods.md`
- Next likely step: build `feature/event-contracts` from the frozen method triggers and shared `EventEnvelope`, without widening back into method shape changes
### 2026-04-21 - Schema foundation

- Branch: `feature/schema-foundation`
- Commit: `a436ccc`
- Summary: added the canonical ASCP core, capability, and error schemas; added schema-valid examples for the required protocol nouns and shared envelope baseline; and documented the schema-foundation scope and versioning assumptions for later method-contract work
- Documentation updated: `plans.md`, `docs/status.md`, `docs/schema-foundation.md`
- Next likely step: build `feature/method-contracts` from these frozen nouns and shared envelopes, without widening into full event or replay work yet

### 2026-04-21 - Workstream prompt pack

- Branch: `main`
- Commit: `not committed`
- Summary: added reusable starter prompts for each ASCP workstream so new conversations can bootstrap the correct feature boundary, dependency reads, deliverables, and stop conditions from repository state
- Documentation updated: `plans.md`, `docs/status.md`, `docs/prompts/README.md`, `docs/prompts/schema-foundation.md`, `docs/prompts/method-contracts.md`, `docs/prompts/event-contracts.md`, `docs/prompts/replay-semantics.md`, `docs/prompts/auth-and-approvals.md`, `docs/prompts/extensions.md`, `docs/prompts/conformance.md`, `docs/prompts/mock-server.md`
- Next likely step: use one of the prompt files to start the next scoped feature branch, beginning with `docs/prompts/schema-foundation.md`

### 2026-04-21 - Protocol workstream plan

- Branch: `main`
- Commit: `not committed`
- Summary: bootstrapped from repository state, confirmed the previous feature is complete, and mapped the ASCP protocol workstreams, dependencies, branch boundaries, and first build slice
- Documentation updated: `plans.md`, `docs/status.md`
- Next likely step: create `feature/schema-foundation` from updated `main` and implement the schema foundation slice only

### 2026-04-21 - Repository operating system

- Branch: `feature/repo-operating-system`
- Commit: `5e2fb07`
- Summary: added explicit intake, planning, drift-control, and checkpoint workflow assets for the ASCP repository
- Documentation updated: `AGENTS.md`, `plans.md`, `docs/repo-operating-system.md`, `README.md`
- Next likely step: choose the next protocol feature and create a dedicated feature branch and scoped plan for it

### 2026-05-29 - Mobile live session detail and simulator QA

- Branch: `codex/mobile-live-session-detail`
- Commit: `not committed`
- Summary: added sessions-list-to-detail navigation, live `sessions.subscribe` wiring, payload-aware timeline rendering for user/agent/tool/approval/terminal-style events, protocol-valid `sessions.send_input` params, and inspect empty-state handling for unsupported or missing artifact metadata. Verified pairing, authenticated WebSocket sessions, live send-input/event feedback, approvals empty state, inspect empty state, and trusted-device settings on the iPhone 16e simulator against a loopback daemon.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Verification: `flutter test`, `flutter analyze`, iOS simulator live run with ASCP daemon on `127.0.0.1:9875` and pairing admin/proxy on `9876`/`9877`
- Next likely step: continue visual parity by comparing each remaining Flutter screen against the HTML references in `Continuum Design System/BUILD_ORDER.md`, then convert the current hand-built controls toward Flutter shadcn CLI components where the registry has matching primitives.

### 2026-05-29 - Mobile HTML screen parity pass

- Branch: `codex/mobile-live-session-detail`
- Commit: `not committed`
- Summary: used Codex as orchestrator/reviewer and external CLI routes for implementation, rebuilding the trusted Home dashboard, Sessions list, live session detail feed, Approvals queue, Inspect empty/artifact states, and Settings screen toward the Continuum HTML references. Removed duplicate shell headers from non-detail tabs and fixed the simulator-observed approvals count mismatch by making the header subtitle data-driven.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Verification: `flutter analyze` passed; `flutter test` passed with 152 tests; iOS simulator build/run passed on iPhone 16e; manual simulator QA paired with `127.0.0.1:8765:APPROVE` and confirmed the Home, Sessions, Approvals, Inspect, and Settings tab surfaces render without duplicate shell headers, with the Approvals empty state now showing `No pending actions`.
- Next likely step: replace static dashboard paired devices and display preferences with live daemon-backed data/actions, then continue HTML parity on populated-data states.

### 2026-05-31 - Mobile attached screen parity pass

- Branch: `codex/mobile-live-session-detail`
- Commit: `not committed`
- Summary: used Codex as orchestrator/reviewer with Agent Forge subagent attempts, then finalized the Flutter UI pass for the attached mobile references. The trusted shell now has Home, Sessions, Approvals, Devices, and Settings tabs; Home, Approvals, Settings, Trusted devices, and Pairing were restyled toward the screenshots, including the dark scanner/code-entry pairing flow and the dedicated trusted devices surface.
- Documentation updated: `internal/plans.md`, `internal/status.md`
- Verification: `flutter analyze` passed; `flutter test` passed; `flutter_shadcn validate --json`, `flutter_shadcn audit --json`, and `flutter_shadcn deps --json` passed; XcodeBuildMCP built and launched Runner on iPhone 17 Pro and captured the updated dark pairing screenshot at `/var/folders/dt/p77q2g1j7190pw1cc_h07hg80000gn/T/screenshot_optimized_b395d82c-fb5b-48b6-8cd4-31a29ab495db.jpg`.
- Next likely step: tighten the live session detail screen against the attached chat reference and add automated XCUITest coverage for the simulator parity path.
