import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/clinical_theme.dart';
import '../../../../services/clinical_ai_copilot_service.dart';
import '../../../../services/clinical_ai_privacy.dart';
import '../../data/clinical_entry_repository.dart';
import '../../data/opd_visit_repository.dart';
import '../../data/triage_repository.dart';
import '../../../../core/widgets/resizable_clinical_dialog.dart';
import '../../data/clinic_catalog_repository.dart';
import 'catalog_dropdowns.dart';
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
  List<Map<String, dynamic>> _procedures = [];

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
  List<Map<String, dynamic>> _rxItems = [];
  List<Map<String, dynamic>> _labOrders = [];
  List<Map<String, dynamic>> _imagingOrders = [];

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
    _rxItems = _rxItemsFromEncounter(encounter.prescriptions);
    _procedures = _mapList(encounter.procedures);
    _labOrders = _mapList(encounter.labOrders);
    _imagingOrders = _mapList(encounter.imagingOrders);
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
      final prescriptionList = _rxItems.map(_rxItemForSave).toList();

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
            procedures: _procedures,
            labOrders: _labOrders,
            imagingOrders: _imagingOrders,
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
    _rxItems.map(_rxAiLine).join('\u0001'),
    _procedures.map(_orderAiName).join('\u0001'),
    _labOrders.map(_orderAiName).join('\u0001'),
    _imagingOrders.map(_orderAiName).join('\u0001'),
  ].join('\u0000');

  Future<void> _requestMedicationSafetyReview() async {
    if (_isMedicationSafetyLoading || _isLoading) return;
    if (_dxController.text.trim().isEmpty || _rxItems.isEmpty) {
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
          'ประวัติแพ้ยา ยาปัจจุบัน ผลแล็บที่ผูกกับ Encounter รายการยาใหม่ '
          'หัตถการ และรายการตรวจที่วางแผนไว้ (เฉพาะชื่อรายการ ไม่รวมราคา) '
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
        'new_prescriptions': _rxItems
            .map(_rxAiLine)
            .where((line) => line.isNotEmpty)
            .toList(),
        'planned_procedures': _procedures
            .map(_orderAiName)
            .where((line) => line.isNotEmpty)
            .toList(),
        'planned_investigations': [
          ..._labOrders.map((o) => 'Lab: ${_orderAiName(o)}'),
          ..._imagingOrders.map((o) => 'Imaging: ${_orderAiName(o)}'),
        ],
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
          _buildRxSection(),
          const SizedBox(height: 8),
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
          _buildProceduresSection(),
          const SizedBox(height: 16),
          _buildLabSection(),
          const SizedBox(height: 16),
          _buildImagingSection(),
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

  // ===================== catalog / order helpers =====================

  AsyncValue<List<T>> _catalog<T>(
    AsyncValue<List<T>> Function(String facilityId) select,
  ) {
    final facility = ref.watch(currentClinicFacilityIdProvider);
    return facility.when(
      data: select,
      loading: () => AsyncLoading<List<T>>(),
      error: (error, stack) => AsyncError<List<T>>(error, stack),
    );
  }

  static int _uidCounter = 0;
  static String _newUid() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_uidCounter++}';

  static List<Map<String, dynamic>> _mapList(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  Map<String, dynamic> _manualRxItem(String name, {bool legacy = false}) => {
    'uid': _newUid(),
    'source': 'manual',
    'generic_name': name,
    'quantity': legacy ? null : 1,
    'sig': '',
  };

  List<Map<String, dynamic>> _rxItemsFromEncounter(List<dynamic> raw) {
    final result = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is Map) {
        final item = Map<String, dynamic>.from(entry);
        if (item.containsKey('source') || item.containsKey('generic_name')) {
          item['uid'] = _newUid();
          result.add(item);
          continue;
        }
        // รูปแบบเดิม: ข้อความอิสระหลายบรรทัดใน item_name
        final text = item['item_name']?.toString() ?? '';
        for (final line in text.split('\n')) {
          if (line.trim().isNotEmpty) {
            result.add(_manualRxItem(line.trim(), legacy: true));
          }
        }
      } else if (entry.toString().trim().isNotEmpty) {
        result.add(_manualRxItem(entry.toString().trim(), legacy: true));
      }
    }
    return result;
  }

  String _text(Object? value) => (value ?? '').toString().trim();

  String _qtyText(Object? quantity) {
    final n = num.tryParse('${quantity ?? ''}');
    if (n == null) return '';
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  String _rxName(Map<String, dynamic> item) {
    final strength = _text(item['strength']);
    final form = _text(item['dosage_form']);
    return [
      _text(item['generic_name']),
      if (strength.isNotEmpty) '($strength)',
      if (form.isNotEmpty) form,
    ].join(' ');
  }

  /// ข้อความที่เก็บใน item_name (หน้าประวัติและใบพิมพ์อ่านฟิลด์นี้)
  String _rxDisplayLine(Map<String, dynamic> item) {
    final sig = _text(item['sig']);
    final qty = _qtyText(item['quantity']);
    final unit = _text(item['dispensing_unit']);
    return [
      _rxName(item),
      if (sig.isNotEmpty) '— $sig',
      if (qty.isNotEmpty) '#$qty${unit.isNotEmpty ? ' $unit' : ''}',
    ].join(' ');
  }

  /// ข้อความที่ส่งให้ AI: ไม่มีราคา/รหัสภายใน
  String _rxAiLine(Map<String, dynamic> item) {
    final group = _text(item['allergen_group']);
    final sig = _text(item['sig']);
    final qty = _qtyText(item['quantity']);
    final unit = _text(item['dispensing_unit']);
    return [
      _rxName(item),
      if (group.isNotEmpty) '[กลุ่มยา: $group]',
      if (sig.isNotEmpty) '| $sig',
      if (qty.isNotEmpty) '| จำนวน $qty${unit.isNotEmpty ? ' $unit' : ''}',
    ].join(' ').trim();
  }

  Map<String, dynamic> _rxItemForSave(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item)
      ..remove('uid')
      ..remove('sig_rev');
    copy['item_name'] = _rxDisplayLine(item);
    copy['quantity'] = num.tryParse('${item['quantity']}');
    copy['ordered_at'] ??= DateTime.now().toIso8601String();
    return copy;
  }

  String _orderAiName(Map<String, dynamic> order) {
    final th = _text(order['name_th']);
    final en = _text(order['name_en']);
    return [th, if (en.isNotEmpty && en != th) '($en)'].join(' ');
  }

  double _ordersTotal(List<Map<String, dynamic>> orders) =>
      orders.fold<double>(0, (sum, order) {
        final price = (order['unit_price'] as num?)?.toDouble() ?? 0;
        final qty = (order['quantity'] as num?)?.toInt() ?? 1;
        return sum + price * qty;
      });

  void _addOrder(
    List<Map<String, dynamic>> list,
    Map<String, dynamic> item, {
    required String codeKey,
    bool allowRepeat = false,
  }) {
    final index = list.indexWhere(
      (e) => item[codeKey] != null
          ? e[codeKey] == item[codeKey]
          : e['name_th'] == item['name_th'],
    );
    if (index >= 0) {
      if (allowRepeat) {
        final qty = (list[index]['quantity'] as num?)?.toInt() ?? 1;
        setState(() => list[index] = {...list[index], 'quantity': qty + 1});
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('มีรายการนี้แล้ว')));
      }
      return;
    }
    setState(() => list.add(item));
  }

  Future<void> _addManualOrder(
    List<Map<String, dynamic>> list, {
    required String title,
    required String codeKey,
    bool allowRepeat = false,
  }) async {
    final name = await showManualEntryDialog(
      context,
      title: title,
      label: 'ชื่อรายการ',
    );
    if (name == null || !mounted) return;
    _addOrder(
      list,
      {
        'source': 'manual',
        codeKey: null,
        'name_th': name,
        'unit_price': null,
        'quantity': 1,
        'ordered_at': DateTime.now().toIso8601String(),
      },
      codeKey: codeKey,
      allowRepeat: allowRepeat,
    );
  }

  // ===================== Rx (drop-down) =====================

  static const _sigPresets = [
    'วันละ 1 ครั้ง หลังอาหารเช้า',
    'วันละ 2 ครั้ง หลังอาหารเช้า-เย็น',
    'วันละ 3 ครั้ง หลังอาหาร เช้า-กลางวัน-เย็น',
    'วันละ 3 ครั้ง ก่อนอาหาร',
    'วันละ 1 ครั้ง ก่อนนอน',
    'เมื่อมีอาการ ทุก 4-6 ชั่วโมง',
    'ใช้ภายนอก ทาบริเวณที่เป็น วันละ 2 ครั้ง',
  ];

  void _addRxFromCatalog(ClinicMedication med) {
    if (_rxItems.any((e) => e['item_code'] == med.itemCode)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('มียานี้ในรายการแล้ว')));
      return;
    }
    setState(
      () => _rxItems.add({
        'uid': _newUid(),
        'source': 'catalog',
        'item_code': med.itemCode,
        'generic_name': med.genericName,
        'trade_name': med.tradeName,
        'strength': med.strength,
        'dosage_form': med.dosageForm,
        'dispensing_unit': med.dispensingUnit,
        'unit_price': med.sellingPrice,
        'allergen_group': med.allergenGroup,
        'quantity': 1,
        'sig': '',
      }),
    );
  }

  Future<void> _addManualRx() async {
    final name = await showManualEntryDialog(
      context,
      title: 'เพิ่มยานอกรายการคลินิก',
      label: 'ชื่อยา ความแรง รูปแบบ',
    );
    if (name == null || !mounted) return;
    setState(() => _rxItems.add(_manualRxItem(name)));
  }

  Widget _buildRxSection() {
    final meds = _catalog<ClinicMedication>(
      (id) => ref.watch(clinicMedicationsProvider(id)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายการยาที่สั่งจ่าย (Prescription / Rx)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CatalogDropdown<ClinicMedication>(
          hint: 'เลือกยาจากรายการคลินิก (พิมพ์เพื่อค้นหา)',
          emptyMessage: 'ยังไม่มีรายการยาของคลินิก (ตรวจว่ารัน seed แล้ว)',
          items: meds,
          labelOf: (m) =>
              m.stockQty <= 0 ? '${m.displayName} (สต็อกหมด)' : m.displayName,
          onSelected: _addRxFromCatalog,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isLoading ? null : _addManualRx,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('พิมพ์เพิ่มยานอกรายการ'),
          ),
        ),
        if (_rxItems.isEmpty)
          const Text(
            'ยังไม่มีรายการยา',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          )
        else
          for (final item in _rxItems) _buildRxRow(item),
      ],
    );
  }

  Widget _buildRxRow(Map<String, dynamic> item) {
    final uid = item['uid'].toString();
    final price = (item['unit_price'] as num?)?.toDouble();
    final trade = _text(item['trade_name']);
    final unit = _text(item['dispensing_unit']);
    final info = [
      if (trade.isNotEmpty) trade,
      if (price != null) '฿${formatBaht(price)}${unit.isNotEmpty ? ' / $unit' : ''}',
      if (item['source'] == 'manual') 'ยานอกรายการ',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _rxName(item),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'ลบ',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(
                    () => _rxItems.removeWhere((e) => e['uid'] == item['uid']),
                  ),
                ),
              ],
            ),
            if (info.isNotEmpty)
              Text(
                info,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    key: ValueKey('$uid-qty'),
                    initialValue: _qtyText(item['quantity']),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'จำนวน',
                      suffixText: unit,
                      isDense: true,
                    ),
                    onChanged: (v) => item['quantity'] = num.tryParse(v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$uid-sig-${item['sig_rev'] ?? 0}'),
                    initialValue: _text(item['sig']),
                    decoration: InputDecoration(
                      labelText: 'วิธีใช้ (Sig)',
                      isDense: true,
                      suffixIcon: PopupMenuButton<String>(
                        tooltip: 'เลือกวิธีใช้สำเร็จรูป',
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) => setState(() {
                          item['sig'] = value;
                          item['sig_rev'] = ((item['sig_rev'] as int?) ?? 0) + 1;
                        }),
                        itemBuilder: (context) => [
                          for (final preset in _sigPresets)
                            PopupMenuItem<String>(
                              value: preset,
                              child: Text(preset),
                            ),
                        ],
                      ),
                    ),
                    onChanged: (v) => item['sig'] = v,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== procedures / lab / imaging =====================

  Widget _buildOrderSection<T>({
    required String title,
    required String hint,
    required String emptyMessage,
    required String manualLabel,
    required AsyncValue<List<T>> catalog,
    required String Function(T item) labelOf,
    required void Function(T item) onSelected,
    required VoidCallback onManual,
    required List<Map<String, dynamic>> orders,
  }) {
    final total = _ordersTotal(orders);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        CatalogDropdown<T>(
          hint: hint,
          emptyMessage: emptyMessage,
          items: catalog,
          labelOf: labelOf,
          onSelected: onSelected,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isLoading ? null : onManual,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(manualLabel),
          ),
        ),
        if (orders.isEmpty)
          const Text(
            'ยังไม่มีรายการ',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          )
        else ...[
          for (var i = 0; i < orders.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(_orderAiName(orders[i])),
              subtitle: Text(
                [
                  if (orders[i]['unit_price'] != null)
                    '฿${formatBaht((orders[i]['unit_price'] as num?)?.toDouble())}'
                        ' × ${(orders[i]['quantity'] as num?)?.toInt() ?? 1}',
                  if (orders[i]['source'] == 'manual') 'นอกรายการ',
                ].join(' · '),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => orders.removeAt(i)),
              ),
            ),
          if (total > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'รวม ฿${formatBaht(total)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildProceduresSection() => _buildOrderSection<ClinicProcedure>(
    title: 'หัตถการ (Procedures)',
    hint: 'เลือกหัตถการ (พิมพ์เพื่อค้นหา)',
    emptyMessage: 'ยังไม่มีรายการหัตถการของคลินิก',
    manualLabel: 'พิมพ์เพิ่มหัตถการนอกรายการ',
    catalog: _catalog<ClinicProcedure>(
      (id) => ref.watch(clinicProceduresProvider(id)),
    ),
    labelOf: (p) => _text(p.nameEn).isNotEmpty
        ? '${p.nameTh} — ${p.nameEn}'
        : p.nameTh,
    onSelected: (p) => _addOrder(
      _procedures,
      {
        'source': 'catalog',
        'procedure_code': p.procedureCode,
        'name_th': p.nameTh,
        'name_en': p.nameEn,
        'unit_price': p.standardPrice,
        'billing_unit': p.billingUnit,
        'quantity': 1,
        'ordered_at': DateTime.now().toIso8601String(),
      },
      codeKey: 'procedure_code',
      allowRepeat: true,
    ),
    onManual: () => _addManualOrder(
      _procedures,
      title: 'เพิ่มหัตถการนอกรายการ',
      codeKey: 'procedure_code',
      allowRepeat: true,
    ),
    orders: _procedures,
  );

  Widget _buildLabSection() => _buildOrderSection<ClinicLabTest>(
    title: 'ส่งตรวจทางห้องปฏิบัติการ (Lab)',
    hint: 'เลือกรายการ Lab (พิมพ์เพื่อค้นหา)',
    emptyMessage: 'ยังไม่มีรายการ Lab ของคลินิก (รอเพิ่มข้อมูล) — พิมพ์เพิ่มเองได้',
    manualLabel: 'พิมพ์เพิ่มรายการ Lab',
    catalog: _catalog<ClinicLabTest>(
      (id) => ref.watch(clinicLabTestsProvider(id)),
    ),
    labelOf: (l) =>
        _text(l.nameEn).isNotEmpty ? '${l.nameTh} — ${l.nameEn}' : l.nameTh,
    onSelected: (l) => _addOrder(
      _labOrders,
      {
        'source': 'catalog',
        'test_code': l.testCode,
        'name_th': l.nameTh,
        'name_en': l.nameEn,
        'specimen': l.specimen,
        'unit_price': l.standardPrice,
        'billing_unit': l.billingUnit,
        'quantity': 1,
        'ordered_at': DateTime.now().toIso8601String(),
      },
      codeKey: 'test_code',
    ),
    onManual: () => _addManualOrder(
      _labOrders,
      title: 'เพิ่มรายการ Lab นอกรายการ',
      codeKey: 'test_code',
    ),
    orders: _labOrders,
  );

  Widget _buildImagingSection() => _buildOrderSection<ClinicImagingTest>(
    title: 'ส่งตรวจภาพถ่ายรังสี (X-ray / Imaging)',
    hint: 'เลือกรายการ X-ray (พิมพ์เพื่อค้นหา)',
    emptyMessage:
        'ยังไม่มีรายการ X-ray ของคลินิก (รอเพิ่มข้อมูล) — พิมพ์เพิ่มเองได้',
    manualLabel: 'พิมพ์เพิ่มรายการ X-ray',
    catalog: _catalog<ClinicImagingTest>(
      (id) => ref.watch(clinicImagingTestsProvider(id)),
    ),
    labelOf: (x) =>
        _text(x.nameEn).isNotEmpty ? '${x.nameTh} — ${x.nameEn}' : x.nameTh,
    onSelected: (x) => _addOrder(
      _imagingOrders,
      {
        'source': 'catalog',
        'test_code': x.testCode,
        'name_th': x.nameTh,
        'name_en': x.nameEn,
        'modality': x.modality,
        'body_part': x.bodyPart,
        'unit_price': x.standardPrice,
        'billing_unit': x.billingUnit,
        'quantity': 1,
        'ordered_at': DateTime.now().toIso8601String(),
      },
      codeKey: 'test_code',
    ),
    onManual: () => _addManualOrder(
      _imagingOrders,
      title: 'เพิ่มรายการ X-ray นอกรายการ',
      codeKey: 'test_code',
    ),
    orders: _imagingOrders,
  );

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