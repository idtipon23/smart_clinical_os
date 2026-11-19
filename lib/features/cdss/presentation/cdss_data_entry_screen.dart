// lib/features/cdss/presentation/cdss_data_entry_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/clinical_theme.dart';
import '../../../services/general_medical_consult_engine.dart';
import '../../overview/data/patient_triage_model.dart';
import '../../overview/data/triage_repository.dart' hide TriageCategory;
import '../../overview/presentation/patient_detail_screen.dart';

class CdssDataEntryScreen extends ConsumerStatefulWidget {
  const CdssDataEntryScreen({super.key});

  @override
  ConsumerState<CdssDataEntryScreen> createState() => _CdssDataEntryScreenState();
}

class _CdssDataEntryScreenState extends ConsumerState<CdssDataEntryScreen> {
  PatientTriageModel? _selectedPatient;

  final _complaintController = TextEditingController();
  final _onsetController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _historyController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _sbpController = TextEditingController();
  final _dbpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _labSummaryController = TextEditingController();

  final Set<String> _selectedRedFlags = {};
  GeneralMedicalConsultResult? _cdssResult;
  bool _isSaving = false;

  List<TextEditingController> get _inputControllers => [
    _complaintController,
    _onsetController,
    _symptomsController,
    _historyController,
    _medicationsController,
    _allergiesController,
    _sbpController,
    _dbpController,
    _pulseController,
    _temperatureController,
    _respiratoryRateController,
    _oxygenSaturationController,
    _weightController,
    _heightController,
    _labSummaryController,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _inputControllers) {
      controller.addListener(_clearStaleConsultResult);
    }
  }

  void _clearStaleConsultResult() {
    if (_cdssResult != null) {
      setState(() => _cdssResult = null);
    }
  }

  @override
  void dispose() {
    for (final controller in _inputControllers) {
      controller.removeListener(_clearStaleConsultResult);
    }
    _complaintController.dispose();
    _onsetController.dispose();
    _symptomsController.dispose();
    _historyController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _sbpController.dispose();
    _dbpController.dispose();
    _pulseController.dispose();
    _temperatureController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _labSummaryController.dispose();
    super.dispose();
  }

  void _onPatientSelected(PatientTriageModel? patient) {
    if (patient == null) return;
    _cdssResult = null;
    setState(() {
      _selectedPatient = patient;
      _complaintController.clear();
      _onsetController.clear();
      _symptomsController.clear();
      _medicationsController.clear();
      _allergiesController.clear();
      _sbpController.text = patient.systolic?.toString() ?? '';
      _dbpController.text = patient.diastolic?.toString() ?? '';
      _pulseController.text = patient.pulse?.toString() ?? '';
      _temperatureController.clear();
      _respiratoryRateController.clear();
      _oxygenSaturationController.clear();
      _weightController.clear();
      _heightController.clear();
      _labSummaryController.clear();
      _historyController.text = patient.underlyingDiseases ?? '';
      _selectedRedFlags.clear();
    });
  }

  void _evaluateCdss() {
    final observations = <String, String>{
      'blood_pressure': [
        _sbpController.text.trim(),
        _dbpController.text.trim(),
      ].where((value) => value.isNotEmpty).join('/'),
      'pulse': _pulseController.text.trim(),
      'temperature': _temperatureController.text.trim(),
      'respiratory_rate': _respiratoryRateController.text.trim(),
      'oxygen_saturation': _oxygenSaturationController.text.trim(),
      'weight': _weightController.text.trim(),
      'height': _heightController.text.trim(),
      'lab_summary': _labSummaryController.text.trim(),
    };

    setState(() {
      _cdssResult = GeneralMedicalConsultEngine.evaluate(
        GeneralMedicalConsultInput(
          chiefComplaint: _complaintController.text,
          onset: _onsetController.text,
          symptoms: _symptomsController.text,
          medicalHistory: _historyController.text,
          medications: _medicationsController.text,
          allergies: _allergiesController.text,
          observations: observations,
          redFlags: Set<String>.from(_selectedRedFlags),
        ),
      );
    });
  }

  Future<void> _saveAssessment() async {
    if (_selectedPatient == null || _cdssResult == null) return;
    setState(() => _isSaving = true);

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final staffName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email ??
        'พยาบาลวิชาชีพเวชปฏิบัติ';

    final sbp = int.tryParse(_sbpController.text.trim());
    final dbp = int.tryParse(_dbpController.text.trim());
    final pulse = int.tryParse(_pulseController.text.trim());
    final hasBloodPressure = (sbp ?? 0) > 0 && (dbp ?? 0) > 0;
    final observations = {
      'systolic': sbp,
      'diastolic': dbp,
      'pulse': pulse,
      'temperature': _temperatureController.text.trim(),
      'respiratory_rate': _respiratoryRateController.text.trim(),
      'oxygen_saturation': _oxygenSaturationController.text.trim(),
      'weight': _weightController.text.trim(),
      'height': _heightController.text.trim(),
      'lab_summary': _labSummaryController.text.trim(),
    };

    try {
      if (hasBloodPressure) {
        await client.from('vital_signs').insert({
          'patient_id': _selectedPatient!.patientId,
          'systolic': sbp,
          'diastolic': dbp,
          'pulse': pulse,
          'recorded_at': DateTime.now().toIso8601String(),
        });
      }

      final inputSnapshot = {
        'consult_type': 'general_medical',
        'chief_complaint': _complaintController.text.trim(),
        'onset': _onsetController.text.trim(),
        'symptoms': _symptomsController.text.trim(),
        'medical_history': _historyController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'observations': observations,
        'red_flags': _selectedRedFlags.toList(),
        'priority': _cdssResult!.priority.name,
        'missing_information': _cdssResult!.missingInformation,
      };

      await client.from('cdss_events').insert({
        'patient_id': _selectedPatient!.patientId,
        'staff_id': user?.id,
        'staff_name': staffName,
        'rule_id': 'GENERAL-CLINICAL-CONSULT',
        'rule_version': 'GENERAL-1.0',
        'severity': switch (_cdssResult!.priority) {
          ConsultPriority.emergency => 'CRITICAL',
          ConsultPriority.promptReview => 'ROUTINE',
          ConsultPriority.routineReview => 'ROUTINE',
        },
        'input_snapshot': jsonEncode(inputSnapshot),
        'recommendation': _cdssResult!.nextSteps.join('; '),
        'staff_action': 'ACCEPTED',
        'created_at': DateTime.now().toIso8601String(),
      });

      await client.from('staff_notes').insert({
        'patient_id': _selectedPatient!.patientId,
        'staff_name': staffName,
        'note_text': [
          'บันทึกการปรึกษาทางการแพทย์ทั่วไป',
          if (_complaintController.text.trim().isNotEmpty)
            'อาการสำคัญ: ${_complaintController.text.trim()}',
          ..._cdssResult!.nextSteps,
        ].join(' | '),
      });

      ref.invalidate(triageOverviewProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการประเมินและบันทึกทางคลินิกสำเร็จ'),
            backgroundColor: ClinicalColors.primaryEmerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: ClinicalColors.criticalRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final triageAsync = ref.watch(triageOverviewProvider);

    return Scaffold(
      backgroundColor: ClinicalColors.canvasBg,
      body: triageAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ClinicalColors.primaryEmerald),
        ),
        error: (err, _) => Center(
          child: Text('เกิดข้อผิดพลาด: $err', style: const TextStyle(color: ClinicalColors.criticalRed)),
        ),
        data: (patients) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เวิร์กสเปซปรึกษาทางการแพทย์ทั่วไป',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ClinicalColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'บันทึกอาการ ประวัติ สัญญาณชีพ และอาการเตือน เพื่อช่วยจัดลำดับการประเมินโดยบุคลากรทางการแพทย์',
                      style: TextStyle(fontSize: 12.5, color: ClinicalColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Step 1: ค้นหาและเลือกผู้ป่วย
                _buildPatientSelectorCard(patients),
                const SizedBox(height: 20),

                if (_selectedPatient != null) ...[
                  // Step 2: กรอกข้อมูลทางคลินิกและเลือกกลุ่มยา
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildVitalsAndLabCard()),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: _buildClinicalFlagsAndMedsCard()),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildVitalsAndLabCard(),
                            const SizedBox(height: 20),
                            _buildClinicalFlagsAndMedsCard(),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มประมวลผล CDSS
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ClinicalColors.primaryEmerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _evaluateCdss,
                    icon: const Icon(Icons.analytics_rounded, size: 18),
                    label: const Text('สรุปการคัดกรองและข้อมูลที่ต้องติดตาม', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: แสดงผลลัพธ์คำแนะนำ CDSS
                  if (_cdssResult != null) _buildCdssResultCard(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientSelectorCard(List<PatientTriageModel> patients) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceWhite,
        borderRadius: BorderRadius.circular(ClinicalColors.cardRadius),
        border: Border.all(color: ClinicalColors.borderLight),
        boxShadow: ClinicalColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_search_rounded, color: ClinicalColors.totalBlue, size: 20),
              SizedBox(width: 8),
              Text('1. เลือกผู้ป่วยสำหรับคัดกรอง / ประเมิน (Select Patient)', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Autocomplete<PatientTriageModel>(
            displayStringForOption: (p) => '${p.fullName} (${p.hn ?? 'ไม่มี HN'})',
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return patients.take(8);
              }
              final q = textEditingValue.text.toLowerCase();
              return patients.where((p) => p.fullName.toLowerCase().contains(q) || (p.hn?.toLowerCase().contains(q) ?? false));
            },
            onSelected: _onPatientSelected,
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ค้นหาชื่อ-นามสกุล หรือ HN ผู้ป่วย...',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
              );
            },
          ),
          if (_selectedPatient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: ClinicalColors.normalGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ผู้ป่วย: ${_selectedPatient!.fullName} | HN: ${_selectedPatient!.hn ?? "-"} | อายุ: ${_selectedPatient!.age ?? "-"} ปี | โรค: ${_selectedPatient!.underlyingDiseases ?? "-"}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: _selectedPatient!.patientId)),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('ดูประวัติเดิม', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalsAndLabCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceWhite,
        borderRadius: BorderRadius.circular(ClinicalColors.cardRadius),
        border: Border.all(color: ClinicalColors.borderLight),
        boxShadow: ClinicalColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: ClinicalColors.primaryEmerald, size: 20),
              SizedBox(width: 8),
              Text('สัญญาณชีพและผลตรวจที่เกี่ยวข้อง', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _numberField(_sbpController, 'ความดัน SYS', 'mmHg'),
              const SizedBox(width: 8),
              _numberField(_dbpController, 'ความดัน DIA', 'mmHg'),
              const SizedBox(width: 8),
              _numberField(_pulseController, 'ชีพจร', 'ครั้ง/นาที'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              _numberField(_temperatureController, 'อุณหภูมิ', '°C'),
              _numberField(_respiratoryRateController, 'อัตราหายใจ', 'ครั้ง/นาที'),
              _numberField(_oxygenSaturationController, 'SpO₂', '%'),
              _numberField(_weightController, 'น้ำหนัก', 'กก.'),
              _numberField(_heightController, 'ส่วนสูง', 'ซม.'),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _labSummaryController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ผลตรวจ/ข้อมูลเพิ่มเติม',
              hintText: 'เช่น ผลแล็บ ภาพถ่าย หรือผลตรวจที่เกี่ยวข้องกับอาการครั้งนี้',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String unit,
  ) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: unit,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildClinicalFlagsAndMedsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceWhite,
        borderRadius: BorderRadius.circular(ClinicalColors.cardRadius),
        border: Border.all(color: ClinicalColors.borderLight),
        boxShadow: ClinicalColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_ind_rounded, color: ClinicalColors.totalBlue, size: 20),
              SizedBox(width: 8),
              Text('อาการสำคัญและประวัติทางคลินิก', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _complaintController,
            decoration: const InputDecoration(
              labelText: 'อาการสำคัญ',
              hintText: 'เหตุผลหลักที่มารับบริการ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _onsetController,
            decoration: const InputDecoration(
              labelText: 'เริ่มมีอาการเมื่อใด',
              hintText: 'วัน/เวลา หรือระยะเวลาที่มีอาการ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'รายละเอียดอาการและอาการร่วม',
              hintText: 'ลักษณะ ความรุนแรง ตำแหน่ง ปัจจัยกระตุ้น/บรรเทา และอาการร่วม',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _historyController,
            decoration: const InputDecoration(
              labelText: 'โรคประจำตัว/ประวัติสำคัญ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _medicationsController,
            decoration: const InputDecoration(
              labelText: 'ยาที่ใช้อยู่',
              hintText: 'ชื่อยา ขนาด และเวลาที่ใช้ หากทราบ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _allergiesController,
            decoration: const InputDecoration(
              labelText: 'ประวัติแพ้ยา/แพ้อาหาร',
              hintText: 'ระบุสิ่งที่แพ้และอาการ หรือระบุว่าไม่มี/ไม่ทราบ',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 24),
          const Text(
            'คัดกรองอาการเตือนที่ต้องประเมินเร่งด่วน',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...GeneralMedicalConsultEngine.redFlagLabels.map(
            (label) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: ClinicalColors.criticalRed,
              title: Text(label, style: const TextStyle(fontSize: 12)),
              value: _selectedRedFlags.contains(label),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedRedFlags.add(label);
                  } else {
                    _selectedRedFlags.remove(label);
                  }
                  _cdssResult = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCdssResultCard() {
    final res = _cdssResult!;
    final isEmergency = res.priority == ConsultPriority.emergency;
    final priorityLabel = switch (res.priority) {
      ConsultPriority.emergency => 'ต้องประเมินฉุกเฉิน',
      ConsultPriority.promptReview => 'ข้อมูลยังไม่ครบ',
      ConsultPriority.routineReview => 'รอผู้ประกอบวิชาชีพประเมิน',
    };
    final priorityColor = isEmergency
        ? ClinicalColors.criticalRed
        : res.priority == ConsultPriority.promptReview
        ? ClinicalColors.warningOrange
        : ClinicalColors.primaryEmerald;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceWhite,
        borderRadius: BorderRadius.circular(ClinicalColors.cardRadius),
        border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
        boxShadow: ClinicalColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEmergency
                          ? Icons.emergency_rounded
                          : Icons.fact_check_rounded,
                      color: priorityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สรุปการคัดกรองทางคลินิก',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: ClinicalColors.primaryEmerald),
                onPressed: _isSaving ? null : _saveAssessment,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกคำสั่งการลงเวชระเบียน'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Safety Alerts
          if (res.safetyAlerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: res.safetyAlerts
                    .map(
                      (alert) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '🚨 $alert',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ClinicalColors.criticalRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (res.missingInformation.isNotEmpty) ...[
            const Text(
              'ข้อมูลที่ควรเก็บเพิ่ม',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...res.missingInformation.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $item',
                  style: const TextStyle(fontSize: 12, color: ClinicalColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'ขั้นตอนถัดไป (สนับสนุนการตัดสินใจ ไม่ใช่การวินิจฉัย)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...res.nextSteps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: ClinicalColors.primaryEmerald)),
                  Expanded(child: Text(step, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ระบบไม่วินิจฉัยโรคและไม่เสนอการสั่งยา ผู้ประกอบวิชาชีพต้องประเมินผู้ป่วยและใช้ดุลยพินิจทางคลินิก',
            style: TextStyle(
              fontSize: 11,
              color: ClinicalColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}