import 'package:flutter/material.dart';

class MedicationSafetyReviewDialog extends StatelessWidget {
  final Map<String, dynamic> result;

  const MedicationSafetyReviewDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final alerts = result['alerts'] is List
        ? result['alerts'] as List
        : const <dynamic>[];

    return AlertDialog(
      title: const Text('Stage 2: ทบทวนความปลอดภัยของยา'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'คำแนะนำจาก AI ไม่ใช่คำสั่งสั่งจ่ายยา โปรดตรวจสอบกับข้อมูลต้นฉบับและแหล่งอ้างอิงของคลินิก',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _summary(result['medication_safety_summary']),
              for (final item in alerts)
                if (item is Map) _alertCard(item),
              _limitations(result['limitations']),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
      ],
    );
  }

  Widget _summary(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFFF8FAFC),
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
    );
  }

  Widget _alertCard(Map item) {
    final severity = item['severity']?.toString() ?? 'unknown';
    final color = switch (severity) {
      'critical' => const Color(0xFFB91C1C),
      'high' => const Color(0xFFDC2626),
      'moderate' => const Color(0xFFD97706),
      'low' => const Color(0xFF2563EB),
      _ => const Color(0xFF64748B),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${severity.toUpperCase()} • ${item['medication'] ?? 'ไม่ระบุยา'}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _field('ประเด็น', item['concern']),
            _field('เหตุผล', item['reasoning']),
            _field('สิ่งที่ควรตรวจสอบ', item['recommendation']),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('$label: $text'),
    );
  }

  Widget _limitations(Object? value) {
    if (value is! List || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ข้อจำกัด', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          for (final item in value) Text('• $item'),
        ],
      ),
    );
  }
}
