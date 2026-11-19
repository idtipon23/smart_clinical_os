import 'package:flutter_test/flutter_test.dart';
import 'package:smart_clinical_os/services/clinical_ai_privacy.dart';

void main() {
  test('clinical payload excludes identifiers and redacts free-text PII', () {
    final context = ClinicalAiPrivacy.sanitizeContext(
      {
        'age': 48,
        'gender': 'female',
        'patient_id': 'patient-secret',
        'hn': 'HN-123456',
        'chief_complaints': 'คุณสมใจ HN: ABC123 โทร 0812345678 เลขบัตรประชาชน 1234567890123 ไอและเหนื่อย',
        'vital_signs': {'blood_pressure': '130/80', 'patient_id': 'secret'},
        'underlying_diseases': [
          ['DM', 'CKD'],
        ],
        'drug_allergies': ['penicillin'],
        'current_medications': ['metformin'],
        'recent_labs': ['HbA1c 8.1%'],
        'new_prescriptions': ['ibuprofen'],
        'unexpected': 'not forwarded',
      },
      identifiers: ['คุณสมใจ', 'ABC123', 'patient-secret'],
    );

    expect(context.keys, [
      'age',
      'gender',
      'vital_signs',
      'chief_complaints',
      'underlying_diseases',
      'drug_allergies',
      'current_medications',
      'recent_labs',
      'new_prescriptions',
    ]);
    expect(context['chief_complaints'], isNot(contains('คุณสมใจ')));
    expect(context['chief_complaints'], isNot(contains('ABC123')));
    expect(context['chief_complaints'], isNot(contains('0812345678')));
    expect(context['chief_complaints'], isNot(contains('1234567890123')));
    expect(context['underlying_diseases'], ['DM', 'CKD']);
    expect(context['vital_signs']['blood_pressure'], '130/80');
  });

  test('medication-safety result is rendered from validated fields', () {
    final result = ClinicalAiPrivacy.sanitizeMedicationSafetyResult({
      'medication_safety_summary': 'โปรดตรวจสอบก่อนสั่ง',
      'alerts': [
        {
          'severity': 'high',
          'medication': 'ibuprofen',
          'concern': 'ประวัติแพ้ยา',
          'reasoning': 'ต้องยืนยันประวัติ',
          'recommendation': 'ตรวจข้อมูลต้นฉบับ',
        },
      ],
      'limitations': ['ไม่มีแหล่งอ้างอิงเฉพาะยา'],
      'patient_name': 'not forwarded',
    });

    expect(result.keys, ['medication_safety_summary', 'alerts', 'limitations']);
    expect(result['alerts'], hasLength(1));
    expect(
      () => ClinicalAiPrivacy.sanitizeMedicationSafetyResult({
        'medication_safety_summary': 'test',
        'alerts': [
          {
            'severity': 'immediate',
            'medication': 'x',
            'concern': 'x',
            'reasoning': 'x',
            'recommendation': 'x',
          },
        ],
        'limitations': [],
      }),
      throwsFormatException,
    );
  });
}
