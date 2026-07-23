FROM python:3.12-slim

# Patch OS vulnerabilities for GCP Artifact Analysis
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Non-root user setup
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser

WORKDIR /app
COPY main.py .

RUN chown -R appuser:appgroup /app
USER 1001

EXPOSE 8080
CMD ["python", "main.py"]
