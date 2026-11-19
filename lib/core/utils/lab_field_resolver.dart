const Map<String, List<String>> kLabKeyAliases = {
  'fbs': ['fasting_blood_sugar', 'fbs'],
  'cholesterol': ['total_cholesterol', 'cholesterol'],
  'triglyceride': ['triglyceride', 'triglycerides'],
  'alt': ['alt', 'sgpt'],
  'uacr': ['uacr', 'urine_microalbumin'],
};

// Canonical PWA columns take precedence, with legacy staff-app aliases supported.
dynamic labValue(Map<String, dynamic>? lab, String logicalKey) {
  if (lab == null) return null;
  for (final key in kLabKeyAliases[logicalKey] ?? [logicalKey]) {
    final value = lab[key];
    if (value != null) return value;
  }
  return null;
}

double? labNum(Map<String, dynamic>? lab, String logicalKey) {
  final value = labValue(lab, logicalKey);
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
