import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/staff_auth_repository.dart';
import '../../../services/general_medical_consult_engine.dart';

class OpdVisitModel {
  final String id;
  final String facilityId;
  final String patientId;
  final String? doctorId;
  final String doctorName;
  final DateTime visitDate;
  final int? sbp;
  final int? dbp;
  final int? pulse;
  final double? temperature;
  final int? respiratoryRate;
  final double? weightKg;
  final double? heightCm;
  final String chiefComplaint;
  final String? presentIllness;
  final String? pastHistory;
  final String? medicationAllergy;
  final String? peGeneral;
  final String? peHeent;
  final String? peHeart;
  final String? peLungs;
  final String? peAbdomen;
  final String? peExtremities;
  final String? peNeuro;
  final String? peOther;
  final String diagnosisText;
  final String? icd10Code;
  final String? treatmentPlan;
  final List<dynamic> prescriptions;
  final String? doctorNotes;
  final String encounterStatus;
  final Map<String, dynamic>? consultationSnapshot;
  final DateTime? closedAt;

  OpdVisitModel({
    required this.id,
    required this.facilityId,
    required this.patientId,
    this.doctorId,
    required this.doctorName,
    required this.visitDate,
    this.sbp,
    this.dbp,
    this.pulse,
    this.temperature,
    this.respiratoryRate,
    this.weightKg,
    this.heightCm,
    required this.chiefComplaint,
    this.presentIllness,
    this.pastHistory,
    this.medicationAllergy,
    this.peGeneral,
    this.peHeent,
    this.peHeart,
    this.peLungs,
    this.peAbdomen,
    this.peExtremities,
    this.peNeuro,
    this.peOther,
    required this.diagnosisText,
    this.icd10Code,
    this.treatmentPlan,
    this.prescriptions = const [],
    this.doctorNotes,
    this.encounterStatus = 'closed',
    this.consultationSnapshot,
    this.closedAt,
  });

