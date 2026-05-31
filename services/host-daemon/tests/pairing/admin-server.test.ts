import { afterEach, describe, expect, it } from "vitest";

import { startHostDaemon, type RunningHostDaemon } from "../../src/main.js";

const daemonsToClose = new Set<RunningHostDaemon>();

afterEach(async () => {
  for (const daemon of daemonsToClose) {
    await daemon.close();
  }

  daemonsToClose.clear();
});

describe("pairing admin server", () => {
  it("lists pairing sessions for the host lifecycle panel", async () => {
    const daemon = await createPairingHarness();
    daemonsToClose.add(daemon);

    const created = await requestJson(daemon.adminUrl, "POST", "/admin/pairing/sessions", {
      requested_scopes: ["read:hosts", "read:sessions"]
    });

    const pendingList = await requestJson(daemon.adminUrl, "GET", "/admin/pairing/sessions");
    expect(pendingList).toMatchObject({
      sessions: [
        {
          approved_at: null,
          claim_token: null,
          claimed_at: null,
          code: created.code,
          consumed_at: null,
          created_at: expect.any(String),
          device_label: null,
          expires_at: created.expires_at,
          issued_device_id: null,
          qr_payload: JSON.stringify({
            code: created.code,
            session_id: created.session_id
          }),
          rejected_at: null,
          requested_scopes: ["read:hosts", "read:sessions"],
          session_id: created.session_id,
          status: "pending_host_claim"
        }
      ]
    });

    const claimed = await requestJson(daemon.adminUrl, "POST", "/pairing/claim", {
      code: created.code,
      device_label: "Lifecycle phone"
    });

    await requestJson(
      daemon.adminUrl,
      "POST",
      `/admin/pairing/sessions/${created.session_id}/approve`,
      {}
    );

    await requestJson(daemon.adminUrl, "GET", `/pairing/claims/${claimed.claim_token}`);

    const consumedList = await requestJson(daemon.adminUrl, "GET", "/admin/pairing/sessions");
    expect(consumedList).toMatchObject({
      sessions: [
        {
          claim_token: claimed.claim_token,
          claimed_at: expect.any(String),
          code: created.code,
          consumed_at: expect.any(String),
          created_at: expect.any(String),
          device_label: "Lifecycle phone",
          expires_at: created.expires_at,
          issued_device_id: expect.any(String),
          requested_scopes: ["read:hosts", "read:sessions"],
          session_id: created.session_id,
          status: "consumed"
        }
      ]
    });
  });

  it("creates pairing sessions, approves them, and revokes trusted devices over loopback HTTP", async () => {
    const daemon = await createPairingHarness();
    daemonsToClose.add(daemon);

    const createResponse = await requestJson(daemon.adminUrl, "POST", "/admin/pairing/sessions", {
      requested_scopes: ["read:hosts", "read:sessions"]
    });

    expect(createResponse).toMatchObject({
      code: expect.stringMatching(/^\d{6}$/),
      expires_at: expect.any(String),
      session_id: expect.any(String)
    });

    const claimResponse = await requestJson(daemon.adminUrl, "POST", "/pairing/claim", {
      code: createResponse.code,
      device_label: "QA phone"
    });

    await requestJson(
      daemon.adminUrl,
      "POST",
      `/admin/pairing/sessions/${createResponse.session_id}/approve`,
      {}
    );

    const pollResponse = await requestJson(
      daemon.adminUrl,
      "GET",
      `/pairing/claims/${claimResponse.claim_token}`
    );

    expect(pollResponse).toMatchObject({
      status: "approved",
      credentials: {
        device_id: expect.any(String),
        device_secret: expect.any(String)
      }
    });

    const devicesResponse = await requestJson(daemon.adminUrl, "GET", "/admin/trusted-devices");
    expect(devicesResponse.devices).toHaveLength(1);

    const revokeResponse = await requestJson(
      daemon.adminUrl,
      "POST",
      `/admin/trusted-devices/${encodeURIComponent(pollResponse.credentials.device_id)}/revoke`,
      {}
    );
    expect(revokeResponse).toMatchObject({
      device_id: pollResponse.credentials.device_id,
      revoked: true
    });
  });

  it("exposes admin diagnostics endpoint", async () => {
    const daemon = await createPairingHarness();
    daemonsToClose.add(daemon);

    const diagnostics = await requestJson(daemon.adminUrl, "GET", "/admin/diagnostics");
    expect(diagnostics).toMatchObject({
      host_id: "127.0.0.1",
      replay_enabled: true,
      state: "connected"
    });
  });

  it("returns 409 for duplicate claims", async () => {
    const daemon = await createPairingHarness();
    daemonsToClose.add(daemon);

    const createResponse = await requestJson(daemon.adminUrl, "POST", "/admin/pairing/sessions", {
      requested_scopes: ["read:sessions"]
    });

    await requestJson(daemon.adminUrl, "POST", "/pairing/claim", {
      code: createResponse.code,
      device_label: "Phone A"
    });

    const duplicate = await requestJson(daemon.adminUrl, "POST", "/pairing/claim", {
      code: createResponse.code,
      device_label: "Phone B"
    });

    expect(duplicate).toMatchObject({
      code: "ALREADY_CLAIMED"
    });
  });
});

async function createPairingHarness(): Promise<RunningHostDaemon> {
  return startHostDaemon({
    config: {
      adminPort: 0,
      authTransport: "loopback",
      databasePath: ":memory:",
      host: "127.0.0.1",
      port: 0,
      runtime: "codex"
    },
    runtimeRegistry: {
      createRuntime: () => ({
        capabilitiesGet: async () => ({
          capabilities: {
            replay: true
          },
          host: {
            id: "host:1",
            status: "online",
            transports: ["websocket"]
          },
          protocol_version: "0.1.0",
          runtimes: [],
          transports: ["websocket"]
        }),
        hostsGet: async () => ({
          host: {
            id: "host:1",
            status: "online",
            transports: ["websocket"]
          }
        })
      })
    }
  });
}

async function requestJson(
  baseUrl: string,
  method: "GET" | "POST",
  pathname: string,
  body?: Record<string, unknown>
): Promise<Record<string, any>> {
  const response = await fetch(new URL(pathname, baseUrl), {
    body: body === undefined ? undefined : JSON.stringify(body),
    headers: {
      "content-type": "application/json"
    },
    method
  });

  return (await response.json()) as Record<string, any>;
}
