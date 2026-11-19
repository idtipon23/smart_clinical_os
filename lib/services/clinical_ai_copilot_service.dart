import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'clinical_ai_privacy.dart';

final clinicalAiCopilotServiceProvider = Provider<ClinicalAiCopilotService>((
  ref,
) {
  return ClinicalAiCopilotService(Supabase.instance.client);
});

class ClinicalAiCopilotService {
  final SupabaseClient _client;

  ClinicalAiCopilotService(this._client);

  Future<Map<String, dynamic>> suggestWorkup({
    required Map<String, dynamic> clinicalContext,
    Iterable<Object?> identifiers = const [],
  }) async {
    final anonymized = ClinicalAiPrivacy.sanitizeContext(
      clinicalContext,
      identifiers: identifiers,
    );
    final response = await _invoke('ai-workup-suggest', anonymized);
    return ClinicalAiPrivacy.sanitizeWorkupResult(
      response['result'],
      identifiers: identifiers,
    );
  }

  Future<Map<String, dynamic>> reviewMedicationSafety({
    required Map<String, dynamic> clinicalContext,
    Iterable<Object?> identifiers = const [],
  }) async {
    final anonymized = ClinicalAiPrivacy.sanitizeContext(
      clinicalContext,
      identifiers: identifiers,
    );
    final response = await _invoke('ai-medication-safety', anonymized);
    return ClinicalAiPrivacy.sanitizeMedicationSafetyResult(
      response['result'],
      identifiers: identifiers,
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String functionName,
    Map<String, dynamic> clinicalContext,
  ) async {
    final FunctionResponse response;
    try {
      response = await _client.functions
          .invoke(functionName, body: {'clinical_context': clinicalContext})
          .timeout(const Duration(seconds: 45));
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : error.reasonPhrase ?? 'คำขอ AI ไม่สำเร็จ';
      throw StateError(message);
    } on TimeoutException {
      throw StateError('AI ใช้เวลานานเกินกำหนด กรุณาลองใหม่');
    }

    final data = response.data;
    if (response.status < 200 ||
        response.status >= 300 ||
        data is! Map ||
        data['result'] is! Map) {
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : 'AI ส่งผลลัพธ์ไม่ถูกต้อง';
      throw StateError(message);
    }
    return Map<String, dynamic>.from(data);
  }
}
