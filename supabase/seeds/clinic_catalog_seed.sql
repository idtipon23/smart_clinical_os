-- Generated from the clinic-supplied workbook. No patient data is included.
-- Run after 20261119152000_clinic_catalogs_and_opd_orders.sql.
-- This seed refuses to assign clinic-specific prices when the project has
-- zero or multiple facilities; review facility scoping before retrying.
begin;
do $$
declare
  facility_count integer;
  target_facility_id text;
begin
  select count(*) into facility_count from public.facilities;
  if facility_count <> 1 then
    raise exception 'Clinic catalog seed requires exactly one facility; found %. Do not apply clinic prices to multiple facilities.', facility_count;
  end if;
  select id::text into target_facility_id from public.facilities limit 1;

  insert into public.clinic_medications (
    facility_id, item_code, generic_name, trade_name, strength, dosage_form,
    dispensing_unit, cost_price, selling_price, stock_qty, nlem_marked,
    nlem_category, pediatric_dose_notes, precaution_interaction_notes,
    source_file, nlem_verified, pediatric_dose_source,
    pediatric_dose_basis, pediatric_auto_calculation_enabled
  )
  values
      (target_facility_id, 'MED-001', 'Paracetamol', 'Sara / Calpol', '500 mg', 'Tablet', 'เม็ด', 0.35, 1.5, 1000, true, 'ก', '10-15 mg/kg/dose q 4-6 hr (Max 75 mg/kg/day)', 'ระวังในผู้ป่วยโรคตับ ดื่มแอลกอฮอล์เรื้อรัง', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-002', 'Paracetamol Syrup', 'Sara Syrup', '120 mg/5 mL', 'Syrup (60 mL)', 'ขวด', 12, 35, 50, true, 'ก', '10-15 mg/kg/dose q 4-6 hr', 'ระวังคำนวณความเข้มข้นผิด', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-003', 'Ibuprofen', 'Brufen', '400 mg', 'Film-coated tab', 'เม็ด', 0.8, 3, 500, true, 'ข', '5-10 mg/kg/dose q 6-8 hr (Max 40 mg/kg/day)', 'ห้ามใช้ในไข้เลือดออก ระวังโรคกระเพาะ/ไต', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-004', 'Ibuprofen Suspension', 'Ibuman Suspension', '100 mg/5 mL', 'Suspension (60 mL)', 'ขวด', 20, 50, 30, true, 'ข', '5-10 mg/kg/dose q 6-8 hr', 'ห้ามใช้ในเด็กสงสัยไข้เลือดออก/ขาดน้ำ', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-005', 'Amoxicillin', 'Amoxil', '500 mg', 'Capsule', 'แคปซูล', 1.2, 4, 500, true, 'ก', '40-90 mg/kg/day แบ่ง 2-3 ครั้ง', 'แพ้ Penicillin ห้ามใช้ ระวัง cross-allergy กับ Cephalosporin', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-006', 'Amoxicillin Dry Syrup', 'Amoxy Dry Syrup', '250 mg/5 mL', 'Dry Syrup (60 mL)', 'ขวด', 22, 60, 30, true, 'ก', '40-90 mg/kg/day แบ่ง 2-3 ครั้ง', 'หลังผสมน้ำมีอายุ 7 วัน (อุณหภูมิห้อง) หรือ 14 วัน (ตู้เย็น)', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-007', 'Amoxicillin + Clavulanate', 'Augmentin', '1 g (875/125)', 'Tablet', 'เม็ด', 15, 35, 100, true, 'ข', 'เด็กใช้รูปแบบ suspension ตามสูตรเฉพาะ', 'ระวังอาการท้องเสีย การแพ้ยากลุ่ม penicillin', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-008', 'Cetirizine', 'Zyrtec', '10 mg', 'Film-coated tab', 'เม็ด', 0.8, 3, 500, true, 'ก', 'อายุ 2-6 ปี: 2.5-5 mg/day, >6 ปี: 10 mg/day', 'ระวังอาการง่วงซึม ปรับขนาดยาในผู้ป่วยไตบกพร่อง', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-009', 'Cetirizine Syrup', 'Zyrtec Syrup', '5 mg/5 mL', 'Syrup (60 mL)', 'ขวด', 25, 65, 30, true, 'ก', '0.25 mg/kg/day หรือตามช่วงอายุ', 'ระวังการใช้ในเด็กอายุน้อยกว่า 6 เดือน', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-010', 'Chlorpheniramine (CPM)', 'Chlor-Trimeton', '4 mg', 'Tablet', 'เม็ด', 0.15, 1, 1000, true, 'ก', '0.35 mg/kg/day แบ่ง 3-4 ครั้ง', 'ง่วงซึมสูง หลีกเลี่ยงขับรถ ห้ามใช้ในเด็กทารก', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-011', 'Dextromethorphan', 'Romilar', '15 mg', 'Tablet', 'เม็ด', 0.5, 2, 500, true, 'ก', '1-2 mg/kg/day แบ่ง 3-4 ครั้ง', 'ห้ามใช้ร่วมกับยากลุ่ม MAOIs, ระวัง Serotonin syndrome', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-012', 'Bromhexine', 'Bisolvon', '8 mg', 'Tablet', 'เม็ด', 0.6, 2.5, 500, true, 'ก', 'เด็ก >2 ปี: 0.3 mg/kg/day', 'ระวังในผู้ป่วยที่มีแผลในกระเพาะอาหาร', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-013', 'Salbutamol', 'Ventolin', '2 mg', 'Tablet', 'เม็ด', 0.3, 1.5, 300, true, 'ก', '0.1-0.2 mg/kg/dose วันละ 3 ครั้ง', 'ระวังใจสั่น มือสั่น หัวใจเต้นเร็ว โพแทสเซียมต่ำ', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-014', 'Omeprazole', 'Miracid', '20 mg', 'Capsule (Enteric-coated)', 'แคปซูล', 1.2, 4, 500, true, 'ก', '0.7-1 mg/kg/day วันละ 1 ครั้ง', 'Interaction กับ Clopidogrel (ลดประสิทธิภาพ)', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-015', 'Simethicone', 'Air-X', '80 mg', 'Chewable tab', 'เม็ด', 0.8, 2.5, 500, true, 'ก', 'เด็ก <2 ปี: 20 mg, >2 ปี: 40 mg วันละ 4 ครั้ง', 'ปลอดภัยสูง เคี้ยวก่อนกลืน', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-016', 'Hyoscine butylbromide', 'Buscopan', '10 mg', 'Tablet', 'เม็ด', 2, 5, 300, true, 'ก', 'เด็ก 6-12 ปี: 10 mg วันละ 3 ครั้ง', 'ระวังต้อหินมุมปิด ต่อมลูกหมากโต ปัสสาวะคั่ง', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-017', 'Oral Rehydration Salts (ORS)', 'Oreda R.O.', 'ซองสำหรับน้ำ 250 mL', 'Powder', 'ซอง', 3, 8, 200, true, 'ก', 'จิบบ่อยๆ ทดแทนการสูญเสียน้ำตามปริมาณถ่าย', 'ระวังในผู้ป่วยโรคไต ไตวาย หัวใจล้มเหลว', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-018', 'Domperidone', 'Motilium', '10 mg', 'Tablet', 'เม็ด', 0.6, 2.5, 400, true, 'ก', '0.25 mg/kg/dose วันละ 3 ครั้งก่อนอาหาร', 'ระวัง QT prolongation หลีกเลี่ยงใช้ร่วมกับยาที่ยืด QT', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-019', 'Amlodipine', 'Norvasc', '5 mg', 'Tablet', 'เม็ด', 0.5, 3, 500, true, 'ก', '0.1-0.3 mg/kg/day (เริ่ม 2.5 mg ในเด็กโต)', 'ระวังข้อเท้าบวม ความดันตก Interaction กับ Simvastatin', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-020', 'Enalapril', 'Anapril', '5 mg', 'Tablet', 'เม็ด', 0.6, 3, 400, true, 'ก', '0.1 mg/kg/day แบ่ง 1-2 ครั้ง', 'ห้ามใช้ในหญิงตั้งครรภ์ ระวังไอแห้ง โพแทสเซียมสูง', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-021', 'Metformin', 'Glucophage', '500 mg', 'Tablet', 'เม็ด', 0.6, 2.5, 500, true, 'ก', 'ไม่แนะนำในเด็กเว้นแต่ T2DM เฉพาะทาง', 'ห้ามใช้ถ้า eGFR <30 ระวัง Lactic acidosis ดื่มแอลกอฮอล์', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-022', 'Lorazepam', 'Ativan', '0.5 mg', 'Tablet', 'เม็ด', 1, 4, 200, true, 'ง', 'เฉพาะกรณีพิเศษตามคำสั่งแพทย์', 'วัตถุออกฤทธิ์ต่อจิตประสาท เสพติด กดการหายใจ', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-023', 'Diclofenac Gel', 'Voltaren Emulgel', '1% (20 g)', 'Topical Gel', 'หลอด', 40, 90, 30, true, 'ก', 'ทาบางๆ วันละ 3-4 ครั้ง (อายุ >12 ปี)', 'ห้ามทาแผลเปิด ระวังแพ้ยา NSAIDs แบบทา', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-024', 'Triamcinolone acetonide', 'Kanolone Oral Paste', '0.1% (5 g)', 'Oral Paste', 'ซอง/หลอด', 18, 45, 40, true, 'ก', 'ป้ายแผลในปากก่อนนอนหรือวันละ 2-3 ครั้ง', 'ห้ามใช้กรณีติดเชื้อราหรือไวรัสในช่องปาก', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false),
      (target_facility_id, 'MED-025', 'Povidone Iodine', 'Betadine Solution', '10% (30 mL)', 'Antiseptic Solution', 'ขวด', 22, 45, 30, true, 'ก', 'ทาทำความสะอาดบาดแผลภายนอก', 'ระวังการแพ้ไอโอดีน ไม่ใช้กับแผลไฟไหม้บริเวณกว้าง', 'clinic_formulary_and_procedures_seed.xlsx', false, null, 'not_configured', false)
  on conflict (facility_id, item_code) do nothing;

  -- Additive rows from the comprehensive workbook. MED-COMP-* codes avoid
  -- colliding with the earlier workbook's MED-* codes; the source code is
  -- retained in source_file. Existing catalog entries are never overwritten.
  insert into public.clinic_medications (
    facility_id, item_code, generic_name, trade_name, strength, dosage_form,
    dispensing_unit, cost_price, selling_price, stock_qty, nlem_marked,
    nlem_category, pediatric_dose_notes, precaution_interaction_notes,
    source_file, nlem_verified, pediatric_dose_source,
    pediatric_dose_basis, pediatric_auto_calculation_enabled
  )
  values
      (target_facility_id, 'MED-COMP-003', 'Paracetamol Forte Syrup', 'Sara Forte / Tempra', '250 mg/5 mL', 'Syrup (60 mL)', 'ขวด', 16, 45, 60, true, 'ก', '10-15 mg/kg/dose q 4-6 hr (เด็กโต)', 'ระวังสับสนกับสูตร 120 mg/5 mL', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-003)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-004', 'Paracetamol Infant Drops', 'Tempra Drops', '100 mg/mL', 'Drops (15 mL)', 'ขวด', 28, 70, 30, true, 'ก', '10-15 mg/kg/dose ใช้ดรอปเปอร์เฉพาะขวด', 'ความเข้มข้นสูงมาก ห้ามใช้ช้อนตวงเด็ดขาด', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-004)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-010', 'Amoxicillin + Clavulanate Suspension', 'Augmentin Dry Syrup', '228.5 mg/5 mL (200/28.5)', 'Dry Syrup (70 mL)', 'ขวด', 95, 190, 25, true, 'ข', '25-45 mg/kg/day (base Amox) แบ่ง 2 ครั้ง q 12 hr', 'หลังผสมน้ำเก็บในตู้เย็นได้ 7 วัน เขย่าขวดก่อนใช้', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-010)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-011', 'Cephalexin Dry Syrup', 'Ibilex Syrup', '125 mg/5 mL', 'Dry Syrup (60 mL)', 'ขวด', 32, 80, 30, true, 'ก', '25-50 mg/kg/day แบ่ง 3-4 ครั้ง', 'ระวังประวัติแพ้ Penicillin รุนแรง (Cross-allergy ~1-3%)', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-011)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-012', 'Azithromycin Dry Syrup', 'Zithromax Dry Syrup', '200 mg/5 mL', 'Dry Syrup (15 mL)', 'ขวด', 120, 240, 20, true, 'ข', '10 mg/kg/day วันละ 1 ครั้ง นาน 3-5 วัน', 'ระวัง QT prolongation ทานก่อนอาหาร 1 ชม. หรือหลัง 2 ชม.', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-012)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-016', 'Chlorpheniramine Syrup', 'CPM Syrup', '2 mg/5 mL', 'Syrup (60 mL)', 'ขวด', 12, 35, 40, true, 'ก', '0.35 mg/kg/day แบ่ง 3-4 ครั้ง', 'ระวังอาการง่วงซึม ปากแห้ง ตาพร่า', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-016)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-017', 'Bromhexine Syrup', 'Bisolvon Syrup', '4 mg/5 mL', 'Syrup (60 mL)', 'ขวด', 28, 70, 40, true, 'ก', 'เด็ก 2-6 ปี: 2.5 mL วันละ 3 ครั้ง, >6 ปี: 5 mL วันละ 3 ครั้ง', 'ระวังในผู้ป่วยแผลในกระเพาะอาหาร', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-017)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-019', 'Salbutamol Syrup', 'Ventolin Syrup', '2 mg/5 mL', 'Syrup (60 mL)', 'ขวด', 18, 50, 40, true, 'ก', '0.1-0.2 mg/kg/dose วันละ 3 ครั้ง', 'ระวังใจสั่น มือสั่น หัวใจเต้นเร็ว โพแทสเซียมต่ำ', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-019)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-020', 'Domperidone Suspension', 'Motilium-M Suspension', '5 mg/5 mL (1 mg/mL)', 'Suspension (30 mL)', 'ขวด', 28, 75, 30, true, 'ก', '0.25 mg/kg/dose วันละ 3 ครั้งก่อนอาหาร 15-30 นาที', 'ระวัง QT prolongation ห้ามใช้ร่วมกับยาที่ยืด QT interval', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-020)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-022', 'Zinc Sulfate Monohydrate Syrup', 'Zinc Syrup', '20 mg elemental Zinc/5 mL', 'Syrup (60 mL)', 'ขวด', 35, 80, 30, true, 'ก', 'เด็ก <6 เดือน: 10 mg/day, >6 เดือน: 20 mg/day นาน 10-14 วัน', 'เสริมการรักษาท้องเสียเฉียบพลันในเด็ก ช่วยฟื้นฟูลำไส้', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-022)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-023', 'Simethicone Drops', 'Air-X Drops', '40 mg/0.6 mL', 'Drops (15 mL)', 'ขวด', 30, 75, 30, true, 'ก', 'ทารกและเด็ก <2 ปี: 0.3 mL, >2 ปี: 0.6 mL หลังอาหาร/ก่อนนอน', 'ปลอดภัยสูง ไม่ดูดซึมเข้าร่างกาย ขับลมแน่นท้องเด็ก', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-023)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-029', 'Salbutamol Nebules', 'Ventolin Nebules', '2.5 mg/2.5 mL', 'Inhalation Solution (Nebule)', 'หลอด', 8, 30, 100, true, 'ก', '0.15 mg/kg/dose (Min 1.25 mg, Max 5 mg) ผสม NSS พ่น q 20 min', 'ระวังหัวใจเต้นเร็ว ใจสั่น มือสั่น โพแทสเซียมต่ำ', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-029)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-030', 'Ipratropium + Salbutamol Nebules', 'Combivent Nebules', '0.5 mg/2.5 mg per 2.5 mL', 'Inhalation Solution (Nebule)', 'หลอด', 15, 45, 80, true, 'ข', 'เด็ก: 1/2 ถึง 1 หลอด พ่นร่วมกับออกซิเจนหรือเครื่องพ่น', 'ระวังต้อหินมุมปิด ปัสสาวะคั่ง หัวใจเต้นผิดจังหวะ', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-030)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-031', 'Budesonide Respules', 'Pulmicort Respules', '0.5 mg/2 mL', 'Inhalation Suspension (Respule)', 'หลอด', 25, 65, 50, true, 'ข', 'เด็ก: 0.25-0.5 mg วันละ 1-2 ครั้ง (Croup หรือ Severe Asthma)', 'บ้วนปากล้างหน้าหลังพ่นป้องกันเชื้อราและผิวระคายเคือง', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-031)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-032', 'Salbutamol MDI', 'Ventolin Inhaler', '100 mcg/dose (200 doses)', 'Metered Dose Inhaler (MDI)', 'เครื่อง', 110, 220, 20, true, 'ก', '1-2 puffs q 4-6 hr ตามอาการ (เด็กควรใช้ร่วมกับ Spacer)', 'เขย่าก่อนพ่นทุกครั้ง ระวังหัวใจเต้นเร็ว', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-032)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-033', 'Adrenaline (Epinephrine) Inj', 'Adrenaline Injection', '1 mg/mL (1:1000)', 'Injection Ampoule (1 mL)', 'แอมพูล', 10, 35, 30, true, 'ก', 'Anaphylaxis: 0.01 mg/kg (0.01 mL/kg) IM ต้นขาด้านนอก (Max 0.3-0.5 mg)', 'ยาช่วยชีวิตฉุกเฉิน ห้ามฉีดเข้าหลอดเลือดดำโดยตรงโดยไม่เจือจาง', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-033)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-034', 'Dexamethasone Inj', 'Dexamethasone Injection', '4 mg/mL (1 mL)', 'Injection Ampoule (1 mL)', 'แอมพูล', 8, 30, 50, true, 'ก', '0.15-0.6 mg/kg/dose IV/IM (ใช้ใน Croup/Severe Allergy)', 'ระวังน้ำตาลในเลือดสูง แผลในกระเพาะ กดภูมิคุ้มกัน', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-034)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-035', 'Hydrocortisone Inj', 'Solu-Cortef', '100 mg', 'Injection Vial', 'ไวอัล', 45, 120, 20, true, 'ก', 'Anaphylaxis/Shock: 4-8 mg/kg IV stat', 'ระวังการติดเชื้อรุนแรง ปรับสมดุลอิเล็กโทรไลต์', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-035)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-036', 'Chlorpheniramine Inj', 'CPM Injection', '10 mg/mL (1 mL)', 'Injection Ampoule (1 mL)', 'แอมพูล', 6, 25, 50, true, 'ก', '0.2-0.3 mg/kg/dose IM หรือ Slow IV (Max 10 mg)', 'ง่วงซึม ความดันตกหากฉีด IV เร็วเกินไป', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-036)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-037', 'Diclofenac Inj', 'Voltaren Injection', '75 mg/3 mL', 'Injection Ampoule (3 mL)', 'แอมพูล', 9, 35, 50, true, 'ก', 'ห้ามใช้ในเด็ก <12 ปี (ผู้ใหญ่: 75 mg Deep IM ก้น)', 'ห้ามฉีด IV, ห้ามใช้ในโรคไต/แผลกระเพาะ/สงสัยไข้เลือดออก', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-037)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-038', 'Tramadol Inj', 'Tramadol Injection', '50 mg/mL (2 mL)', 'Injection Ampoule (2 mL)', 'แอมพูล', 10, 35, 30, true, 'ง', 'เด็ก >12 ปี: 1 mg/kg Slow IV/IM (ระวังชัก)', 'ห้ามฉีด IV เร็ว คลื่นไส้อาเจียนสูง กดการหายใจ เสพติด', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-038)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-039', 'Hyoscine butylbromide Inj', 'Buscopan Injection', '20 mg/mL (1 mL)', 'Injection Ampoule (1 mL)', 'แอมพูล', 15, 45, 30, true, 'ก', 'เด็ก >6 ปี: 0.3-0.6 mg/kg/dose Slow IV/IM', 'ระวังต้อหิน หัวใจเต้นเร็ว ปัสสาวะไม่ออก', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-039)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-040', 'Metoclopramide Inj', 'Plasil Injection', '10 mg/2 mL', 'Injection Ampoule (2 mL)', 'แอมพูล', 6, 25, 40, true, 'ก', '0.1-0.15 mg/kg/dose Slow IV/IM q 8 hr', 'ระวัง Extrapyramidal symptoms (EPS) กล้ามเนื้อเกร็งกระตุกในเด็ก', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-040)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-041', 'Furosemide Inj', 'Lasix Injection', '20 mg/2 mL', 'Injection Ampoule (2 mL)', 'แอมพูล', 8, 30, 20, true, 'ก', '0.5-1 mg/kg/dose Slow IV/IM (Max 2 mg/kg)', 'ระวังความดันตก โพแทสเซียมต่ำ ขาดน้ำรุนแรง', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-041)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-042', 'Diazepam Inj', 'Valium Injection', '10 mg/2 mL', 'Injection Ampoule (2 mL)', 'แอมพูล', 12, 40, 20, true, 'ง', 'Status epilepticus: 0.2-0.5 mg/kg Slow IV หรือสวนทวาร (Max 10 mg)', 'วัตถุออกฤทธิ์ต่อจิตประสาท กดการหายใจ เตรียมแอมบูแบ็กให้พร้อม', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-042)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-043', 'Lidocaine HCl 2% Inj', 'Xylocaine 2%', '2% (20 mg/mL) (50 mL)', 'Injection Vial (Local Anesthetic)', 'ไวอัล', 45, 120, 15, true, 'ก', 'Max 4.5 mg/kg (ยาชาเฉพาะที่สำหรับเย็บแผล/ผ่าตัดเล็ก)', 'ห้ามฉีดเข้าหลอดเลือดดำ ระวังพิษต่อระบบประสาทและหัวใจ', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-043)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-044', '0.9% Normal Saline (NSS)', 'NSS for Irrigation / IV', '1000 mL', 'IV / Irrigation Bottle', 'ขวด', 30, 60, 30, true, 'ก', 'ล้างแผล หรือให้สารน้ำทดแทนตามข้อบ่งชี้แพทย์', 'เก็บในที่สะอาด ตรวจสอบความใสก่อนใช้', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-044)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-045', '0.9% Normal Saline Miniflasco', 'NSS for Inhalation', '10 mL', 'Plastic Ampoule', 'แอมพูล', 5, 15, 100, true, 'ก', 'ใช้ละลายยาพ่น 2-4 mL หรือล้างจมูกเด็กเล็ก', 'ปราศจากเชื้อ เปิดแล้วควรใช้ครั้งเดียวทิ้ง', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-045)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-046', 'Chloramphenicol Eye Drops', 'Opsar / Archifen', '0.5% (10 mL)', 'Eye Drops', 'ขวด', 18, 45, 30, true, 'ก', 'หยอดตา 1-2 หยด วันละ 4-6 ครั้ง นาน 5-7 วัน', 'เปิดแล้วมีอายุ 30 วัน ห้ามใช้ในคนแพ้คลอแรมเฟนิคอล', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-046)', false, null, 'not_configured', false),
      (target_facility_id, 'MED-COMP-047', 'Sodium Chloride 0.9% Nasal Drops', 'Hashi / Nasic Cleanse Drops', '0.9% (15 mL)', 'Nasal Drops / Spray', 'ขวด', 25, 60, 30, true, 'ก', 'หยอด/พ่นจมูกข้างละ 2-3 หยด ก่อนดูดน้ำมูกเด็กทารก', 'ปลอดภัยสูง ช่วยละลายน้ำมูกเหนียวข้น', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code MED-047)', false, null, 'not_configured', false)
  on conflict (facility_id, item_code) do nothing;

  insert into public.clinic_procedures (
    facility_id, procedure_code, name_th, name_en, standard_price,
    billing_unit, icd9_cm_reference, remarks, source_file, reference_verified
  )
  values
      (target_facility_id, 'PROC-001', 'ตรวจรักษาโรคทั่วไปโดยแพทย์', 'General Consultation / OPD Examination', 150, 'ครั้ง', '89.07', 'ไม่รวมค่ายาและค่าตรวจทางห้องปฏิบัติการ', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-002', 'ตรวจวัดระดับน้ำตาลปลายนิ้ว', 'Capillary Blood Glucose (DTX)', 80, 'ครั้ง', '90.59', 'รวมเข็มและแถบตรวจ', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-003', 'พ่นยาขยายหลอดลม', 'Nebulizer Therapy', 150, 'ครั้ง', '93.94', 'รวมยา Salbutamol/Berodual + Mask', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-004', 'ล้างแผล / ทำแผลขนาดเล็ก (< 5 ซม.)', 'Simple Wound Dressing (<5 cm)', 100, 'ครั้ง', '93.57', 'รวมชุดทำแผลและน้ำยาฆ่าเชื้อ', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-005', 'ล้างแผล / ทำแผลขนาดใหญ่หรือแผลซับซ้อน', 'Complex Wound Dressing (>=5 cm)', 200, 'ครั้ง', '93.57', 'แผลอุบัติเหตุหรือแผลเบาหวาน', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-006', 'เย็บแผลสด (1-3 เข็มแรก)', 'Wound Suture (1-3 stitches)', 350, 'ครั้ง', '86.59', 'รวมยาชาเฉพาะที่ 2% Lidocaine และอุปกรณ์เย็บ', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-007', 'เย็บแผลสด (เข็มถัดไป ต่อเข็ม)', 'Additional Suture (per stitch)', 50, 'เข็ม', '86.59', 'คิดเพิ่มต่อเข็มตั้งแต่เข็มที่ 4 เป็นต้นไป', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-008', 'ตัดไหมแผลเย็บ', 'Suture Removal', 80, 'ครั้ง', '97.83', 'รวมตรวจประเมินแผลและการทำความสะอาด', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-009', 'ฉีดยาเข้ากล้ามเนื้อ / ชั้นไขมัน (ไม่รวมค่ายา)', 'IM / SC Injection Fee', 50, 'ครั้ง', '99.29', 'ค่าบริการฉีดยา ไม่รวมราคายาที่นำมาหรือเบิกคลินิก', 'clinic_formulary_and_procedures_seed.xlsx', false),
      (target_facility_id, 'PROC-010', 'ตรวจร่างกายออกใบรับรองแพทย์ทั่วไป', 'Medical Certificate Physical Exam', 250, 'ฉบับ', '89.38', 'สมัครงาน / ใบขับขี่ / เข้าศึกษา', 'clinic_formulary_and_procedures_seed.xlsx', false)
  on conflict (facility_id, procedure_code) do nothing;
  -- Additive procedures from the comprehensive workbook. Source codes are
  -- retained in source_file to avoid collisions with the first workbook.
  insert into public.clinic_procedures (
    facility_id, procedure_code, name_th, name_en, standard_price,
    billing_unit, icd9_cm_reference, remarks, source_file, reference_verified
  )
  values
      (target_facility_id, 'PROC-COMP-009', 'ผ่าระบายฝี / ก้อนหนองขนาดเล็ก', 'Incision and Drainage (I&D)', 450, 'ครั้ง', '86.04', 'รวมยาชาเฉพาะที่ กรีดระบายหนอง ใส่ก๊อซระบาย', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code PROC-009)', false),
      (target_facility_id, 'PROC-COMP-010', 'ถอดเล็บ / ถอดเล็บขบ (บางส่วนหรือทั้งแผ่น)', 'Nail Avulsion / Partial Nail Extraction', 400, 'นิ้ว', '86.23', 'รวมฉีดยาชาเฉพาะที่ Digital block และทำแผล', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code PROC-010)', false),
      (target_facility_id, 'PROC-COMP-011', 'คีบสิ่งแปลกปลอมออกจากหู / จมูก / ตา (ไม่ซับซ้อน)', 'Foreign Body Removal (Ear/Nose/Eye)', 250, 'ครั้ง', '98.11', 'กรณีไม่ซับซ้อน หากติดลึกแนะนำส่งต่อเฉพาะทาง', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code PROC-011)', false),
      (target_facility_id, 'PROC-COMP-012', 'ล้างจมูกและดูดเสมหะ / น้ำมูกเด็กเล็ก', 'Nasal Irrigation & Suctioning', 120, 'ครั้ง', '96.29', 'รวมน้ำเกลือ NSS และสาย suction/ลูกยางแดง', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code PROC-012)', false),
      (target_facility_id, 'PROC-COMP-014', 'เปิดเส้นให้น้ำเกลือ / ยาฉีดเข้าเส้นเลือดดำ', 'IV Cannulation & Infusion Setup', 150, 'ครั้ง', '99.21', 'รวมสาย IV catheter, IV set (ไม่รวมขวดน้ำเกลือ)', 'comprehensive_clinic_formulary_and_procedures.xlsx (source item code PROC-014)', false)
  on conflict (facility_id, procedure_code) do nothing;
end
$$;
commit;
