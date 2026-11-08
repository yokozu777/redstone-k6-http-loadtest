# Security

This repository is a load test. It sends traffic to `TARGET_HOST`. The default is `https://change-me.example/`. Run it only against a system you are allowed to test. The heavy and spike profiles generate hundreds of concurrent requests.

`certs/*.crt` are public CA certificates. They are copied into the image only when `INSTALL_LOCAL_CERT=true`. Do not commit the matching private key. `REMOTE_CA_URL` is fetched with TLS verification disabled (`curl -k`). Prefer a file in `certs/` when you already have the CA.

`results/` can contain response bodies and timings. Do not commit it. The repository has no passwords or private keys.
