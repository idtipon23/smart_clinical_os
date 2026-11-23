import { normalizeClinicalContext } from "./clinical_ai.mjs";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
  "Content-Type": "application/json; charset=utf-8",
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

async function authenticateRequest(
  authorization: string,
  supabaseUrl: string,
  anonKey: string,
) {
  const response = await fetch(
    `${supabaseUrl.replace(/\/$/, "")}/auth/v1/user`,
    {
      headers: {
        apikey: anonKey,
        Authorization: authorization,
      },
      signal: AbortSignal.timeout(10000),
    },
  );
  return response.ok;
}

export async function handleClinicalAiRequest(
  request: Request,
  options: {
    systemInstruction: string;
    responseSchema: Record<string, unknown>;
    normalizeResult: (
      value: unknown,
      context: ReturnType<typeof normalizeClinicalContext>,
    ) => Record<string, unknown>;
    validateContext: (
      context: ReturnType<typeof normalizeClinicalContext>,
    ) => string | null;
  },
) {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "กรุณาเข้าสู่ระบบใหม่" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  const configuredModel = Deno.env.get("GEMINI_MODEL")?.trim();
  const model = configuredModel || "gemini-2.5-flash";
  if (
    !supabaseUrl ||
    !anonKey ||
    !apiKey ||
    !/^gemini-[a-zA-Z0-9.-]+$/.test(model)
  ) {
    return jsonResponse(500, { error: "บริการ AI ยังตั้งค่าไม่ครบ" });
  }

  try {
    if (!(await authenticateRequest(authorization, supabaseUrl, anonKey))) {
      return jsonResponse(401, { error: "กรุณาเข้าสู่ระบบใหม่" });
    }

    const bodyText = await request.text();
    if (new TextEncoder().encode(bodyText).length > 32000) {
      return jsonResponse(413, { error: "ข้อมูลมีขนาดใหญ่เกินกำหนด" });
    }

    let body: Record<string, unknown>;
    try {
      const parsed = JSON.parse(bodyText);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
        return jsonResponse(400, { error: "รูปแบบคำขอไม่ถูกต้อง" });
      }
      body = parsed as Record<string, unknown>;
    } catch {
      return jsonResponse(400, { error: "รูปแบบคำขอไม่ถูกต้อง" });
    }

    let clinicalContext: ReturnType<typeof normalizeClinicalContext>;
    try {
      clinicalContext = normalizeClinicalContext(body.clinical_context);
    } catch {
      return jsonResponse(400, { error: "ข้อมูลทางคลินิกไม่ถูกต้อง" });
    }
    const contextError = options.validateContext(clinicalContext);
    if (contextError) return jsonResponse(400, { error: contextError });

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 35000);
    let geminiResponse: Response;
    try {
      geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": apiKey,
          },
          body: JSON.stringify({
            systemInstruction: {
              parts: [{ text: options.systemInstruction }],
            },
            contents: [
              {
                role: "user",
                parts: [{ text: JSON.stringify(clinicalContext) }],
              },
            ],
            generationConfig: {
              temperature: 0.1,
              // ภาษาไทยใช้ token เยอะ + Gemini 2.5 นับ "thinking" รวมใน
              // maxOutputTokens ทำให้ JSON ถูกตัดกลางคัน -> parse ไม่ได้ -> 502
              maxOutputTokens: 4096,
              responseMimeType: "application/json",
              responseSchema: options.responseSchema,
              ...(/^gemini-2\.5-flash/.test(model)
                ? { thinkingConfig: { thinkingBudget: 0 } }
                : {}),
            },
          }),
          signal: controller.signal,
        },
      );
    } finally {
      clearTimeout(timeout);
    }

    if (!geminiResponse.ok) {
      const errText = (await geminiResponse.text().catch(() => "")).slice(0, 800);
      console.error("Gemini HTTP error", geminiResponse.status, model, errText);
      return jsonResponse(502, {
        error: "Gemini ไม่สามารถประมวลผลได้ในขณะนี้",
        gemini_status: geminiResponse.status,
      });
    }

    let result: unknown;
    let responseBody: any;
    try {
      responseBody = await geminiResponse.json();
      const text = responseBody.candidates?.[0]?.content?.parts
        ?.map((part: { text?: string }) => part.text ?? "")
        .join("")
        .trim();
      if (!text) throw new Error("Empty Gemini response");
      result = options.normalizeResult(JSON.parse(text), clinicalContext);
    } catch (err) {
      console.error(
        "Gemini output invalid:",
        String(err),
        "finishReason=",
        responseBody?.candidates?.[0]?.finishReason,
        "blockReason=",
        responseBody?.promptFeedback?.blockReason,
        "usage=",
        JSON.stringify(responseBody?.usageMetadata ?? {}),
      );
      return jsonResponse(502, {
        error: "Gemini ส่งผลลัพธ์ไม่ครบหรือไม่ถูกต้อง",
        finish_reason: responseBody?.candidates?.[0]?.finishReason ?? null,
      });
    }

    return jsonResponse(200, { model, result });
  } catch (err) {
    console.error("Unhandled edge error:", String(err));
    return jsonResponse(502, { error: "ไม่สามารถเชื่อมต่อบริการ Gemini ได้" });
  }
}