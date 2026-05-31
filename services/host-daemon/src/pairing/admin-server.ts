import { createServer, type IncomingMessage, type Server as HttpServer, type ServerResponse } from "node:http";

import type { PairingBackendService } from "./service.js";
import type { PairingSessionRecord } from "./types.js";

export interface PairingAdminServer {
  close(): Promise<void>;
  listen(): Promise<void>;
  readonly url: string;
}

export function createPairingAdminServer(options: {
  host?: string;
  pairingService: PairingBackendService;
  port?: number;
}): PairingAdminServer {
  return new LoopbackPairingAdminServer(options);
}

class LoopbackPairingAdminServer implements PairingAdminServer {
  private readonly host: string;
  private readonly port: number;
  private readonly pairingService: PairingBackendService;
  private readonly httpServer: HttpServer;
  private listening = false;
  private resolvedUrl = "";

  constructor(options: { host?: string; pairingService: PairingBackendService; port?: number }) {
    this.host = options.host ?? "127.0.0.1";
    this.port = options.port ?? 0;
    this.pairingService = options.pairingService;
    this.httpServer = createServer((request, response) => {
      void this.handleRequest(request, response);
    });
  }

  get url(): string {
    if (this.resolvedUrl.length === 0) {
      throw new Error("Pairing admin server is not listening.");
    }

    return this.resolvedUrl;
  }

  async listen(): Promise<void> {
    if (this.listening) {
      return;
    }

    await new Promise<void>((resolve, reject) => {
      const onError = (error: Error) => {
        this.httpServer.off("listening", onListening);
        reject(error);
      };

      const onListening = () => {
        this.httpServer.off("error", onError);
        resolve();
      };

      this.httpServer.once("error", onError);
      this.httpServer.once("listening", onListening);
      this.httpServer.listen(this.port, this.host);
    });

    const address = this.httpServer.address();

    if (address === null || typeof address === "string") {
      throw new Error("Pairing admin server failed to resolve a listening address.");
    }

    this.resolvedUrl = `http://${this.host}:${address.port}`;
    this.listening = true;
  }

  async close(): Promise<void> {
    if (!this.listening) {
      return;
    }

    await new Promise<void>((resolve, reject) => {
      this.httpServer.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  }

  private async handleRequest(request: IncomingMessage, response: ServerResponse): Promise<void> {
    try {
      const url = new URL(request.url ?? "/", "http://127.0.0.1");
      const pathname = url.pathname;

      if (request.method === "OPTIONS") {
        sendCorsHeaders(response);
        response.statusCode = 204;
        response.end();
        return;
      }

      if (request.method === "POST" && pathname === "/admin/pairing/sessions") {
        const body = await readJsonBody(request);
        const created = this.pairingService.startPairing({
          requestedScopes: Array.isArray(body.requested_scopes)
            ? (body.requested_scopes as string[])
            : [],
          ttlMs: typeof body.ttl_ms === "number" ? body.ttl_ms : undefined
        });
        sendJson(response, 201, {
          code: created.code,
          expires_at: created.expiresAt,
          qr_payload: created.qrPayload,
          session_id: created.sessionId
        });
        return;
      }

      if (request.method === "GET" && pathname === "/admin/pairing/sessions") {
        sendJson(response, 200, {
          sessions: this.pairingService
            .listPairingSessions()
            .map((session) => serializePairingSession(session))
        });
        return;
      }

      if (request.method === "POST" && pathname === "/pairing/claim") {
        const body = await readJsonBody(request);

        try {
          const claimed = await this.pairingService.claimPairing({
            code: String(body.code ?? ""),
            deviceLabel: String(body.device_label ?? "")
          });

          sendJson(response, 200, {
            claim_token: claimed.claimToken,
            session_id: claimed.sessionId
          });
        } catch (error) {
          if (error instanceof Error && error.message === "Already claimed.") {
            sendJson(response, 409, {
              code: "ALREADY_CLAIMED",
              message: "Already claimed."
            });
            return;
          }

          throw error;
        }

        return;
      }

      const approveMatch = pathname.match(/^\/admin\/pairing\/sessions\/([^/]+)\/approve$/);
      if (request.method === "POST" && approveMatch !== null) {
        const sessionId = decodeURIComponent(approveMatch[1] ?? "");
        this.pairingService.approvePairing(sessionId);
        sendJson(response, 200, {
          session_id: sessionId,
          status: "approved"
        });
        return;
      }

      const rejectMatch = pathname.match(/^\/admin\/pairing\/sessions\/([^/]+)\/reject$/);
      if (request.method === "POST" && rejectMatch !== null) {
        const sessionId = decodeURIComponent(rejectMatch[1] ?? "");
        this.pairingService.rejectPairing(sessionId);
        sendJson(response, 200, {
          session_id: sessionId,
          status: "rejected"
        });
        return;
      }

      const claimMatch = pathname.match(/^\/pairing\/claims\/([^/]+)$/);
      if (request.method === "GET" && claimMatch !== null) {
        const claimToken = decodeURIComponent(claimMatch[1] ?? "");
        const status = await this.pairingService.pollPairing(claimToken);
        sendJson(response, 200, status);
        return;
      }

      if (request.method === "GET" && pathname === "/admin/trusted-devices") {
        sendJson(response, 200, {
          devices: this.pairingService.listTrustedDevices()
        });
        return;
      }

      if (request.method === "GET" && pathname === "/admin/diagnostics") {
        sendJson(response, 200, {
          host_id: this.host,
          replay_enabled: true,
          state: this.listening ? "connected" : "disconnected"
        });
        return;
      }

      const revokeMatch = pathname.match(/^\/admin\/trusted-devices\/([^/]+)\/revoke$/);
      if (request.method === "POST" && revokeMatch !== null) {
        const deviceId = decodeURIComponent(revokeMatch[1] ?? "");
        this.pairingService.revokeTrustedDevice(deviceId);
        sendJson(response, 200, {
          device_id: deviceId,
          revoked: true
        });
        return;
      }

      sendJson(response, 404, {
        message: "Not found."
      });
    } catch (error) {
      sendJson(response, 400, {
        message: error instanceof Error ? error.message : "Request failed."
      });
    }
  }
}

function serializePairingSession(session: PairingSessionRecord): Record<string, unknown> {
  return {
    approved_at: session.approvedAt,
    claim_token: session.claimToken,
    claimed_at: session.claimedAt,
    code: session.code,
    consumed_at: session.consumedAt,
    created_at: session.createdAt,
    device_label: session.deviceLabel,
    expires_at: session.expiresAt,
    issued_device_id: session.issuedDeviceId,
    qr_payload: JSON.stringify({
      code: session.code,
      session_id: session.sessionId
    }),
    rejected_at: session.rejectedAt,
    requested_scopes: session.requestedScopes,
    session_id: session.sessionId,
    status: session.status
  };
}

async function readJsonBody(request: IncomingMessage): Promise<Record<string, unknown>> {
  const chunks: Buffer[] = [];

  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  if (chunks.length === 0) {
    return {};
  }

  return JSON.parse(Buffer.concat(chunks).toString("utf8")) as Record<string, unknown>;
}

function sendJson(response: ServerResponse, statusCode: number, payload: Record<string, unknown>): void {
  response.statusCode = statusCode;
  sendCorsHeaders(response);
  response.setHeader("content-type", "application/json");
  response.end(JSON.stringify(payload));
}

function sendCorsHeaders(response: ServerResponse): void {
  response.setHeader("access-control-allow-origin", "*");
  response.setHeader("access-control-allow-methods", "GET,POST,OPTIONS");
  response.setHeader("access-control-allow-headers", "content-type");
}
