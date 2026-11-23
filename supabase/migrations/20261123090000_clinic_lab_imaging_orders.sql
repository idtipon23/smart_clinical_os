-- Lab / imaging catalogs (empty, ready to receive clinic data) and OPD order columns.
-- Run after 20261119152000_clinic_catalogs_and_opd_orders.sql. Safe to re-run.
begin;

create table if not exists public.clinic_lab_tests (
  id uuid primary key default gen_random_uuid(),
  facility_id text not null,
  test_code text not null,
  name_th text not null,
  name_en text,
  specimen text,
  standard_price numeric(12, 2),
  billing_unit text,
  remarks text,
  source_file text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (facility_id, test_code),
  check (standard_price is null or standard_price >= 0)
);

create table if not exists public.clinic_imaging_tests (
  id uuid primary key default gen_random_uuid(),
  facility_id text not null,
  test_code text not null,
  name_th text not null,
  name_en text,
  modality text,
  body_part text,
  standard_price numeric(12, 2),
  billing_unit text,
  remarks text,
  source_file text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (facility_id, test_code),
  check (standard_price is null or standard_price >= 0)
);

create index if not exists clinic_lab_tests_facility_active_name_idx
  on public.clinic_lab_tests (facility_id, is_active, name_th);
create index if not exists clinic_imaging_tests_facility_active_name_idx
  on public.clinic_imaging_tests (facility_id, is_active, name_th);

alter table public.opd_visits
  add column if not exists lab_orders jsonb not null default '[]'::jsonb,
  add column if not exists imaging_orders jsonb not null default '[]'::jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'opd_visits_lab_orders_array_check'
      and conrelid = 'public.opd_visits'::regclass
  ) then
    alter table public.opd_visits
      add constraint opd_visits_lab_orders_array_check
      check (jsonb_typeof(lab_orders) = 'array');
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'opd_visits_imaging_orders_array_check'
      and conrelid = 'public.opd_visits'::regclass
  ) then
    alter table public.opd_visits
      add constraint opd_visits_imaging_orders_array_check
      check (jsonb_typeof(imaging_orders) = 'array');
  end if;
end
$$;

alter table public.clinic_lab_tests enable row level security;
grant select, insert, update, delete on public.clinic_lab_tests to authenticated;

drop policy if exists clinic_lab_tests_read_facility on public.clinic_lab_tests;
create policy clinic_lab_tests_read_facility
  on public.clinic_lab_tests
  for select to authenticated
  using (
    exists (
      select 1 from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_lab_tests.facility_id
    )
  );

drop policy if exists clinic_lab_tests_manage_facility on public.clinic_lab_tests;
create policy clinic_lab_tests_manage_facility
  on public.clinic_lab_tests
  for all to authenticated
  using (
    exists (
      select 1 from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_lab_tests.facility_id
        and staff.role in ('ADMIN', 'DOCTOR')
    )
  )
  with check (
    exists (
      select 1 from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_lab_tests.facility_id
        and staff.role in ('ADMIN', 'DOCTOR')
    )
  );

alter table public.clinic_imaging_tests enable row level security;
grant select, insert, update, delete on public.clinic_imaging_tests to authenticated;

drop policy if exists clinic_imaging_tests_read_facility on public.clinic_imaging_tests;
create policy clinic_imaging_tests_read_facility
  on public.clinic_imaging_tests
  for select to authenticated
  using (
    exists (
      select 1 from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_imaging_tests.facility_id
    )
  );

drop policy if exists clinic_imaging_tests_manage_facility on public.clinic_imaging_tests;
create policy clinic_imaging_tests_manage_facility
  on public.clinic_imaging_tests
  for all to authenticated
  using (
    exists (
      select 1 from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_imaging_tests.facility_id
        and staff.role in ('ADMIN', 'DOCTOR')
    )
  )
  with check (
    exists (
      select 1 from public.staff_profiles as staff
      where staff.id = auth.uid()
        and staff.facility_id::text = clinic_imaging_tests.facility_id
        and staff.role in ('ADMIN', 'DOCTOR')
    )
  );

commit;
