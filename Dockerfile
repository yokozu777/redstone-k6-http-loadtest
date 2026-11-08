# Official k6 image (Alpine).
FROM grafana/k6:latest

# INSTALL_LOCAL_CERT=true installs certificates from ./certs into the trusted CA store.
# REMOTE_CA_URL, when set, downloads a CA from that URL (for example https://ca.mxhash.dev:8443/roots.pem).
ARG INSTALL_LOCAL_CERT=false
ARG REMOTE_CA_URL=

USER root

RUN apk add --no-cache ca-certificates curl

COPY certs/ /tmp/local-certs/
RUN set -eux; \
    mkdir -p /usr/local/share/ca-certificates; \
    if [ "$INSTALL_LOCAL_CERT" = "true" ]; then \
      if ! ls /tmp/local-certs/*.crt >/dev/null 2>&1; then \
        echo "INSTALL_LOCAL_CERT=true but certs/ has no .crt files" >&2; \
        exit 1; \
      fi; \
      cp /tmp/local-certs/*.crt /usr/local/share/ca-certificates/; \
    fi; \
    if [ -n "$REMOTE_CA_URL" ]; then \
      curl -fsSLk -o /usr/local/share/ca-certificates/remote-ca.crt "$REMOTE_CA_URL"; \
    fi; \
    rm -rf /tmp/local-certs; \
    find /usr/local/share/ca-certificates -name '*.crt' -exec chmod 644 {} +; \
    update-ca-certificates

WORKDIR /app

COPY loadtest.js .
COPY config/ ./config/
RUN chmod -R a+rX /app

USER k6

ENV TARGET_HOST=https://change-me.example/
ENV ENDPOINTS=/

# Default run: 200 virtual users for 10 minutes, thresholds from config/default.json.
CMD ["-c", "/app/config/default.json", "run", "--vus", "200", "--duration", "10m", "/app/loadtest.js"]
