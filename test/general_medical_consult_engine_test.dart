import 'package:flutter_test/flutter_test.dart';
import 'package:smart_clinical_os/services/general_medical_consult_engine.dart';

void main() {
  group('GeneralMedicalConsultEngine', () {
    GeneralMedicalConsultInput input({
      String chiefComplaint = 'ปวดท้อง',
      Set<String> redFlags = const {},
      Map<String, String> observations = const {'temperature': '37.0'},
    }) {
      return GeneralMedicalConsultInput(
        chiefComplaint: chiefComplaint,
        onset: 'วันนี้',
        symptoms: 'ปวดท้องหลังรับประทานอาหาร',
        medicalHistory: 'ไม่มีข้อมูล',
        medications: 'ไม่มีข้อมูล',
        allergies: 'ไม่มีข้อมูล',
        observations: observations,
        redFlags: redFlags,
      );
    }

    test('escalates selected red flags without generating a diagnosis', () {
      final result = GeneralMedicalConsultEngine.evaluate(
        input(redFlags: {'หายใจลำบากรุนแรง'}),
      );

      expect(result.priority, ConsultPriority.emergency);
      expect(result.safetyAlerts, isNotEmpty);
      expect(result.nextSteps.first, contains('ฉุกเฉิน'));
    });

    test(
      'flags missing consultation information without assuming an emergency',
      () {
        final result = GeneralMedicalConsultEngine.evaluate(
          input(chiefComplaint: '', observations: const {}),
        );

        expect(result.priority, ConsultPriority.promptReview);
        expect(result.missingInformation, contains('อาการสำคัญ'));
        expect(
          result.missingInformation,
          contains('สัญญาณชีพ/ผลตรวจที่เกี่ยวข้อง'),
        );
        expect(result.safetyAlerts, isEmpty);
      },
    );
  });
}
