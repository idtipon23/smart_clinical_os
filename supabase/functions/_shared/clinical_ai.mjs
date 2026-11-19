const VITAL_FIELDS = [
  "blood_pressure",
  "pulse",
  "temperature",
  "respiratory_rate",
  "oxygen_saturation",
  "weight",
  "height",
];

const MAX_FIELD_LENGTH = 3000;
const MAX_TOTAL_LENGTH = 16000;

const WORKUP_SCHEMA = {
  type: "OBJECT",
  properties: {
    red_flags: { type: "ARRAY", items: { type: "STRING" } },
    differential_diagnosis: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          condition: { type: "STRING" },
          reasoning: { type: "STRING" },
        },
        required: ["condition", "reasoning"],
      },
    },
    recommended_physical_exams: {
      type: "ARRAY",
      items: { type: "STRING" },
    },
    recommended_investigations: {
      type: "ARRAY",
      items: { type: "STRING" },
    },
  },
  required: [
    "red_flags",
    "differential_diagnosis",
    "recommended_physical_exams",
    "recommended_investigations",
  ],
};

const MEDICATION_SAFETY_SCHEMA = {
  type: "OBJECT",
  properties: {
    medication_safety_summary: { type: "STRING" },
    alerts: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          severity: {
            type: "STRING",
            enum: ["critical", "high", "moderate", "low", "unknown"],
          },
          medication: { type: "STRING" },
          concern: { type: "STRING" },
          reasoning: { type: "STRING" },
          recommendation: { type: "STRING" },
        },
        required: [
          "severity",
          "medication",
          "concern",
          "reasoning",
          "recommendation",
        ],
      },
    },
    limitations: { type: "ARRAY", items: { type: "STRING" } },
  },
  required: ["medication_safety_summary", "alerts", "limitations"],
};

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function redactKnownIdentifiers(text, identifiers) {
  let result = text;
  for (const identifier of identifiers) {
    const value = String(identifier ?? "").trim();
    if (value.length < 3) continue;
    result = result.replace(
      new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "gi"),
      "[REDACTED]",
    );
  }
  return result;
}