  factory OpdVisitModel.fromMap(Map<String, dynamic> map) {
    return OpdVisitModel(
      id: map['id']?.toString() ?? '',
      facilityId: map['facility_id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString(),
      doctorName: map['doctor_name']?.toString() ?? 'แพทย์ผู้ตรวจ',
      visitDate:
          DateTime.tryParse(map['visit_date']?.toString() ?? '') ??
          DateTime.now(),
      sbp: (map['sbp'] as num?)?.toInt(),
      dbp: (map['dbp'] as num?)?.toInt(),
      pulse: (map['pulse'] as num?)?.toInt(),
      temperature: (map['temperature'] as num?)?.toDouble(),
      respiratoryRate: (map['respiratory_rate'] as num?)?.toInt(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      chiefComplaint: map['chief_complaint']?.toString() ?? '',
      presentIllness: map['present_illness']?.toString(),
      pastHistory: map['past_history']?.toString(),
      medicationAllergy: map['medication_allergy']?.toString(),
      peGeneral: map['pe_general']?.toString(),
      peHeent: map['pe_heent']?.toString(),
      peHeart: map['pe_heart']?.toString(),
      peLungs: map['pe_lungs']?.toString(),
      peAbdomen: map['pe_abdomen']?.toString(),
      peExtremities: map['pe_extremities']?.toString(),
      peNeuro: map['pe_neuro']?.toString(),
      peOther: map['pe_other']?.toString(),
      diagnosisText: map['diagnosis_text']?.toString() ?? '',
      icd10Code: map['icd10_code']?.toString(),
      treatmentPlan: map['treatment_plan']?.toString(),
      prescriptions: map['prescriptions'] is List
          ? map['prescriptions']
          : const [],
      doctorNotes: map['doctor_notes']?.toString(),
      encounterStatus: map['encounter_status']?.toString() ?? 'closed',
      consultationSnapshot: map['consultation_snapshot'] is Map
          ? Map<String, dynamic>.from(map['consultation_snapshot'] as Map)
          : null,
      closedAt: DateTime.tryParse(map['closed_at']?.toString() ?? ''),
    );
  }
}

final opdVisitRepositoryProvider = Provider<OpdVisitRepository>((ref) {
  return OpdVisitRepository(Supabase.instance.client, ref);
});

final patientOpdVisitsProvider = FutureProvider.autoDispose
    .family<List<OpdVisitModel>, String>((ref, patientId) async {
      final repo = ref.watch(opdVisitRepositoryProvider);
      return repo.fetchPatientVisits(patientId);
    });

class OpdVisitRepository {
  final SupabaseClient _client;
  final Ref _ref;

  OpdVisitRepository(this._client, this._ref);

  Future<List<OpdVisitModel>> fetchPatientVisits(String patientId) async {
    try {
      final res = await _client
          .from('opd_visits')
          .select()
          .eq('patient_id', patientId)
          .order('visit_date', ascending: false);

      return (res as List<dynamic>)
          .map((item) => OpdVisitModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Fetch OPD Visits error: $e');
      return [];
    }
  }

  Future<OpdVisitModel> createOpenConsultationEncounter({
    required String patientId,
    required GeneralMedicalConsultInput input,
    required GeneralMedicalConsultResult assessment,
  }) async {
    final staffProfile = await _ref.read(currentStaffProfileProvider.future);
    final facilityId = staffProfile?.facilityId.trim();
    if (facilityId == null || facilityId.isEmpty) {
      throw StateError('ไม่พบหน่วยบริการของเจ้าหน้าที่ที่เข้าสู่ระบบ');
    }
    final doctorId = _client.auth.currentUser?.id;
    final doctorName = staffProfile?.fullName ?? 'แพทย์ผู้ตรวจ';
    final bloodPressure = (input.observations['blood_pressure'] ?? '').split(
      '/',
    );
    final systolic = bloodPressure.isNotEmpty
        ? int.tryParse(bloodPressure[0].trim())
        : null;
    final diastolic = bloodPressure.length > 1
        ? int.tryParse(bloodPressure[1].trim())
        : null;
    final snapshot = {
      'consult_type': 'general_medical',
      'chief_complaint': input.chiefComplaint.trim(),
      'onset': input.onset.trim(),
      'symptoms': input.symptoms.trim(),
      'medical_history': input.medicalHistory.trim(),
      'medications': input.medications.trim(),
      'allergies': input.allergies.trim(),
      'observations': input.observations,
      'red_flags': input.redFlags.toList(),
      'priority': assessment.priority.name,
      'missing_information': assessment.missingInformation,
      'next_steps': assessment.nextSteps,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    final presentIllness = [
      if (input.onset.trim().isNotEmpty) 'เริ่มมีอาการ: ${input.onset.trim()}',
      if (input.symptoms.trim().isNotEmpty) input.symptoms.trim(),
    ].join('\n');

    final row = await _client
        .from('opd_visits')
        .insert({
          'facility_id': facilityId,
          'patient_id': patientId,
          'doctor_id': doctorId,
          'doctor_name': doctorName,
          'visit_date': DateTime.now().toUtc().toIso8601String(),
          'sbp': systolic,
          'dbp': diastolic,
          'pulse': int.tryParse(input.observations['pulse'] ?? ''),
          'temperature': double.tryParse(
            input.observations['temperature'] ?? '',
          ),
          'respiratory_rate': int.tryParse(
            input.observations['respiratory_rate'] ?? '',
          ),
          'weight_kg': double.tryParse(input.observations['weight'] ?? ''),
          'height_cm': double.tryParse(input.observations['height'] ?? ''),
          'chief_complaint': input.chiefComplaint.trim(),
          'present_illness': presentIllness,
          'past_history': input.medicalHistory.trim(),
          'medication_allergy': input.allergies.trim(),
          'pe_general': 'ยังไม่ได้ตรวจ',
          'pe_heent': 'ยังไม่ได้ตรวจ',
          'pe_heart': 'ยังไม่ได้ตรวจ',
          'pe_lungs': 'ยังไม่ได้ตรวจ',
          'pe_abdomen': 'ยังไม่ได้ตรวจ',
          'pe_extremities': 'ยังไม่ได้ตรวจ',
          'diagnosis_text': 'รอการตรวจประเมิน',
          'prescriptions': <Map<String, dynamic>>[],
          'consultation_snapshot': snapshot,
          'encounter_status': 'open',
          'closed_at': null,
        })
        .select()
        .single();

    return OpdVisitModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> saveOpdVisit({
    String? encounterId,
    bool closeEncounter = false,
    Map<String, dynamic>? consultationSnapshot,
    required String patientId,
    int? sbp,
    int? dbp,
    int? pulse,
    double? temperature,
    int? respiratoryRate,
    double? weightKg,
    double? heightCm,
    required String chiefComplaint,
    String? presentIllness,
    String? pastHistory,
    String? medicationAllergy,
    String? peGeneral,
    String? peHeent,
    String? peHeart,
    String? peLungs,
    String? peAbdomen,
    String? peExtremities,
    String? peNeuro,
    String? peOther,
    required String diagnosisText,
    String? icd10Code,
    String? treatmentPlan,
    List<Map<String, dynamic>> prescriptions = const [],
    String? doctorNotes,
  }) async {
    final staffProfile = await _ref.read(currentStaffProfileProvider.future);
    final facilityId = staffProfile?.facilityId.trim();
    if (facilityId == null || facilityId.isEmpty) {
      throw StateError('ไม่พบหน่วยบริการของเจ้าหน้าที่ที่เข้าสู่ระบบ');
    }
    final doctorId = _client.auth.currentUser?.id;
    final doctorName = staffProfile?.fullName ?? 'แพทย์ผู้ตรวจ';
    final now = DateTime.now().toUtc();

    final visitData = <String, dynamic>{
      'facility_id': facilityId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'sbp': sbp,
      'dbp': dbp,
      'pulse': pulse,
      'temperature': temperature,
      'respiratory_rate': respiratoryRate,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'chief_complaint': chiefComplaint.trim(),
      'present_illness': presentIllness?.trim().isNotEmpty == true
          ? presentIllness!.trim()
          : null,
      'past_history': pastHistory?.trim().isNotEmpty == true
          ? pastHistory!.trim()
          : null,
      'medication_allergy': medicationAllergy?.trim().isNotEmpty == true
          ? medicationAllergy!.trim()
          : null,
      'pe_general': peGeneral?.trim().isNotEmpty == true
          ? peGeneral!.trim()
          : null,
      'pe_heent': peHeent?.trim().isNotEmpty == true ? peHeent!.trim() : null,
      'pe_heart': peHeart?.trim().isNotEmpty == true ? peHeart!.trim() : null,
      'pe_lungs': peLungs?.trim().isNotEmpty == true ? peLungs!.trim() : null,
      'pe_abdomen': peAbdomen?.trim().isNotEmpty == true
          ? peAbdomen!.trim()
          : null,
      'pe_extremities': peExtremities?.trim().isNotEmpty == true
          ? peExtremities!.trim()
          : null,
      'pe_neuro': peNeuro?.trim().isNotEmpty == true ? peNeuro!.trim() : null,
      'pe_other': peOther?.trim().isNotEmpty == true ? peOther!.trim() : null,
      'diagnosis_text': diagnosisText.trim(),
      'icd10_code': icd10Code?.trim().isNotEmpty == true
          ? icd10Code!.trim()
          : null,
      'treatment_plan': treatmentPlan?.trim().isNotEmpty == true
          ? treatmentPlan!.trim()
          : null,
      'prescriptions': prescriptions,
      'doctor_notes': doctorNotes?.trim().isNotEmpty == true
          ? doctorNotes!.trim()
          : null,
      'encounter_status': closeEncounter ? 'closed' : 'open',
      'closed_at': closeEncounter ? now.toIso8601String() : null,
    };
    if (consultationSnapshot != null) {
      visitData['consultation_snapshot'] = consultationSnapshot;
    }
    if (encounterId == null) {
      visitData['visit_date'] = now.toIso8601String();
    }

    final savedVisit = encounterId == null
        ? await _client.from('opd_visits').insert(visitData).select().single()
        : await _client
              .from('opd_visits')
              .update(visitData)
              .eq('id', encounterId)
              .select()
              .single();

    if (encounterId == null) {
      final noteSummary =
          'ตรวจรักษา (OPD Visit) โดย $doctorName: Dx: $diagnosisText ${icd10Code != null ? '($icd10Code)' : ''} | CC: $chiefComplaint';
      await _client.from('staff_notes').insert({
        'patient_id': patientId,
        'staff_name': doctorName,
        'note_text': noteSummary,
        'created_at': now.toIso8601String(),
      });
    }

    return savedVisit['id'].toString();
  }
}
