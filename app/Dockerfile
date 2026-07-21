FROM python:3.12-slim

# GCP Marketplace required annotation (update with your actual service name)
LABEL "com.googleapis.cloudmarketplace.product.service.name"="services/services/gcp-mp-poc-k8s.endpoints.searce-cloud-products.cloud.goog"

# Ensure immediate log output in kubectl and avoid writing .pyc on disk
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Patch OS vulnerabilities for GCP Artifact Analysis
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Non-root user setup
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN chown -R appuser:appgroup /app
USER 1001

ENV APP_NAME="gcp-mp-poc-k8s" \
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