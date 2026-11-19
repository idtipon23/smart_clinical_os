import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _withoutNullValues(Map<String, dynamic> values) {
  return Map<String, dynamic>.from(values)
    ..removeWhere((_, value) => value == null);
}

final clinicalEntryRepositoryProvider = Provider<ClinicalEntryRepository>((
  ref,
) {
  return ClinicalEntryRepository(Supabase.instance.client);
});

final patientLabHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      patientId,
    ) async {
      final response = await Supabase.instance.client
          .from('lab_results')
          .select('*')
          .eq('patient_id', patientId)
          .order('lab_date', ascending: false)
          .order('test_date', ascending: false, nullsFirst: false);

      return List<Map<String, dynamic>>.from(response);
    });

class EncounterClinicalResults {
  final List<Map<String, dynamic>> vitalSigns;
  final List<Map<String, dynamic>> labResults;

  const EncounterClinicalResults({
    required this.vitalSigns,
    required this.labResults,
  });

  bool get isEmpty => vitalSigns.isEmpty && labResults.isEmpty;
}

final encounterClinicalResultsProvider = FutureProvider.autoDispose
    .family<EncounterClinicalResults, String>((ref, encounterId) async {
      return ref
          .watch(clinicalEntryRepositoryProvider)
          .fetchEncounterResults(encounterId);
    });

class ClinicalEntryRepository {
  final SupabaseClient _client;
  ClinicalEntryRepository(this._client);

  Future<EncounterClinicalResults> fetchEncounterResults(
    String encounterId,
  ) async {
    final vitalSigns = await _client
        .from('vital_signs')
        .select('*')
        .eq('opd_visit_id', encounterId)
        .order('recorded_at', ascending: false);
    final labResults = await _client
        .from('lab_results')
        .select('*')
        .eq('opd_visit_id', encounterId)
        .order('lab_date', ascending: false);

    return EncounterClinicalResults(
      vitalSigns: List<Map<String, dynamic>>.from(vitalSigns),
      labResults: List<Map<String, dynamic>>.from(labResults),
    );
  }

  Future<void> _requireOpenEncounter(
    String encounterId,
    String patientId,
  ) async {
    final encounter = await _client
        .from('opd_visits')
        .select('patient_id, encounter_status')
        .eq('id', encounterId)
        .single();

    if (encounter['patient_id']?.toString() != patientId) {
      throw StateError('OPD encounter does not belong to this patient.');
    }
    if (encounter['encounter_status'] != 'open') {
      throw StateError(
        'Clinical results can only be added to an open encounter.',
      );
    }
  }

