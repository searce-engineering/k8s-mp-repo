# ────────────────────────────────────────────────────────────
# Single-stage build — reliable on Apple Silicon / Rancher Desktop
# Multi-stage builds with venv COPY can produce incomplete layers
# on some Docker runtimes (Rancher Desktop, colima, etc.).
# pip installs gunicorn to /usr/local/bin — always in PATH.
# ────────────────────────────────────────────────────────────
FROM python:3.12-slim

# Non-root user (GCP Marketplace security requirement)
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser


WORKDIR /app

# Install dependencies as root so they land in /usr/local/bin + site-packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY app.py .

# Hand ownership of the workdir to appuser
RUN chown -R appuser:appgroup /app
USER 1001

ENV APP_NAME="byol-python-app" \
    APP_VERSION="1.0.0" \
    PORT="8080" \
    LICENSE_KEY="" \
    LICENSE_SECRET=""

EXPOSE 8080

CMD ["gunicorn", \
     "--bind", "0.0.0.0:8080", \
     "--workers", "2", \
     "--timeout", "30", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "app:app"]
