#!/usr/bin/env python3
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    snapshot = {}

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
            length = min(int(self.headers.get("Content-Length", "0")), 65536)
            Handler.snapshot = json.loads(self.rfile.read(length) or b"{}")
            self.send_json(200, {"synced": True})
        except (ValueError, json.JSONDecodeError):
            self.send_json(400, {"error": "invalid_json"})

    def send_json(self, status, body):
        payload = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    print("YPadel backend: http://localhost:8080")
    ThreadingHTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
