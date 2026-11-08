import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics. Stages and thresholds come from a profile in config/.
export let errorRate = new Rate('errors');
export let responseTime = new Trend('response_time');

const targetHost = __ENV.TARGET_HOST || 'https://change-me.example/';

// Comma-separated paths, for example /api/status,/api/health.
const endpoints = (__ENV.ENDPOINTS || '/')
    .split(',')
    .map((path) => path.trim())
    .filter((path) => path.length > 0);

if (endpoints.length === 0) {
    throw new Error('ENDPOINTS is empty. Set a comma-separated list of paths.');
}

const scenarios = {
    headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'k6-loadtest/1.0',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
    },
};

function joinUrl(host, path) {
    const base = host.endsWith('/') ? host.slice(0, -1) : host;
    const suffix = path.startsWith('/') ? path : `/${path}`;
    return base + suffix;
}

export default function () {
    endpoints.forEach(endpoint => {
        const url = joinUrl(targetHost, endpoint);
        const response = http.get(url, { headers: scenarios.headers });
        const ok = check(response, {
            [`GET ${endpoint} status is 200`]: (r) => r.status === 200,
            [`GET ${endpoint} response time < 5s`]: (r) => r.timings.duration < 5000,
            [`GET ${endpoint} has content`]: (r) => r.body && r.body.length > 0,
        });

        errorRate.add(!ok);
        responseTime.add(response.timings.duration);
        sleep(1);
    });
}

export function setup() {
    console.log('Starting the load test...');
    console.log('Target host:', targetHost);
    console.log('Paths:', endpoints.join(', '));
    return {};
}

export function teardown() {
    console.log('Load test finished');
}
