import http from 'k6/http';
import { check, group } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '10s', target: 10 }, // Ramp up to 10 RPS
    { duration: '60s', target: 10 }, // Stay at 10 RPS for 60 seconds
    { duration: '10s', target: 0 },  // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    errors: ['rate<0.1'],              // Error rate must be below 10%
  },
};

const API_URL = __ENV.API_URL;
const TEST_SLUG = `perf-test-${Date.now()}-${__VU}`;

export default function () {
  // Test 1: Create URL
  group('POST /urls - Create URL', () => {
    const createPayload = JSON.stringify({
      slug: `${TEST_SLUG}-${__ITER}`,
      fullUrl: 'https://example.com/performance-test',
    });

    const createParams = {
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const createRes = http.post(`${API_URL}/urls`, createPayload, createParams);
    
    const createSuccess = check(createRes, {
      'POST status is 201': (r) => r.status === 201,
      'POST response time < 500ms': (r) => r.timings.duration < 500,
      'POST returns slug': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.slug !== undefined;
        } catch (e) {
          return false;
        }
      },
    });

    errorRate.add(!createSuccess);
  });

  // Test 2: List URLs
  group('GET /urls - List URLs', () => {
    const listRes = http.get(`${API_URL}/urls`);
    
    const listSuccess = check(listRes, {
      'GET /urls status is 200': (r) => r.status === 200,
      'GET /urls response time < 500ms': (r) => r.timings.duration < 500,
      'GET /urls returns items': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.items !== undefined;
        } catch (e) {
          return false;
        }
      },
    });

    errorRate.add(!listSuccess);
  });

  // Test 3: Get specific URL (redirect)
  group('GET /urls/{slug} - Redirect', () => {
    const getRes = http.get(`${API_URL}/urls/${TEST_SLUG}-${__ITER}`, {
      redirects: 0, // Don't follow redirects
    });
    
    const getSuccess = check(getRes, {
      'GET /urls/{slug} status is 302': (r) => r.status === 302,
      'GET /urls/{slug} response time < 500ms': (r) => r.timings.duration < 500,
      'GET /urls/{slug} has Location header': (r) => r.headers['Location'] !== undefined,
    });

    errorRate.add(!getSuccess);
  });

  // Test 4: Update URL
  group('PUT /urls/{slug} - Update URL', () => {
    const updatePayload = JSON.stringify({
      fullUrl: 'https://example.com/updated-performance-test',
    });

    const updateParams = {
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const updateRes = http.put(`${API_URL}/urls/${TEST_SLUG}-${__ITER}`, updatePayload, updateParams);
    
    const updateSuccess = check(updateRes, {
      'PUT status is 200': (r) => r.status === 200,
      'PUT response time < 500ms': (r) => r.timings.duration < 500,
      'PUT returns updated URL': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.fullUrl === 'https://example.com/updated-performance-test';
        } catch (e) {
          return false;
        }
      },
    });

    errorRate.add(!updateSuccess);
  });

  // Test 5: Delete URL
  group('DELETE /urls/{slug} - Delete URL', () => {
    const deleteRes = http.del(`${API_URL}/urls/${TEST_SLUG}-${__ITER}`);
    
    const deleteSuccess = check(deleteRes, {
      'DELETE status is 200': (r) => r.status === 200,
      'DELETE response time < 500ms': (r) => r.timings.duration < 500,
    });

    errorRate.add(!deleteSuccess);
  });
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options = {}) {
  const indent = options.indent || '';
  const colors = options.enableColors;

  let summary = '\n';
  summary += `${indent}Performance Test Results\n`;
  summary += `${indent}========================\n\n`;

  // HTTP request metrics
  const httpReqDuration = data.metrics.http_req_duration;
  if (httpReqDuration) {
    summary += `${indent}HTTP Request Duration:\n`;
    summary += `${indent}  avg: ${httpReqDuration.values.avg.toFixed(2)}ms\n`;
    summary += `${indent}  min: ${httpReqDuration.values.min.toFixed(2)}ms\n`;
    summary += `${indent}  max: ${httpReqDuration.values.max.toFixed(2)}ms\n`;
    summary += `${indent}  p(95): ${httpReqDuration.values['p(95)'].toFixed(2)}ms\n`;
    summary += `${indent}  p(99): ${httpReqDuration.values['p(99)'].toFixed(2)}ms\n\n`;
  }

  // Request rate
  const httpReqs = data.metrics.http_reqs;
  if (httpReqs) {
    summary += `${indent}HTTP Requests: ${httpReqs.values.count}\n`;
    summary += `${indent}Request Rate: ${httpReqs.values.rate.toFixed(2)} req/s\n\n`;
  }

  // Error rate
  const errors = data.metrics.errors;
  if (errors) {
    const errorPct = (errors.values.rate * 100).toFixed(2);
    summary += `${indent}Error Rate: ${errorPct}%\n\n`;
  }

  // Check pass rates
  const checks = data.metrics.checks;
  if (checks) {
    const passPct = (checks.values.rate * 100).toFixed(2);
    summary += `${indent}Checks Passed: ${passPct}%\n`;
    summary += `${indent}  Passed: ${checks.values.passes}\n`;
    summary += `${indent}  Failed: ${checks.values.fails}\n\n`;
  }

  return summary;
}
