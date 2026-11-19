import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/staff_auth_repository.dart';

class ClinicMedication {
  final String id;
  final String itemCode;
  final String genericName;
  final String? tradeName;
  final String? strength;
  final String? dosageForm;
  final String? dispensingUnit;
  final double? costPrice;
  final double? sellingPrice;
  final double stockQty;
  final bool nlemMarked;
  final String? nlemCategory;
  final String? nlemSourceYear;
  final bool nlemVerified;
  final String? pediatricDoseNotes;
  final String? pediatricDoseSource;
  final String pediatricDoseBasis;
  final String? pediatricIbwProtocol;
  final bool pediatricAutoCalculationEnabled;
  final String? precautionInteractionNotes;
  final String? allergenGroup;

  const ClinicMedication({
    required this.id,
    required this.itemCode,
    required this.genericName,
    this.tradeName,
    this.strength,
    this.dosageForm,
    this.dispensingUnit,
    this.costPrice,
    this.sellingPrice,
    required this.stockQty,
    required this.nlemMarked,
    this.nlemCategory,
    this.nlemSourceYear,
    required this.nlemVerified,
    this.pediatricDoseNotes,
    this.pediatricDoseSource,
    required this.pediatricDoseBasis,
    this.pediatricIbwProtocol,
    required this.pediatricAutoCalculationEnabled,
    this.precautionInteractionNotes,
    this.allergenGroup,
  });

  factory ClinicMedication.fromMap(Map<String, dynamic> map) {
    return ClinicMedication(
      id: map['id']?.toString() ?? '',
      itemCode: map['item_code']?.toString() ?? '',
      genericName: map['generic_name']?.toString() ?? '',
      tradeName: map['trade_name']?.toString(),
      strength: map['strength']?.toString(),
      dosageForm: map['dosage_form']?.toString(),
      dispensingUnit: map['dispensing_unit']?.toString(),
      costPrice: (map['cost_price'] as num?)?.toDouble(),
      sellingPrice: (map['selling_price'] as num?)?.toDouble(),
      stockQty: (map['stock_qty'] as num?)?.toDouble() ?? 0,
      nlemMarked: map['nlem_marked'] == true,
      nlemCategory: map['nlem_category']?.toString(),
      nlemSourceYear: map['nlem_source_year']?.toString(),
      nlemVerified: map['nlem_verified'] == true,
      pediatricDoseNotes: map['pediatric_dose_notes']?.toString(),
      pediatricDoseSource: map['pediatric_dose_source']?.toString(),
      pediatricDoseBasis:
          map['pediatric_dose_basis']?.toString() ?? 'not_configured',
      pediatricIbwProtocol: map['pediatric_ibw_protocol']?.toString(),
      pediatricAutoCalculationEnabled:
          map['pediatric_auto_calculation_enabled'] == true,
      precautionInteractionNotes: map['precaution_interaction_notes']
          ?.toString(),
      allergenGroup: map['allergen_group']?.toString(),
    );
  }

  String get displayName => [
    genericName,
    if (strength?.isNotEmpty == true) strength,
    if (dosageForm?.isNotEmpty == true) dosageForm,
  ].join(' — ');
}

class ClinicProcedure {
  final String id;
  final String procedureCode;
  final String nameTh;
  final String? nameEn;
  final double? standardPrice;
  final String? billingUnit;
  final String? icd9CmReference;
  final String? remarks;
  final bool referenceVerified;

  const ClinicProcedure({
    required this.id,
    required this.procedureCode,
    required this.nameTh,
    this.nameEn,
    this.standardPrice,
    this.billingUnit,
    this.icd9CmReference,
    this.remarks,
    required this.referenceVerified,
  });

  factory ClinicProcedure.fromMap(Map<String, dynamic> map) {
    return ClinicProcedure(
      id: map['id']?.toString() ?? '',
      procedureCode: map['procedure_code']?.toString() ?? '',
      nameTh: map['name_th']?.toString() ?? '',
      nameEn: map['name_en']?.toString(),
      standardPrice: (map['standard_price'] as num?)?.toDouble(),
      billingUnit: map['billing_unit']?.toString(),
      icd9CmReference: map['icd9_cm_reference']?.toString(),
      remarks: map['remarks']?.toString(),
      referenceVerified: map['reference_verified'] == true,
    );
  }
}

final clinicCatalogRepositoryProvider = Provider<ClinicCatalogRepository>((
  ref,
) {
  return ClinicCatalogRepository(Supabase.instance.client, ref);
});

final currentClinicFacilityIdProvider = FutureProvider.autoDispose<String>((
  ref,
) {
  return ref.watch(clinicCatalogRepositoryProvider).getCurrentFacilityId();
});

final clinicMedicationsProvider = FutureProvider.autoDispose
    .family<List<ClinicMedication>, String>((ref, facilityId) {
      return ref
          .watch(clinicCatalogRepositoryProvider)
          .fetchMedications(facilityId);
    });

final clinicProceduresProvider = FutureProvider.autoDispose
    .family<List<ClinicProcedure>, String>((ref, facilityId) {
      return ref
          .watch(clinicCatalogRepositoryProvider)
          .fetchProcedures(facilityId);
    });

class ClinicCatalogRepository {
  final SupabaseClient _client;
  final Ref _ref;

  ClinicCatalogRepository(this._client, this._ref);

  Future<String> getCurrentFacilityId() async {
    final staffProfile = await _ref.read(currentStaffProfileProvider.future);
    final facilityId = staffProfile?.facilityId.trim();
    if (facilityId == null || facilityId.isEmpty) {
      throw StateError('ไม่พบหน่วยบริการของเจ้าหน้าที่ที่เข้าสู่ระบบ');
    }
    return facilityId;
  }

  Future<List<ClinicMedication>> fetchMedications(String facilityId) async {
    final rows = await _client
        .from('clinic_medications')
        .select()
        .eq('facility_id', facilityId)
        .eq('is_active', true)
        .order('generic_name');
    return (rows as List)
        .map(
          (row) =>
              ClinicMedication.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<List<ClinicProcedure>> fetchProcedures(String facilityId) async {
    final rows = await _client
        .from('clinic_procedures')
        .select()
        .eq('facility_id', facilityId)
        .eq('is_active', true)
        .order('name_th');
    return (rows as List)
        .map(
          (row) =>
              ClinicProcedure.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}
