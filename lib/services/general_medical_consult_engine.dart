enum ConsultPriority { emergency, promptReview, routineReview }

class GeneralMedicalConsultInput {
  final String chiefComplaint;
  final String onset;
  final String symptoms;
  final String medicalHistory;
  final String medications;
  final String allergies;
  final Map<String, String> observations;
  final Set<String> redFlags;

  const GeneralMedicalConsultInput({
    required this.chiefComplaint,
    required this.onset,
    required this.symptoms,
    required this.medicalHistory,
    required this.medications,
    required this.allergies,
    required this.observations,
    required this.redFlags,
  });
}

class GeneralMedicalConsultResult {
  final ConsultPriority priority;
  final List<String> safetyAlerts;
  final List<String> missingInformation;
  final List<String> nextSteps;

  const GeneralMedicalConsultResult({
    required this.priority,
    required this.safetyAlerts,
    required this.missingInformation,
    required this.nextSteps,
  });
}

class GeneralMedicalConsultEngine {
  static const redFlagLabels = <String>[
    'เจ็บหน้าอกรุนแรงหรือแน่นหน้าอก',
    'หายใจลำบากรุนแรง',
    'หมดสติหรือสับสนเฉียบพลัน',
    'หน้าเบี้ยว แขนขาอ่อนแรง หรือพูดไม่ชัด',
    'เลือดออกมากหรือหยุดยาก',
    'หน้าบวม/ลิ้นบวม หรือสงสัยแพ้รุนแรง',
    'ปวดท้องรุนแรงหรืออาการทรุดเร็ว',
  ];

  static GeneralMedicalConsultResult evaluate(
    GeneralMedicalConsultInput input,
  ) {
    final safetyAlerts = <String>[];
    final missingInformation = <String>[];
    final nextSteps = <String>[];

    if (input.redFlags.isNotEmpty) {
      safetyAlerts.add(
        'พบอาการเตือนที่เลือกไว้: ${input.redFlags.join(', ')}',
      );
    }

    if (input.chiefComplaint.trim().isEmpty) {
      missingInformation.add('อาการสำคัญ');
    }
    if (input.onset.trim().isEmpty) {
      missingInformation.add('วัน/เวลาที่เริ่มมีอาการ');
    }
    if (input.symptoms.trim().isEmpty) {
      missingInformation.add('รายละเอียดอาการและอาการร่วม');
    }
    if (input.medicalHistory.trim().isEmpty) {
      missingInformation.add('ประวัติโรคประจำตัว');
    }
    if (input.medications.trim().isEmpty) {
      missingInformation.add('ยาที่ใช้อยู่');
    }
    if (input.allergies.trim().isEmpty) {
      missingInformation.add('ประวัติแพ้ยา/แพ้อาหาร');
    }
    if (input.observations.values.every((value) => value.trim().isEmpty)) {
      missingInformation.add('สัญญาณชีพ/ผลตรวจที่เกี่ยวข้อง');
    }

    if (input.redFlags.isNotEmpty) {
      nextSteps.add('ส่งประเมินฉุกเฉินทันทีตามแนวทางของหน่วยบริการ');
      nextSteps.add('บันทึกเวลาที่เริ่มอาการและการดูแลเบื้องต้น');
    } else {
      nextSteps.add('ให้แพทย์หรือบุคลากรผู้รับผิดชอบประเมินอาการและตรวจร่างกาย');
      nextSteps.add('ทบทวนสัญญาณชีพ ประวัติแพ้ยา ยาที่ใช้อยู่ และผลตรวจที่เกี่ยวข้อง');
    }

    if (missingInformation.isNotEmpty) {
      nextSteps.add('เก็บข้อมูลเพิ่มเติม: ${missingInformation.join(', ')}');
    }

    return GeneralMedicalConsultResult(
      priority: input.redFlags.isNotEmpty
          ? ConsultPriority.emergency
          : missingInformation.isNotEmpty
          ? ConsultPriority.promptReview
          : ConsultPriority.routineReview,
      safetyAlerts: safetyAlerts,
      missingInformation: missingInformation,
      nextSteps: nextSteps,
    );
  }
}
