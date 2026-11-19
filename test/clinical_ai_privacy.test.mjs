import assert from "node:assert/strict";
import test from "node:test";

import {
  clinicalAiSchemas,
  ensureUnknownAllergyAlert,
  normalizeClinicalContext,
  normalizeMedicationSafetyResult,
  normalizeWorkupResult,
} from "../supabase/functions/_shared/clinical_ai.mjs";

test("clinical context uses only allowlisted fields and redacts direct identifiers", () => {
  const context = normalizeClinicalContext(
    {
      age: 48,
      gender: "female",
      patient_name: "must not be forwarded",
      hn: "HN-123456",
      vital_signs: {
        blood_pressure: "130/80",
        pulse: "82",
        patient_id: "must not be forwarded",
      },
      chief_complaints:
        "คุณสมใจ HN: ABC123 โทร 0812345678 เลขบัตรประชาชน 1234567890123 ไอและเหนื่อย",
      underlying_diseases: ["DM"],
      drug_allergies: ["penicillin"],
      current_medications: ["metformin"],
      recent_labs: ["HbA1c 8.1%"],
      new_prescriptions: [],
    },
    ["คุณสมใจ", "ABC123"],
  );

  assert.deepEqual(Object.keys(context), [
    "age",
    "gender",
    "vital_signs",
    "chief_complaints",
    "underlying_diseases",
    "drug_allergies",
    "current_medications",
    "recent_labs",
    "new_prescriptions",
  ]);
  assert.equal(context.vital_signs.blood_pressure, "130/80");
  assert.equal(context.chief_complaints.includes("คุณสมใจ"), false);
  assert.equal(context.chief_complaints.includes("ABC123"), false);
  assert.equal(context.chief_complaints.includes("0812345678"), false);
  assert.equal(context.chief_complaints.includes("1234567890123"), false);
  assert.match(JSON.stringify(context), /ไอและเหนื่อย/);
});

test("workup output is normalized to the required structured schema", () => {
  const result = normalizeWorkupResult({
    red_flags: ["ประเมินหอบเหนื่อยเร่งด่วน"],
    differential_diagnosis: [
      { condition: "Heart failure", reasoning: "มี orthopnea ร่วมกับบวม" },
    ],
    recommended_physical_exams: ["ประเมิน JVP และเสียงปอด"],
    recommended_investigations: ["ECG"],
    ignored_field: "not forwarded",
  });

  assert.deepEqual(Object.keys(result), [
    "red_flags",
    "differential_diagnosis",
    "recommended_physical_exams",
    "recommended_investigations",
  ]);
  assert.equal(result.differential_diagnosis[0].condition, "Heart failure");
  assert.equal(clinicalAiSchemas.workup.required.length, 4);
});

test("medication-safety output rejects unknown severity values", () => {
  assert.throws(() =>
    normalizeMedicationSafetyResult({
      medication_safety_summary: "ตรวจทานรายการยา",
      alerts: [
        {
          severity: "immediate",
          medication: "ibuprofen",
          concern: "allergy",
          reasoning: "test",
          recommendation: "ตรวจสอบ",
        },
      ],
      limitations: [],
    })
  );

  const result = normalizeMedicationSafetyResult({
    medication_safety_summary: "ควรตรวจสอบก่อนสั่ง",
    alerts: [
      {
        severity: "high",
        medication: "ibuprofen",
        concern: "ประวัติแพ้ยา",
        reasoning: "ข้อมูลมีความเสี่ยง",
        recommendation: "ตรวจสอบประวัติแพ้ยา",
      },
    ],
    limitations: ["ยังไม่มีแหล่งอ้างอิงเฉพาะยา"],
  });
  assert.equal(result.alerts[0].severity, "high");
  assert.equal(clinicalAiSchemas.medicationSafety.required.length, 3);
});

test("unknown allergy history always produces a visible safety alert", () => {
  const result = normalizeMedicationSafetyResult({
    medication_safety_summary: "ข้อมูลมีข้อจำกัด",
    alerts: [],
    limitations: ["ยังไม่มีประวัติยืนยัน"],
  });
  const guarded = ensureUnknownAllergyAlert(result, {
    drug_allergies: ["สถานะที่บันทึก: ยังไม่ทราบหรือยังไม่ได้ซักประวัติแพ้ยา"],
  });

  assert.equal(guarded.alerts[0].severity, "unknown");
  assert.match(guarded.alerts[0].concern, /แพ้ยา/);
  assert.match(guarded.medication_safety_summary, /ยังไม่สามารถยืนยัน/);
});
