FROM nginx:1.27-alpine

# Patch OS-level packages to fix known vulnerabilities (libxml2, openssl, etc.)
RUN apk update && apk upgrade --no-cache

RUN echo "<h1>Marketplace K8s POC App</h1>" > /usr/share/nginx/html/index.html

EXPOSE 80
