begin;

create table if not exists public.clinic_medications (
  id uuid primary key default gen_random_uuid(),
  facility_id text not null,
  item_code text not null,
  generic_name text not null,
  trade_name text,
  strength text,
  dosage_form text,
  dispensing_unit text,
  default_dose text,
  route text,
  administration_method text,
  cost_price numeric(12, 2),
  selling_price numeric(12, 2),
  stock_qty numeric(12, 2) not null default 0,
  nlem_marked boolean not null default false,
  nlem_category text,
  nlem_source_year text,
  nlem_verified boolean not null default false,
  pediatric_dose_notes text,
  pediatric_dose_source text,
  pediatric_dose_basis text not null default 'not_configured'
    check (pediatric_dose_basis in (
      'not_configured',
      'actual_body_weight',
      'ideal_body_weight',
      'body_surface_area',
      'age_band',
      'fixed'
    )),
  pediatric_ibw_protocol text,
  pediatric_dose_rule jsonb not null default '{}'::jsonb,
  pediatric_auto_calculation_enabled boolean not null default false,
  precaution_interaction_notes text,
  allergen_group text,
  source_file text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (facility_id, item_code),
  check (cost_price is null or cost_price >= 0),
  check (selling_price is null or selling_price >= 0),
  check (stock_qty >= 0),
  check (
    not pediatric_auto_calculation_enabled
    or (
      pediatric_dose_basis = 'ideal_body_weight'
      and pediatric_dose_source is not null
      and pediatric_ibw_protocol is not null
      and pediatric_dose_rule <> '{}'::jsonb
    )
  )
);

create table if not exists public.clinic_procedures (
  id uuid primary key default gen_random_uuid(),
  facility_id text not null,
  procedure_code text not null,
  name_th text not null,
  name_en text,
  standard_price numeric(12, 2),
  billing_unit text,
  icd9_cm_reference text,
  remarks text,
  source_file text,
  reference_verified boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (facility_id, procedure_code),
  check (standard_price is null or standard_price >= 0)
);

alter table public.opd_visits
  add column if not exists procedures jsonb not null default '[]'::jsonb,
  add column if not exists medication_safety_review jsonb,
  add column if not exists ai_final_review jsonb;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'opd_visits_procedures_array_check'
      and conrelid = 'public.opd_visits'::regclass
  ) then
    alter table public.opd_visits
      add constraint opd_visits_procedures_array_check
      check (jsonb_typeof(procedures) = 'array');
  end if;
end
$$;

create index if not exists clinic_medications_facility_active_name_idx
  on public.clinic_medications (facility_id, is_active, generic_name);

create index if not exists clinic_procedures_facility_active_name_idx
  on public.clinic_procedures (facility_id, is_active, name_th);

alter table public.clinic_medications enable row level security;
alter table public.clinic_procedures enable row level security;

grant select, insert, update, delete on public.clinic_medications to authenticated;
grant select, insert, update, delete on public.clinic_procedures to authenticated;

drop policy if exists clinic_medications_read_facility
  on public.clinic_medications;
create policy clinic_medications_read_facility
  on public.clinic_medications
  for select to authenticated
  using (
    exists (
      select 1
      from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_medications.facility_id
    )
  );

drop policy if exists clinic_medications_manage_facility
  on public.clinic_medications;
create policy clinic_medications_manage_facility
  on public.clinic_medications
  for all to authenticated
  using (
    exists (
      select 1
      from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_medications.facility_id
        and staff.role in ('ADMIN', 'DOCTOR', 'PHARMACIST')
    )
  )
  with check (
    exists (
      select 1
      from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_medications.facility_id
        and staff.role in ('ADMIN', 'DOCTOR', 'PHARMACIST')
    )
  );

drop policy if exists clinic_procedures_read_facility
  on public.clinic_procedures;
create policy clinic_procedures_read_facility
  on public.clinic_procedures
  for select to authenticated
  using (
    exists (
      select 1
      from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_procedures.facility_id
    )
  );

drop policy if exists clinic_procedures_manage_facility
  on public.clinic_procedures;
create policy clinic_procedures_manage_facility
  on public.clinic_procedures
  for all to authenticated
  using (
    exists (
      select 1
      from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_procedures.facility_id
        and staff.role in ('ADMIN', 'DOCTOR', 'PHARMACIST')
    )
  )
  with check (
    exists (
      select 1
      from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_procedures.facility_id
        and staff.role in ('ADMIN', 'DOCTOR', 'PHARMACIST')
    )
  );

commit;
