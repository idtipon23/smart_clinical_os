import 'package:flutter_test/flutter_test.dart';
import 'package:smart_clinical_os/core/utils/lab_field_resolver.dart';

void main() {
  group('lab field resolver', () {
    test('reads canonical-only values', () {
      expect(labValue({'fasting_blood_sugar': 110}, 'fbs'), 110);
      expect(labValue({'total_cholesterol': 320}, 'cholesterol'), 320);
      expect(labValue({'triglyceride': 150}, 'triglyceride'), 150);
      expect(labValue({'alt': 40}, 'alt'), 40);
      expect(labValue({'uacr': 30}, 'uacr'), 30);
    });

    test('reads alias-only values', () {
      expect(labValue({'fbs': 110}, 'fbs'), 110);
      expect(labValue({'cholesterol': 320}, 'cholesterol'), 320);
      expect(labValue({'triglycerides': 150}, 'triglyceride'), 150);
      expect(labValue({'sgpt': 40}, 'alt'), 40);
      expect(labValue({'urine_microalbumin': 30}, 'uacr'), 30);
    });

    test('prefers canonical values when both are present', () {
      expect(labValue({'fasting_blood_sugar': 110, 'fbs': 99}, 'fbs'), 110);
    });

    test('returns null when neither value is present', () {
      expect(labValue({}, 'fbs'), isNull);
    });

    test('parses numeric strings', () {
      expect(labNum({'fasting_blood_sugar': '110.00'}, 'fbs'), 110.0);
    });
  });
}
