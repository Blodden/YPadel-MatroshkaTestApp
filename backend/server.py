#!/usr/bin/env python3
import json
import secrets
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    records = {}
    records_lock = threading.Lock()

    def do_GET(self):
        if self.path != "/health":
            self.send_error(404)
            return
        self.send_json(200, {"status": "ok"})

    def do_POST(self):
        if self.path != "/sync":
            self.send_error(404)
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 65536:
                raise ValueError("invalid_length")
            body = json.loads(self.rfile.read(length))
            response = self.sync(body)
            self.send_json(200, response)
        except (TypeError, ValueError, json.JSONDecodeError) as error:
            self.send_json(400, {"error": str(error) or "invalid_request"})

    @classmethod
    def sync(cls, body):
        installation_id = body.get("installationId")
        snapshot = body.get("snapshot")
        client_revision = body.get("clientRevision")
        push = body.get("push") or {}
        if not isinstance(installation_id, str) or not installation_id:
            raise ValueError("installation_id_required")
        if not isinstance(snapshot, dict) or not isinstance(client_revision, int):
            raise ValueError("snapshot_required")

        token = body.get("matchToken")
        if not isinstance(token, str) or token not in cls.records:
            token = secrets.token_urlsafe(12)

        with cls.records_lock:
            current = cls.records.get(token)
            current_revision = current["revision"] if current else -1
            if current is None or client_revision >= current_revision:
                current = {
                    "installationId": installation_id,
                    "revision": client_revision,
                    "snapshot": snapshot,
                    "push": push,
                }
                cls.records[token] = current
                status = "updated"
            else:
                status = "current"

        push_token = current.get("push", {}).get("token")
        push_enabled = current.get("push", {}).get("enabled") is True
        return {
            "status": status,
            "matchToken": token,
            "serverRevision": current["revision"],
            "snapshot": current["snapshot"],
            "pushStatus": "pending_credentials" if push_token and push_enabled else "not_registered",
            "serverTime": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        }

    def send_json(self, status, body):
        payload = json.dumps(body, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8080), Handler)
    server.daemon_threads = True
    print("YPoints backend: http://localhost:8080")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