  /// 1. บันทึกสัญญาณชีพและอาการ (V/S & Symptoms)
  Future<void> saveVitalSigns({
    required String encounterId,
    required String patientId,
    required int systolic,
    required int diastolic,
    required int pulse,
    double? temperature,
    int? respiratoryRate,
    double? weightKg,
    double? heightCm,
    String? symptomsOrFeedback,
  }) async {
    await _requireOpenEncounter(encounterId, patientId);

    final user = _client.auth.currentUser;
    final staffName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email ??
        'เจ้าหน้าที่คลินิก';

    // คำนวณระดับความเร่งด่วนตามเกณฑ์ Triage
    String urgency = 'NORMAL';
    if (systolic >= 180 || diastolic >= 110) {
      urgency = 'CRITICAL';
    } else if ((systolic > 0 && systolic < 100) ||
        (diastolic > 0 && diastolic < 60)) {
      urgency = 'WARNING';
    } else if (systolic >= 140 || diastolic >= 90) {
      urgency = 'WARNING';
    }

    await _client.from('vital_signs').insert({
      'opd_visit_id': encounterId,
      'patient_id': patientId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'temperature': temperature,
      'respiratory_rate': respiratoryRate,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'spoken_feedback': symptomsOrFeedback,
      'urgency_level': urgency,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    });

    final vitalSummary =
        'บันทึก V/S: $systolic/$diastolic mmHg, ชีพจร $pulse bpm'
        '${temperature != null ? ', T $temperature°C' : ''}'
        '${symptomsOrFeedback != null && symptomsOrFeedback.isNotEmpty ? ' | อาการ: $symptomsOrFeedback' : ''}';

    await _client.from('staff_notes').insert({
      'opd_visit_id': encounterId,
      'patient_id': patientId,
      'staff_name': staffName,
      'note_text': vitalSummary,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// 2. บันทึกผลแล็บครบวงจร (Comprehensive Lab Results)
  Future<void> saveLabResults({
    required String encounterId,
    required String patientId,
    required DateTime labDate,
    // Glycemic
    double? fbs,
    double? hba1c,
    // Lipid Profile
    double? totalCholesterol,
    double? triglycerides,
    double? hdl,
    double? ldl,
    // Renal & Electrolytes
    double? bun,
    double? creatinine,
    double? egfr,
    double? sodium,
    double? potassium,
    double? chloride,
    double? bicarbonate,
    // Liver Function & Metabolic
    double? ast,
    double? alt,
    double? alp,
    double? uricAcid,
    // Urine Tests
    double? urineMicroalbumin,
    String? urineProtein,
    // Interpretation & Attachments
    String? interpretation,
    String? imageUrl,
  }) async {
    await _requireOpenEncounter(encounterId, patientId);

    final user = _client.auth.currentUser;
    final staffName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email ??
        'เจ้าหน้าที่ชันสูตร';

    final payload = _withoutNullValues({
      'opd_visit_id': encounterId,
      'patient_id': patientId,
      'lab_date': labDate.toIso8601String().split('T').first,
      'test_date': DateTime.now().toUtc().toIso8601String(),
      'test_type': 'LAB',
      // Glycemic
      'fbs': fbs,
      'fasting_blood_sugar': fbs,
      'hba1c': hba1c,
      // Lipid
      'cholesterol': totalCholesterol,
      'total_cholesterol': totalCholesterol,
      'triglycerides': triglycerides,
      'triglyceride': triglycerides,
      'hdl': hdl,
      'ldl': ldl,
      // Renal & Electrolytes
      'bun': bun,
      'creatinine': creatinine,
      'egfr': egfr,
      'sodium': sodium,
      'potassium': potassium,
      'chloride': chloride,
      'bicarbonate': bicarbonate,
      // Liver & Metabolic
      'ast': ast,
      'alt': alt,
      'sgpt': alt,
      'alp': alp,
      'uric_acid': uricAcid,
      // Urine
      'urine_microalbumin': urineMicroalbumin,
      'uacr': urineMicroalbumin,
      'urine_protein': urineProtein,
      // Meta
      'clinical_interpretation': interpretation,
      'image_url': imageUrl,
      'staff_recorder_name': staffName,
    });

    await _client.from('lab_results').insert(payload);
  }

  /// 3. บันทึกผลการตรวจ X-Ray หรือ EKG พร้อมภาพแนบ
  Future<void> saveDiagnosticImaging({
    required String encounterId,
    required String patientId,
    required String testType, // 'XRAY' หรือ 'EKG'
    required DateTime examDate,
    required String interpretation,
    String? imageUrl,
  }) async {
    await _requireOpenEncounter(encounterId, patientId);

    final user = _client.auth.currentUser;
    final staffName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email ??
        'แพทย์/เจ้าหน้าที่รังสี';

    await _client.from('lab_results').insert({
      'opd_visit_id': encounterId,
      'patient_id': patientId,
      'lab_date': examDate.toIso8601String().split('T').first,
      'test_type': testType,
      'clinical_interpretation': interpretation,
      'image_url': imageUrl,
      'staff_recorder_name': staffName,
    });

    final testNameThai = testType == 'XRAY'
        ? 'ภาพเอกซเรย์ทรวงอก (Chest X-Ray)'
        : 'คลื่นไฟฟ้าหัวใจ (EKG 12-Lead)';

    await _client.from('staff_notes').insert({
      'opd_visit_id': encounterId,
      'patient_id': patientId,
      'staff_name': staffName,
      'note_text': '[$testNameThai] $interpretation',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// 4. อัปโหลดภาพไปยัง Supabase Storage
  Future<String> uploadClinicalImage({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filePath =
        '$patientId/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

    await _client.storage
        .from('clinical_attachments')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return _client.storage.from('clinical_attachments').getPublicUrl(filePath);
  }
}
