import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/clinical_theme.dart';
import '../../../../services/clinical_ai_copilot_service.dart';
import '../../../../services/clinical_ai_privacy.dart';
import '../../data/clinical_entry_repository.dart';
import '../../data/opd_visit_repository.dart';
import '../../data/triage_repository.dart';
import '../../../../core/widgets/resizable_clinical_dialog.dart';
import 'medication_safety_review_dialog.dart';

class OpdEncounterDialog extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;
  final int? sbp;
  final int? dbp;
  final int? pulse;
  final OpdVisitModel? existingEncounter;
  final VoidCallback onSaved;

  const OpdEncounterDialog({
    super.key,
    required this.patientId,
    required this.patientName,
    this.sbp,
    this.dbp,
    this.pulse,
    this.existingEncounter,
    required this.onSaved,
  });

  @override
  ConsumerState<OpdEncounterDialog> createState() => _OpdEncounterDialogState();
}

class _OpdEncounterDialogState extends ConsumerState<OpdEncounterDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isMedicationSafetyLoading = false;

  // History Taking
  final _ccController = TextEditingController();
  final _piController = TextEditingController();
  final _phController = TextEditingController();
  final _allergyController = TextEditingController();

  // Physical Examination
  final _peGeneralController = TextEditingController();
  final _peHeentController = TextEditingController();
  final _peHeartController = TextEditingController();
  final _peLungsController = TextEditingController();
  final _peAbdomenController = TextEditingController();
  final _peExtremitiesController = TextEditingController();

  // Diagnosis & Plan
  final _dxController = TextEditingController();
  final _icd10Controller = TextEditingController();
  final _planController = TextEditingController();
  final _rxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final encounter = widget.existingEncounter;
    if (encounter != null) {
      _populateFromEncounter(encounter);
    }
  }

  void _populateFromEncounter(OpdVisitModel encounter) {
    _ccController.text = encounter.chiefComplaint;
    _piController.text = encounter.presentIllness ?? '';
    _phController.text = encounter.pastHistory ?? '';
    _allergyController.text = encounter.medicationAllergy ?? '';
    _peGeneralController.text = encounter.peGeneral ?? '';
    _peHeentController.text = encounter.peHeent ?? '';
    _peHeartController.text = encounter.peHeart ?? '';
    _peLungsController.text = encounter.peLungs ?? '';
    _peAbdomenController.text = encounter.peAbdomen ?? '';
    _peExtremitiesController.text = encounter.peExtremities ?? '';
    _dxController.text = encounter.diagnosisText == 'รอการตรวจประเมิน'
        ? ''
        : encounter.diagnosisText;
    _icd10Controller.text = encounter.icd10Code ?? '';
    _planController.text = encounter.treatmentPlan ?? '';
    _rxController.text = encounter.prescriptions
        .map((item) {
          if (item is Map) return item['item_name']?.toString() ?? '';
          return item.toString();
        })
        .where((item) => item.isNotEmpty)
        .join('\n');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ccController.dispose();
    _piController.dispose();
    _phController.dispose();
    _allergyController.dispose();
    _peGeneralController.dispose();
    _peHeentController.dispose();
    _peHeartController.dispose();
    _peLungsController.dispose();
    _peAbdomenController.dispose();
    _peExtremitiesController.dispose();
    _dxController.dispose();
    _icd10Controller.dispose();
    _planController.dispose();
    _rxController.dispose();
    super.dispose();
  }

  Future<void> _submitEncounter({bool closeEncounter = false}) async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    if (closeEncounter && _dxController.text.trim().isEmpty) {
      _tabController.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุการวินิจฉัยโรค (Diagnosis)'),
          backgroundColor: ClinicalColors.criticalRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> prescriptionList = [];
      if (_rxController.text.trim().isNotEmpty) {
        prescriptionList.add({
          'item_name': _rxController.text.trim(),
          'ordered_at': DateTime.now().toIso8601String(),
        });
      }

      await ref
          .read(opdVisitRepositoryProvider)
          .saveOpdVisit(
            encounterId: widget.existingEncounter?.id,
            closeEncounter: closeEncounter,
            consultationSnapshot:
                widget.existingEncounter?.consultationSnapshot,
            patientId: widget.patientId,
            sbp: widget.existingEncounter?.sbp ?? widget.sbp,
            dbp: widget.existingEncounter?.dbp ?? widget.dbp,
            pulse: widget.existingEncounter?.pulse ?? widget.pulse,
            chiefComplaint: _ccController.text.trim(),
            presentIllness: _piController.text.trim(),
            pastHistory: _phController.text.trim(),
            medicationAllergy: _allergyController.text.trim(),
            peGeneral: _peGeneralController.text.trim(),
            peHeent: _peHeentController.text.trim(),
            peHeart: _peHeartController.text.trim(),
            peLungs: _peLungsController.text.trim(),
            peAbdomen: _peAbdomenController.text.trim(),
            peExtremities: _peExtremitiesController.text.trim(),
            diagnosisText: _dxController.text.trim(),
            icd10Code: _icd10Controller.text.trim(),
            treatmentPlan: _planController.text.trim(),
            prescriptions: prescriptionList,
          );

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _medicationSafetyInputFingerprint() => [
    widget.patientId,
    _ccController.text,
    _piController.text,
    _phController.text,
    _allergyController.text,
    _dxController.text,
    _rxController.text,
  ].join('\u0000');

  Future<void> _requestMedicationSafetyReview() async {
    if (_isMedicationSafetyLoading || _isLoading) return;
    if (_dxController.text.trim().isEmpty ||
        _rxController.text.trim().isEmpty) {
      _tabController.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุ Diagnosis และรายการยาก่อน')),
      );
      return;
    }

    final fingerprint = _medicationSafetyInputFingerprint();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตรวจทานความปลอดภัยของยา (AI)'),
        content: const Text(
          'เมื่อยืนยัน ระบบจะส่งเฉพาะอายุ เพศ สัญญาณชีพ อาการ โรคร่วม '
          'ประวัติแพ้ยา ยาปัจจุบัน ผลแล็บที่ผูกกับ Encounter และรายการยาใหม่ '
          'ผ่าน Supabase Edge Function ไปยัง Google Gemini API โดยลบข้อมูลระบุตัวตน '
          'จากประวัติผู้ป่วยและตรวจจับรูปแบบทั่วไป ไม่ส่งภาพตรวจ '
          'อย่างไรก็ตาม ระบบอาจตรวจไม่พบชื่อหรือที่อยู่ที่พิมพ์ปะปนในข้อความอิสระ '
          'โปรดตรวจข้อมูลก่อนยืนยัน\n\n'
          'AI เป็นเพียงตัวช่วยตรวจทาน ไม่สั่งหรือเปลี่ยนยา และไม่คำนวณขนาดยา '
          'แพทย์ต้องตรวจสอบข้อมูลและแหล่งอ้างอิงเอง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยันและตรวจทานยา'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isMedicationSafetyLoading = true);
    try {
      final detail = await ref.read(
        patientDetailProvider(widget.patientId).future,
      );
      if (detail.patient.isEmpty) {
        throw StateError('ไม่พบข้อมูลผู้ป่วยสำหรับตรวจทานยา');
      }

      final patient = detail.patient;
      final medicationRows = await ref.read(
        patientMedicationsProvider(widget.patientId).future,
      );
      final encounter = widget.existingEncounter;
      final results = encounter == null
          ? null
          : await ref.read(
              encounterClinicalResultsProvider(encounter.id).future,
            );
      final latestVital = results?.vitalSigns.isNotEmpty == true
          ? results!.vitalSigns.first
          : detail.vitalSigns.isNotEmpty
          ? detail.vitalSigns.first
          : <String, dynamic>{};

      List<Object?> values(Object? value) {
        if (value is List) return value;
        if (value is String && value.trim().isNotEmpty) {
          return value.split(RegExp(r'[\n,;]+'));
        }
        return value == null ? [] : [value];
      }

      String firstValue(Iterable<Object?> candidates) {
        for (final candidate in candidates) {
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            return candidate.toString().trim();
          }
        }
        return '';
      }

      final currentMedications = <Object?>[
        ...values(patient['current_med_classes']),
        ...medicationRows
            .where((item) {
              const activeFields = [
                'is_morning_active',
                'is_noon_active',
                'is_evening_active',
                'is_bedtime_active',
              ];
              return !activeFields.any(item.containsKey) ||
                  activeFields.any((field) => item[field] == true);
            })
            .map((item) {
              final name = item['medication_name']?.toString().trim() ?? '';
              if (name.isEmpty) return '';
              final schedule = [
                if (item['is_morning_active'] == true) 'เช้า',
                if (item['is_noon_active'] == true) 'กลางวัน',
                if (item['is_evening_active'] == true) 'เย็น',
                if (item['is_bedtime_active'] == true) 'ก่อนนอน',
              ];
              return schedule.isEmpty ? name : '$name (${schedule.join('/')})';
            }),
      ];

      const labFields = [
        'fbs',
        'hba1c',
        'cholesterol',
        'total_cholesterol',
        'triglycerides',
        'hdl',
        'ldl',
        'bun',
        'creatinine',
        'egfr',
        'sodium',
        'potassium',
        'chloride',
        'bicarbonate',
        'ast',
        'alt',
        'alp',
        'uric_acid',
        'urine_microalbumin',
        'uacr',
        'urine_protein',
      ];
      final recentLabs = <String>[];
      for (final row in results?.labResults ?? const <Map<String, dynamic>>[]) {
        final values = [
          for (final field in labFields)
            if (row[field] != null && row[field].toString().trim().isNotEmpty)
              '$field: ${row[field]}',
          if (row['clinical_interpretation'] != null &&
              row['clinical_interpretation'].toString().trim().isNotEmpty)
            row['clinical_interpretation'].toString().trim(),
        ];
        if (values.isNotEmpty && recentLabs.length < 30) {
          recentLabs.add(
            '${row['test_type']?.toString() ?? 'ผลตรวจ'}: ${values.join(', ')}',
          );
        }
      }

      final requestContext = {
        'age': patient['age']?.toString() ?? '',
        'gender': patient['gender']?.toString() ?? '',
        'vital_signs': {
          'blood_pressure': firstValue([
            if (latestVital['systolic'] != null &&
                latestVital['diastolic'] != null)
              '${latestVital['systolic']}/${latestVital['diastolic']}',
            if (encounter?.sbp != null && encounter?.dbp != null)
              '${encounter!.sbp}/${encounter.dbp}',
            if (widget.sbp != null && widget.dbp != null)
              '${widget.sbp}/${widget.dbp}',
          ]),
          'pulse': firstValue([
            latestVital['pulse'],
            encounter?.pulse,
            widget.pulse,
          ]),
          'temperature': firstValue([
            latestVital['temperature'],
            encounter?.temperature,
          ]),
          'respiratory_rate': firstValue([
            latestVital['respiratory_rate'],
            encounter?.respiratoryRate,
          ]),
          'oxygen_saturation': firstValue([
            latestVital['oxygen_saturation'],
            latestVital['spo2'],
          ]),
          'weight': firstValue([latestVital['weight_kg'], encounter?.weightKg]),
          'height': firstValue([latestVital['height_cm'], encounter?.heightCm]),
        },
        'chief_complaints': [
          if (_ccController.text.trim().isNotEmpty)
            'อาการสำคัญ: ${_ccController.text.trim()}',
          if (_piController.text.trim().isNotEmpty)
            'อาการปัจจุบัน: ${_piController.text.trim()}',
        ].join('\n'),
        'underlying_diseases': [
          ...values(patient['underlying_diseases']),
          ...values(patient['medication_risk_conditions']),
          _phController.text,
        ],
        'drug_allergies': [
          ...values(patient['drug_allergies']),
          _allergyController.text,
          ClinicalAiPrivacy.drugAllergyStatusSummary(
            patient['drug_allergy_status'],
          ),
        ],
        'current_medications': currentMedications,
        'recent_labs': recentLabs,
        'new_prescriptions': _rxController.text
            .split(RegExp(r'[\n;]+'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
      };
      final identifiers = [
        widget.patientId,
        widget.patientName,
        ...ClinicalAiPrivacy.identifiersFromPatient(patient),
      ];
      if (!mounted) return;
      if (_medicationSafetyInputFingerprint() != fingerprint) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ข้อมูลยาเปลี่ยนระหว่างเตรียมคำขอ กรุณากดตรวจทานอีกครั้ง',
            ),
          ),
        );
        return;
      }
      final review = await ref
          .read(clinicalAiCopilotServiceProvider)
          .reviewMedicationSafety(
            clinicalContext: requestContext,
            identifiers: identifiers,
          );
      if (!mounted) return;
      if (_medicationSafetyInputFingerprint() != fingerprint) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ข้อมูลยาเปลี่ยนระหว่างตรวจทาน กรุณากดตรวจทานอีกครั้ง',
            ),
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => MedicationSafetyReviewDialog(result: review),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ตรวจทานความปลอดภัยของยาไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMedicationSafetyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final encounter = widget.existingEncounter;
    final displaySbp = encounter?.sbp ?? widget.sbp;
    final displayDbp = encounter?.dbp ?? widget.dbp;
    final displayPulse = encounter?.pulse ?? widget.pulse;

    return ResizableClinicalDialog(
      startMaximized: true,
      child: Container(
        width: 980,
        height: 780,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header ส่วนหัวสว่าง พร้อมค่าสัญญาณชีพใหญ่ชัด
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF0284C7),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'บันทึกการตรวจรักษาผู้ป่วยนอก (OPD Encounter)',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'ผู้ป่วย: ${widget.patientName}',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                'V/S ล่าสุด: ${displaySbp ?? '-'}/${displayDbp ?? '-'} mmHg (PR: ${displayPulse ?? '-'} bpm)',
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (widget.existingEncounter != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'กำลังทำต่อ OPD encounter ที่ยังเปิดอยู่ — บันทึกค้างไว้เพื่อทำต่อ หรือปิดเมื่อการตรวจรักษาเสร็จสิ้น',
                    style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // TabBar
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0284C7),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF0284C7),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.history_edu_outlined, size: 20),
                      text: '1. ซักประวัติอาการ (CC / PI)',
                    ),
                    Tab(
                      icon: Icon(Icons.accessibility_new_outlined, size: 20),
                      text: '2. ตรวจร่างกาย (Physical Exam)',
                    ),
                    Tab(
                      icon: Icon(Icons.assignment_turned_in_outlined, size: 20),
                      text: '3. การวินิจฉัย & แผนการรักษา (Dx / Plan / Rx)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryTab(),
                    _buildPhysicalExamTab(),
                    _buildDiagnosisPlanTab(),
                  ],
                ),
              ),

              // Actions Footer
              const Divider(color: Color(0xFFE2E8F0), height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _submitEncounter(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 20),
                    label: const Text(
                      'บันทึกค้างไว้',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _submitEncounter(closeEncounter: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'ปิด Encounter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildField(
            label: 'อาการสำคัญที่มาพบแพทย์ (Chief Complaint: CC) *',
            controller: _ccController,
            hint: 'เช่น มาตรวจตามนัดความดันโลหิตสูง, ปวดศีรษะท้ายทอย 2 วัน',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณาระบุอาการสำคัญ' : null,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'ประวัติการเจ็บป่วยปัจจุบัน (Present Illness: PI)',
            controller: _piController,
            hint: 'รายละเอียดอาการ ระยะเวลา ปัจจัยกระตุ้น หรืออาการร่วมอื่นๆ',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'ประวัติโรคประจำตัว / การผ่าตัด (Past History)',
                  controller: _phController,
                  hint: 'เช่น HT 5 ปี, DLP, ไม่เคยผ่าตัด',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildField(
                  label: 'ประวัติแพ้ยา / แพ้อาหาร (Allergy)',
                  controller: _allergyController,
                  hint: 'ระบุชื่อยา หรือ ปฏิเสธการแพ้ยา',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalExamTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'General Appearance',
                  controller: _peGeneralController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildField(
                  label: 'HEENT (ศีรษะ ตา หู คอ จมูก)',
                  controller: _peHeentController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Heart & CVS (หัวใจและหลอดเลือด)',
                  controller: _peHeartController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildField(
                  label: 'Lungs & Thorax (ปอดและทรวงอก)',
                  controller: _peLungsController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Abdomen (ช่องท้อง)',
                  controller: _peAbdomenController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildField(
                  label: 'Extremities (รยางค์/แขนขา)',
                  controller: _peExtremitiesController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisPlanTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildField(
                  label: 'การวินิจฉัยโรค (Diagnosis: Dx) *',
                  controller: _dxController,
                  hint: 'เช่น Essential Hypertension, Type 2 DM, Acute URI',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณาระบุผลการวินิจฉัย'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildField(
                  label: 'รหัส ICD-10',
                  controller: _icd10Controller,
                  hint: 'I10, E11.9, J00',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'รายการยาที่สั่งจ่าย (Prescription / Rx)',
            controller: _rxController,
            hint: 'เช่น Amlodipine (5mg) 1 tab po od pc เช้า #30\nMetformin (500mg) 1 tab po bid pc เช้า-เย็น #60',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isLoading || _isMedicationSafetyLoading
                ? null
                : _requestMedicationSafetyReview,
            icon: _isMedicationSafetyLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.medication_outlined, size: 18),
            label: Text(
              _isMedicationSafetyLoading
                  ? 'กำลังตรวจทานยา...'
                  : 'ตรวจทานความปลอดภัยของยา (AI)',
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'แผนการดูแลและคำแนะนำผู้ป่วย (Treatment Plan & Advice)',
            controller: _planController,
            hint: 'เช่น ควบคุมอาหารเค็ม, ลดแป้ง, นัด F/U ติดตามความดัน 1 เดือน',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF0284C7),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
      ],
    );
  }
}