export function sanitizeText(
  value,
  identifiers = [],
  maxLength = MAX_FIELD_LENGTH,
) {
  if (value === undefined || value === null) return "";
  if (typeof value !== "string" && typeof value !== "number") {
    throw new Error("Invalid clinical text");
  }

  let text = redactKnownIdentifiers(String(value).trim(), identifiers);
  text = text
    .replace(
      /(^|[^\d])(?:\d[\s-]?){13}(?!\d)/g,
      "$1[REDACTED_ID]",
    )
    .replace(
      /(^|[^\d])(?:\+?66|0)[\s().-]*(?:\d[\s().-]*){8,10}(?!\d)/gi,
      "$1[REDACTED_PHONE]",
    )
    .replace(
      /\b(?:HN|MRN|patient\s*(?:id|number)|hospital\s*(?:id|number))\s*[:#-]?\s*[A-Z0-9][A-Z0-9/-]{2,}/gi,
      "[REDACTED_HN]",
    )
    .replace(
      /(?:เลขบัตรประชาชน|เลขประจำตัวประชาชน|เลขประจำตัวผู้ป่วย)\s*[:：]?\s*[\d -]{8,}/gi,
      "[REDACTED_ID]",
    )
    .replace(
      /(?:เบอร์โทร(?:ศัพท์)?|โทรศัพท์|phone)\s*[:：]?\s*[\d\s()+.-]{8,}/gi,
      "[REDACTED_PHONE]",
    )
    .replace(
      /(?:ชื่อผู้ป่วย|ผู้ป่วยชื่อ|ที่อยู่|address|บ้านเลขที่|หมู่ที่|ซอย|ถนน|ตำบล|อำเภอ|จังหวัด|แขวง|เขต)\s*[:：]?\s*[^,;\n]+/gi,
      "[REDACTED_PII]",
    )
    .replace(
      /(?:^|[\s,;])(?:name|patient name)\s*[:：]?\s*[^,;\n]+/gi,
      " [REDACTED_NAME]",
    )
    .trim();

  if (text.length > maxLength) throw new Error("Clinical field is too long");
  return text;
}

function normalizeStringList(value, field, identifiers) {
  if (value === undefined || value === null || value === "") return [];
  const values = Array.isArray(value) ? value : [value];
  if (values.length > 30) throw new Error(`Invalid ${field}`);
  return values
    .map((item) => sanitizeText(item, identifiers))
    .filter(Boolean);
}

export function normalizeClinicalContext(value, identifiers = []) {
  if (!isRecord(value)) throw new Error("Invalid clinical context");
  if (!isRecord(value.vital_signs ?? {})) {
    throw new Error("Invalid vital signs");
  }

  const vitalSigns = Object.fromEntries(
    VITAL_FIELDS.map((field) => [
      field,
      sanitizeText(value.vital_signs?.[field], identifiers, 100),
    ]),
  );
  const context = {
    age: sanitizeText(value.age, identifiers, 30),
    gender: sanitizeText(value.gender, identifiers, 40),
    vital_signs: vitalSigns,
    chief_complaints: sanitizeText(value.chief_complaints, identifiers),
    underlying_diseases: normalizeStringList(
      value.underlying_diseases,
      "underlying diseases",
      identifiers,
    ),
    drug_allergies: normalizeStringList(
      value.drug_allergies,
      "drug allergies",
      identifiers,
    ),
    current_medications: normalizeStringList(
      value.current_medications,
      "current medications",
      identifiers,
    ),
    recent_labs: normalizeStringList(
      value.recent_labs,
      "recent labs",
      identifiers,
    ),
    new_prescriptions: normalizeStringList(
      value.new_prescriptions,
      "new prescriptions",
      identifiers,
    ),
  };

  const totalLength = JSON.stringify(context).length;
  if (totalLength > MAX_TOTAL_LENGTH) {
    throw new Error("Clinical context is too large");
  }
  return context;
}

function cleanOutputText(value) {
  if (typeof value !== "string" || value.length > MAX_FIELD_LENGTH) {
    throw new Error("Invalid Gemini output");
  }
  return sanitizeText(value);
}

function cleanOutputList(value) {
  if (!Array.isArray(value) || value.length > 30) {
    throw new Error("Invalid Gemini output");
  }
  return value.map(cleanOutputText);
}

export function normalizeWorkupResult(value) {
  if (!isRecord(value) || !Array.isArray(value.differential_diagnosis)) {
    throw new Error("Invalid workup result");
  }
  if (value.differential_diagnosis.length > 15) {
    throw new Error("Invalid workup result");
  }
  return {
    red_flags: cleanOutputList(value.red_flags),
    differential_diagnosis: value.differential_diagnosis.map((item) => {
      if (!isRecord(item)) throw new Error("Invalid workup result");
      return {
        condition: cleanOutputText(item.condition),
        reasoning: cleanOutputText(item.reasoning),
      };
    }),
    recommended_physical_exams: cleanOutputList(
      value.recommended_physical_exams,
    ),
    recommended_investigations: cleanOutputList(
      value.recommended_investigations,
    ),
  };
}

export function normalizeMedicationSafetyResult(value) {
  if (!isRecord(value)) throw new Error("Invalid medication safety result");
  if (!Array.isArray(value.alerts) || value.alerts.length > 30) {
    throw new Error("Invalid medication safety result");
  }
  const allowedSeverities = new Set([
    "critical",
    "high",
    "moderate",
    "low",
    "unknown",
  ]);
  return {
    medication_safety_summary: cleanOutputText(
      value.medication_safety_summary,
    ),
    alerts: value.alerts.map((item) => {
      if (!isRecord(item) || !allowedSeverities.has(item.severity)) {
        throw new Error("Invalid medication safety result");
      }
      return {
        severity: item.severity,
        medication: cleanOutputText(item.medication),
        concern: cleanOutputText(item.concern),
        reasoning: cleanOutputText(item.reasoning),
        recommendation: cleanOutputText(item.recommendation),
      };
    }),
    limitations: cleanOutputList(value.limitations),
  };
}

export function ensureUnknownAllergyAlert(result, context) {
  const allergyStatusUnknown = context.drug_allergies.some((item) =>
    /unknown|ยังไม่ทราบ|ยังไม่ได้ซักประวัติ/i.test(item)
  );
  if (!allergyStatusUnknown) return result;

  const hasAllergyAlert = result.alerts.some((alert) =>
    /allerg|แพ้ยา|cross/i.test(`${alert.concern} ${alert.reasoning}`)
  );
  if (hasAllergyAlert) return result;

  return {
    ...result,
    medication_safety_summary:
      `ยังไม่สามารถยืนยันความปลอดภัยด้านการแพ้ยาได้: ${result.medication_safety_summary}`
        .slice(
          0,
          MAX_FIELD_LENGTH,
        ),
    alerts: [
      {
        severity: "unknown",
        medication: "รายการยาที่สั่ง",
        concern: "ยังไม่ทราบประวัติแพ้ยา",
        reasoning:
          "ข้อมูลผู้ป่วยระบุว่ายังไม่ได้ยืนยันประวัติแพ้ยา จึงประเมิน cross-allergy ไม่ครบ",
        recommendation: "ตรวจสอบประวัติแพ้ยาและการแพ้ข้ามกลุ่มกับผู้ป่วย/ผู้ดูแลก่อนสั่งจ่าย",
      },
      ...result.alerts,
    ].slice(0, 30),
  };
}

export const clinicalAiSchemas = {
  workup: WORKUP_SCHEMA,
  medicationSafety: MEDICATION_SAFETY_SCHEMA,
};
