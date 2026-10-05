import assert from 'node:assert/strict';
import test from 'node:test';
import analyze, { config } from '../../netlify/functions/analyze.mjs';

const url = 'https://example.test/api/analyze';
const request = (body) => new Request(url, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body),
});

test('rejects malformed requests before reaching Gemini', async () => {
  const response = await analyze(request({ kind: 'livestock', images: [] }));
  assert.equal(response.status, 400);
  assert.deepEqual(config.rateLimit.aggregateBy, ['ip', 'domain']);
});

test('forwards three labeled photos through the server without exposing its key', async () => {
  const previousKey = process.env.GEMINI_API_KEY;
  const previousBase = process.env.GOOGLE_GEMINI_BASE_URL;
  const previousFetch = globalThis.fetch;
  process.env.GEMINI_API_KEY = 'server-only-test-key';
  process.env.GOOGLE_GEMINI_BASE_URL = 'https://gateway.test';
  let calls = 0;
  globalThis.fetch = async (target, options) => {
    calls++;
    assert.match(target, /gemini-3\.8-flash:generateContent$/);
    assert.equal(options.headers['x-goog-api-key'], 'server-only-test-key');
    const body = JSON.parse(options.body);
    assert.equal(body.contents[0].parts.filter((part) => part.inline_data).length, 3);
    assert.deepEqual(body.contents[0].parts.filter((part) => part.text)
      .slice(-3).map((part) => part.text), ['ÖNDEN', 'YANDAN', 'ARKADAN']);
    return Response.json({ candidates: [{ content: { parts: [{ text: '{"weight":520}' }] } }] });
  };
  try {
    const image = 'data:image/jpeg;base64,/9j/2Q==';
    const response = await analyze(request({
      kind: 'livestock', prompt: 'Canlı ağırlık tahmini yap.', images: [image, image, image],
    }));
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { text: '{"weight":520}' });
    assert.equal(calls, 1);
  } finally {
    globalThis.fetch = previousFetch;
    if (previousKey === undefined) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = previousKey;
    if (previousBase === undefined) delete process.env.GOOGLE_GEMINI_BASE_URL;
    else process.env.GOOGLE_GEMINI_BASE_URL = previousBase;
  }
});
