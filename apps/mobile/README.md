# Continuum Mobile

Flutter companion app for ASCP host pairing, trusted-device onboarding, live session observation, approvals, artifacts, diffs, and settings.

## Architecture

The app uses a feature-first structure:

- `lib/core/ascp`: exact ASCP method names, JSON-RPC envelopes, errors, event envelopes, statuses, and extension-safe parsing.
- `lib/core/network`: HTTP and WebSocket JSON-RPC clients plus reconnect policy.
- `lib/core/security`: local trust material, secure-store interface, Flutter secure-storage adapter, and local auth gate boundary.
- `lib/core/database`: Drift-backed replay cursor persistence boundary.
- `lib/app/mobile_dependencies.dart`: app-level memory/live dependency container that wires controllers to ASCP, daemon, scanner, and local-auth boundaries.
- `lib/features/*`: feature-owned domain, data, application, and presentation code.
- `lib/ui/shadcn`: components installed by `flutter_shadcn`.

ASCP remains protocol-first. The mobile client must not redefine method names, event names, session statuses, replay semantics, approval semantics, or host trust behavior.

## Flutter shadcn

Use `flutter_shadcn` as the source of truth for registry operations:

```bash
flutter_shadcn dry-run <components> --json
flutter_shadcn add <components>
flutter_shadcn validate --json
flutter_shadcn audit --json
flutter_shadcn deps --json
```

The current foundation includes app, card, button, badge, dialog, drawer, navigation, tabs, form controls, text inputs, skeleton, toast, tooltip, timeline, and code snippet primitives.

## State And Transport

Riverpod is the default state-management and dependency-injection layer. BLoC is allowed only for isolated feature-local event machines.

Transport is split:

- HTTP JSON-RPC: ASCP discovery, session reads, approval reads/responses, artifacts, diffs, and other non-streaming protocol calls.
- WebSocket JSON-RPC: subscriptions, event streams, input, reconnect, and replay.
- Loopback daemon REST: pairing claim/poll and trusted-device administration. These endpoints are daemon onboarding/admin surfaces, not ASCP core methods.

Replay cursors are stored in Drift per host and session. Session summaries, artifact details, and diff details are also cached by host/session so reconnect recovery can show useful metadata before fresh ASCP reads complete. `sessions.subscribe` can request replay from a known sequence and maps live/replayed ASCP events into feature-owned timeline events. The mobile client never invents missing ASCP sequence numbers.

Riverpod owns the default app dependency graph through `mobileRuntimeConfigProvider` and `mobileDependenciesProvider`. Tests can override those providers through `ProviderScope`, while focused widget tests can still pass explicit `MobileDependencies` constructors.

`MobileDependencies.memory()` keeps deterministic in-memory controllers for tests and local shell previews. `MobileDependencies.live()` wires Dio-backed ASCP JSON-RPC repositories, daemon admin/pairing repositories, a lazy WebSocket subscription repository, `FlutterSecureStore`, `DeviceLocalAuthGate`, and the `mobile_scanner` QR scanner path.

The platform shells are configured for the live mobile capabilities:

- Android release manifest declares network, camera, and biometric permissions, and `MainActivity` extends `FlutterFragmentActivity` for `local_auth`.
- iOS declares camera and Face ID usage descriptions for pairing scans and trusted-device confirmations.

The default provider reads live device configuration from `--dart-define` values. Incomplete live configuration falls back to memory mode so local previews stay deterministic:

```bash
flutter run \
  --dart-define=CONTINUUM_MOBILE_MODE=live \
  --dart-define=CONTINUUM_ASCP_RPC_ENDPOINT=http://127.0.0.1:18787/rpc \
  --dart-define=CONTINUUM_ASCP_WS_ENDPOINT=ws://127.0.0.1:18787/rpc \
  --dart-define=CONTINUUM_DAEMON_ADMIN_BASE_URL=http://127.0.0.1:18787 \
  --dart-define=CONTINUUM_HOST_ID=host_local \
  --dart-define=CONTINUUM_ACTIVE_SESSION_ID=sess_active \
  --dart-define=CONTINUUM_DEVICE_ID=device_mobile
```

## iOS Simulator

The Runner project supports both physical iOS devices and simulators through `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`. If `flutter run -d <simulator-id>` reports that Xcode cannot find the selected simulator destination, verify that Xcode has a simulator runtime matching its installed SDK:

```bash
xcodebuild -showsdks
xcrun simctl list runtimes
flutter devices -v
```

For Xcode 26.3 with the iOS Simulator 26.2 SDK, install the iOS 26.2 simulator runtime from Xcode > Settings > Components before launching on an iOS simulator. After the runtime is installed, rerun:

```bash
flutter run -d B42021B5-74F7-482A-8D2A-A645439C0CF2
```

## Test Workflow

Development is test-driven:

```bash
flutter test
flutter test test_goldens
flutter analyze
flutter_shadcn validate --json
flutter_shadcn audit --json
flutter_shadcn deps --json
```

Focused tests live beside the feature or core boundary they protect.
