# k6 load test

Load-test an HTTP service with [Grafana k6](https://grafana.com/docs/k6/). The default target is `https://change-me.example/` and the default path is `/`.

## Layout

```
nginx_nt/
├── Dockerfile
├── docker-compose.yml
├── loadtest.js
├── config/
│   ├── default.json
│   ├── light-load.json
│   ├── heavy-load.json
│   └── spike-test.json
├── certs/
├── build-and-run.sh
├── build-and-run.ps1
└── results/
```

## Paths

`ENDPOINTS` is a comma-separated list of paths. Each virtual user sends a GET to every path and checks status 200, a body, and a response time under 5 seconds. The default is `/`.

## Profiles

| Profile | File | Shape |
| --- | --- | --- |
| default | `config/default.json` | 200 virtual users for 10 minutes. 95% of requests under 5s, failed requests under 20%. |
| light | `config/light-load.json` | Ramp to 10 users. 95% under 1s, failed requests under 5%. |
| heavy | `config/heavy-load.json` | Ramp to 500 users. 95% under 5s, failed requests under 20%. |
| spike | `config/spike-test.json` | Jumps to 200, then 300 users. 95% under 3s, failed requests under 15%. |

## Quick start

macOS and Linux. The first argument selects the profile. `default` is 200 virtual users for 10 minutes.

```bash
./build-and-run.sh
./build-and-run.sh light
./build-and-run.sh heavy
./build-and-run.sh spike
```

Windows uses the same choice:

```powershell
.\build-and-run.ps1
.\build-and-run.ps1 light
.\build-and-run.ps1 -Profile heavy -TargetHost https://example.com/
```

Variables, with their defaults:

| Variable | Default | Meaning |
| --- | --- | --- |
| profile argument | `default` | `default`, `light`, `heavy`, or `spike` |
| `TARGET_HOST` | `https://change-me.example/` | Host the test calls |
| `ENDPOINTS` | `/` | Comma-separated paths, for example `/api/status,/api/health` |
| `INSTALL_LOCAL_CERT` | `false` | `true` copies `certs/*.crt` into the image trust store |
| `REMOTE_CA_URL` | empty | Download a CA and install it. TLS verification is skipped |

```bash
TARGET_HOST=https://example.com/ \
ENDPOINTS=/api/status,/api/health \
INSTALL_LOCAL_CERT=true \
REMOTE_CA_URL=https://ca.mxhash.dev:8443/roots.pem \
./build-and-run.sh heavy
```

JSON output is `results/results.json` for `default`, and `results/light.json`, `results/heavy.json`, or `results/spike.json` for the other profiles.

`docker compose run k6-loadtest` always runs the default profile with the host set in `docker-compose.yml` and writes `results/results.json`.

## Certificates

Nothing is added to the trust store unless `INSTALL_LOCAL_CERT=true` or `REMOTE_CA_URL` is set on the command above. `true` copies `certs/*.crt` and runs `update-ca-certificates`. The build stops if that directory has no `.crt` files. A CA URL is saved as `remote-ca.crt`. The server may be presenting the certificate being installed.

Put only public CA files in `certs/`. Do not commit the matching private key.

## Results

k6 prints the summary in the terminal. JSON output goes to `results/` when you use the launcher or Compose. Those files are local and are not part of this repository.
