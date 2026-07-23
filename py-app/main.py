"""Minimal GKE Marketplace sample application."""

import http.server
import os
import json

PORT = int(os.environ.get("PORT", "8080"))
LICENSE_KEY = os.environ.get("LICENSE_KEY", "not-set")


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self._respond(200, {"status": "healthy"})
        elif self.path == "/":
            body = {
                "message": "GKE Marketplace Terraform POC is running",
                "license_key_present": LICENSE_KEY != "not-set",
            }
            self._respond(200, body)
        else:
            self._respond(404, {"error": "not found"})

    def _respond(self, code, body):
        payload = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Listening on :{PORT}")
    server.serve_forever()
