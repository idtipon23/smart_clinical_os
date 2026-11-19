import 'package:flutter/material.dart';

class AiWorkupResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const AiWorkupResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext _) {
    return Card(
      color: const Color(0xFFF0FDF4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Workup — คำแนะนำประกอบการประเมิน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stage 1 ไม่สั่งยาและไม่ใช่การวินิจฉัย แพทย์ต้องตรวจสอบข้อมูลต้นฉบับ',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            _section('สัญญาณอันตราย', result['red_flags']),
            _differentialSection(result['differential_diagnosis']),
            _section(
              'การตรวจร่างกายที่ควรพิจารณา',
              result['recommended_physical_exams'],
            ),
            _section(
              'การตรวจเพิ่มเติมที่ควรพิจารณา',
              result['recommended_investigations'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Object? value) {
    if (value is! List || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          for (final item in value)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $item'),
            ),
        ],
      ),
    );
  }

  Widget _differentialSection(Object? value) {
    if (value is! List || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'โรคที่ควรพิจารณา (ไม่ใช่การวินิจฉัย)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (final item in value)
            if (item is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${item['condition'] ?? ''}: ${item['reasoning'] ?? ''}',
                ),
              ),
        ],
      ),
    );
  }
}
