"""
GCP Marketplace BYOL Python App — POC
Flask application with BYOL license verification.
License key is injected via a Kubernetes Secret → env var.
"""

import os
import hmac
import hashlib
import logging
from datetime import datetime

from flask import Flask, jsonify, request

# ──────────────────────────────────────────────
# Config
# ──────────────────────────────────────────────
app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

APP_VERSION   = os.environ.get("APP_VERSION", "1.0.0")
APP_NAME      = os.environ.get("APP_NAME", "gcp-mp-poc-k8s")
LICENSE_KEY   = os.environ.get("LICENSE_KEY", "")          # injected from K8s Secret
LICENSE_SECRET = os.environ.get("LICENSE_SECRET", "")      # your server-side secret


# ──────────────────────────────────────────────
# License helpers
# ──────────────────────────────────────────────
def verify_license(provided_key: str) -> bool:
    """
    BYOL verification logic.
    Replace this with a call to your real license server / JWT validation.
    This demo uses HMAC-SHA256 so you can test locally without a server.

    To generate a valid test key:
        import hmac, hashlib
        hmac.new(b"my-secret", b"my-license", hashlib.sha256).hexdigest()
    """
    if not provided_key or not LICENSE_SECRET:
        logger.warning("License key or server secret is missing.")
        return False

    expected = hmac.new(
        LICENSE_SECRET.encode(),
        APP_NAME.encode(),
        hashlib.sha256,
    ).hexdigest()

    return hmac.compare_digest(provided_key.strip(), expected.strip())


def require_license(f):
    """Decorator — blocks routes if license is invalid."""
    from functools import wraps

    @wraps(f)
    def decorated(*args, **kwargs):
        if not verify_license(LICENSE_KEY):
            return jsonify({
                "error": "license_invalid",
                "message": (
                    "A valid BYOL license key is required. "
                    "Set LICENSE_KEY via your Kubernetes Secret."
                ),
            }), 403
        return f(*args, **kwargs)

    return decorated


# ──────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────
@app.route("/healthz")
def health():
    """Kubernetes liveness probe."""
    return jsonify({"status": "ok", "timestamp": datetime.utcnow().isoformat()}), 200


@app.route("/readyz")
def ready():
    """Kubernetes readiness probe — only ready when license is valid."""
    if not verify_license(LICENSE_KEY):
        return jsonify({"status": "not_ready", "reason": "invalid_license"}), 200
    return jsonify({"status": "ready"}), 200


@app.route("/license/status")
def license_status():
    """Public endpoint: reports license validity (no sensitive data)."""
    valid = verify_license(LICENSE_KEY)
    return jsonify({
        "licensed": valid,
        "model":    "BYOL",
        "app":      APP_NAME,
        "version":  APP_VERSION,
    }), 200 if valid else 403


@app.route("/")
@require_license
def index():
    return jsonify({
        "message": f"Hello from {APP_NAME}!",
        "version": APP_VERSION,
        "license": "valid",
        "model":   "BYOL",
    })


@app.route("/api/data")
@require_license
def api_data():
    """Example protected business-logic endpoint."""
    return jsonify({
        "data": [
            {"id": 1, "value": "sample-record-1"},
            {"id": 2, "value": "sample-record-2"},
            {"id": 3, "value": "sample-record-3"},
        ],
        "count": 3,
    })


# ──────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    logger.info("Starting %s v%s on port %d", APP_NAME, APP_VERSION, port)
    app.run(host="0.0.0.0", port=port)
