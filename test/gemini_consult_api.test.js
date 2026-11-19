const assert = require('node:assert/strict');
const test = require('node:test');

const handler = require('../api/gemini-consult');

function responseRecorder() {
  return {
    statusCode: null,
    body: null,
    status(statusCode) {
      this.statusCode = statusCode;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
    setHeader() {},
    end() {
      return this;
    },
  };
}

function withEnvironment(callback) {
  const original = {
    SUPABASE_URL: process.env.SUPABASE_URL,
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY,
    GEMINI_API_KEY: process.env.GEMINI_API_KEY,
  };

  process.env.SUPABASE_URL = 'https://clinic-test.supabase.co';
  process.env.SUPABASE_ANON_KEY = 'test-anon-key';
  process.env.GEMINI_API_KEY = 'test-gemini-key';

  return Promise.resolve()
    .then(callback)
    .finally(() => {
      for (const [key, value] of Object.entries(original)) {
        if (value === undefined) delete process.env[key];
        else process.env[key] = value;
      }
    });
}

test('requires a valid Supabase session before requesting Gemini', async () => {
  await withEnvironment(async () => {
    const originalFetch = global.fetch;
    const calls = [];
    global.fetch = async (url) => {
      calls.push(String(url));
      return { ok: false, status: 401 };
    };

    try {
      const res = responseRecorder();
      await handler(
        { method: 'POST', headers: { authorization: 'Bearer invalid' }, body: {} },
        res,
      );

      assert.equal(res.statusCode, 401);
      assert.equal(calls.length, 1);
      assert.match(calls[0], /\/auth\/v1\/user$/);
    } finally {
      global.fetch = originalFetch;
    }
  });
});

test('uses Gemini 3.5 Flash Lite and forwards only consultation data', async () => {
  await withEnvironment(async () => {
    const originalFetch = global.fetch;
    const calls = [];
    global.fetch = async (url, options) => {
      calls.push({ url: String(url), options });
      if (String(url).endsWith('/auth/v1/user')) {
        return { ok: true, status: 200 };
      }
      return {
        ok: true,
        status: 200,
        json: async () => ({
          candidates: [{ content: { parts: [{ text: 'ตรวจสอบสัญญาณชีพเพิ่มเติม' }] } }],
        }),
      };
    };

    try {
      const res = responseRecorder();
      await handler(
        {
          method: 'POST',
          headers: { authorization: 'Bearer valid-test-token' },
          body: {
            patient_id: 'must-not-be-forwarded',
            consultation: {
              chief_complaint: 'ไอ',
              onset: 'วันนี้',
              symptoms: 'ไอแห้ง',
              medical_history: '',
              medications: '',
              allergies: '',
              observations: { temperature: '37.0' },
              red_flags: [],
              priority: 'routineReview',
            },
          },
        },
        res,
      );

      assert.equal(res.statusCode, 200);
      assert.equal(res.body.model, 'gemini-3.5-flash-lite');
      assert.equal(res.body.recommendation, 'ตรวจสอบสัญญาณชีพเพิ่มเติม');

      const geminiCall = calls[1];
      assert.match(
        geminiCall.url,
        /\/v1beta\/models\/gemini-3\.5-flash-lite:generateContent$/,
      );
      assert.equal(geminiCall.options.headers['x-goog-api-key'], 'test-gemini-key');
      assert.equal(geminiCall.url.includes('test-gemini-key'), false);

      const payload = JSON.parse(geminiCall.options.body);
      const prompt = payload.contents[0].parts[0].text;
      assert.equal(prompt.includes('must-not-be-forwarded'), false);
      assert.equal(prompt.includes('"chief_complaint":"ไอ"'), true);
    } finally {
      global.fetch = originalFetch;
    }
  });
});
