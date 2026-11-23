class ClinicalAiPrivacy {
  static const _vitalFields = [
    'blood_pressure',
    'pulse',
    'temperature',
    'respiratory_rate',
    'oxygen_saturation',
    'weight',
    'height',
  ];

  static const _listFields = [
    'underlying_diseases',
    'drug_allergies',
    'current_medications',
    'recent_labs',
    'new_prescriptions',
    'planned_procedures',
    'planned_investigations',
  ];

  static Map<String, dynamic> sanitizeContext(
    Map<String, dynamic> context, {
    Iterable<Object?> identifiers = const [],
  }) {
    final identifierValues = identifiers
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.length >= 3)
        .toSet()
        .toList();
    final rawVitals = context['vital_signs'];
    final vitalSigns = rawVitals is Map
        ? Map<String, dynamic>.fromEntries(
            _vitalFields.map(
              (field) => MapEntry(
                field,
                _sanitizeText(rawVitals[field], identifierValues, 100),
              ),
            ),
          )
        : <String, dynamic>{for (final field in _vitalFields) field: ''};

    return {
      'age': _sanitizeText(context['age'], identifierValues, 30),
      'gender': _sanitizeText(context['gender'], identifierValues, 40),
      'vital_signs': vitalSigns,
      'chief_complaints': _sanitizeText(
        context['chief_complaints'],
        identifierValues,
      ),
      for (final field in _listFields)
        field: _sanitizeList(context[field], identifierValues),
    };
  }

  static Map<String, dynamic> sanitizeWorkupResult(
    Object? result, {
    Iterable<Object?> identifiers = const [],
  }) {
    if (result is! Map) throw const FormatException('Invalid workup result');
    final map = Map<String, dynamic>.from(result);
    final differential = map['differential_diagnosis'];
    if (differential is! List) {
      throw const FormatException('Invalid differential diagnosis');
    }

    return {
      'red_flags': _sanitizeList(map['red_flags'], identifiers),
      'differential_diagnosis': differential.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid differential diagnosis item');
        }
        return {
          'condition': _sanitizeText(item['condition'], identifiers),
          'reasoning': _sanitizeText(item['reasoning'], identifiers),
        };
      }).toList(),
      'recommended_physical_exams': _sanitizeList(
        map['recommended_physical_exams'],
        identifiers,
      ),
      'recommended_investigations': _sanitizeList(
        map['recommended_investigations'],
        identifiers,
      ),
    };
  }

  static Map<String, dynamic> sanitizeMedicationSafetyResult(
    Object? result, {
    Iterable<Object?> identifiers = const [],
  }) {
    if (result is! Map) {
      throw const FormatException('Invalid medication safety result');
    }
    final map = Map<String, dynamic>.from(result);
    final alerts = map['alerts'];
    if (alerts is! List) {
      throw const FormatException('Invalid medication safety alerts');
    }
    const severities = {'critical', 'high', 'moderate', 'low', 'unknown'};

    return {
      'medication_safety_summary': _sanitizeText(
        map['medication_safety_summary'],
        identifiers,
      ),
      'alerts': alerts.map((item) {
        if (item is! Map || !severities.contains(item['severity'])) {
          throw const FormatException('Invalid medication safety alert');
        }
        return {
          'severity': item['severity'],
          'medication': _sanitizeText(item['medication'], identifiers),
          'concern': _sanitizeText(item['concern'], identifiers),
          'reasoning': _sanitizeText(item['reasoning'], identifiers),
          'recommendation': _sanitizeText(item['recommendation'], identifiers),
        };
      }).toList(),
      'limitations': _sanitizeList(map['limitations'], identifiers),
    };
  }

  static List<String> identifiersFromPatient(Map<String, dynamic> patient) {
    const identifierFields = {
      'id',
      'patient_id',
      'patientid',
      'hn',
      'full_name',
      'fullname',
      'first_name',
      'firstname',
      'last_name',
      'lastname',
      'name',
      'phone',
      'mobile',
      'telephone',
      'national_id',
      'nationalid',
      'citizen_id',
      'citizenid',
      'address',
      'phone_number',
      'phonenumber',
      'mobile_number',
      'mobilenumber',
      'telephone_number',
      'telephonenumber',
      'postal_code',
      'postalcode',
      'postcode',
      'zip_code',
      'zipcode',
    };
    return patient.entries
        .where((entry) {
          final key = entry.key.toLowerCase();
          return identifierFields.contains(key) ||
              key.startsWith('address') ||
              key.endsWith('_phone') ||
              key.endsWith('_telephone');
        })
        .map((entry) => entry.value?.toString().trim() ?? '')
        .where((value) => value.length >= 3)
        .toSet()
        .toList();
  }

  static String drugAllergyStatusSummary(Object? status) =>
      switch (status?.toString()) {
        'none' => 'สถานะที่บันทึก: ผู้ป่วย/ผู้ดูแลแจ้งว่าไม่มีประวัติแพ้ยา',
        'has_allergy' => 'สถานะที่บันทึก: มีประวัติแพ้ยา',
        _ => 'สถานะที่บันทึก: ยังไม่ทราบหรือยังไม่ได้ซักประวัติแพ้ยา',
      };

  static List<String> _sanitizeList(
    Object? value,
    Iterable<Object?> identifiers,
  ) {
    if (value == null) return [];
    final values = value is List
        ? value.expand((item) => item is List ? item : [item])
        : [value];
    return values
        .map((item) => _sanitizeText(item, identifiers))
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  static String _sanitizeText(
    Object? value,
    Iterable<Object?> identifiers, [
    int maxLength = 3000,
  ]) {
    if (value == null) return '';
    if (value is! String && value is! num) {
      throw const FormatException('Invalid clinical text');
    }
    var text = value.toString().trim();
    for (final identifier in identifiers) {
      final literal = identifier?.toString().trim() ?? '';
      if (literal.length >= 3) {
        text = text.replaceAll(
          RegExp(RegExp.escape(literal), caseSensitive: false),
          '[REDACTED]',
        );
      }
    }
    text = text
        .replaceAllMapped(
          RegExp(r'(^|[^\d])(?:\d[\s-]?){13}(?!\d)'),
          (match) => '${match[1]}[REDACTED_ID]',
        )
        .replaceAllMapped(
          RegExp(r'(^|[^\d])(?:\+?66|0)[\s().-]*(?:\d[\s().-]*){8,10}(?!\d)'),
          (match) => '${match[1]}[REDACTED_PHONE]',
        )
        .replaceAll(
          RegExp(
            r'(?:^|[\s,;])(?:HN|MRN|patient\s*(?:id|number)|hospital\s*(?:id|number))\s*[:#-]?\s*[A-Z0-9][A-Z0-9/-]{2,}',
            caseSensitive: false,
          ),
          ' [REDACTED_HN]',
        )
        .replaceAll(
          RegExp(
            r'(?:เลขบัตรประชาชน|เลขประจำตัวประชาชน|เลขประจำตัวผู้ป่วย)\s*[:：]?\s*[\d -]{8,}',
            caseSensitive: false,
          ),
          '[REDACTED_ID]',
        )
        .replaceAll(
          RegExp(
            r'(?:เบอร์โทร(?:ศัพท์)?|โทรศัพท์|phone)\s*[:：]?\s*[\d\s()+.-]{8,}',
            caseSensitive: false,
          ),
          '[REDACTED_PHONE]',
        )
        .replaceAll(
          RegExp(
            r'(?:ชื่อผู้ป่วย|ผู้ป่วยชื่อ|ที่อยู่|address|บ้านเลขที่|หมู่ที่|ซอย|ถนน|ตำบล|อำเภอ|จังหวัด|แขวง|เขต)\s*[:：]?\s*[^,;\n]+',
            caseSensitive: false,
          ),
          '[REDACTED_PII]',
        )
        .replaceAll(
          RegExp(
            r'(?:^|[\s,;])(?:name|patient name)\s*[:：]?\s*[^,;\n]+',
            caseSensitive: false,
          ),
          ' [REDACTED_NAME]',
        )
        .trim();
    if (text.length > maxLength) {
      throw const FormatException('Clinical text is too long');
    }
    return text;
  }
}
