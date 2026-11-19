begin;

alter table public.opd_visits
  add column if not exists encounter_status text,
  add column if not exists consultation_snapshot jsonb,
  add column if not exists closed_at timestamptz;

update public.opd_visits
set encounter_status = 'closed'
where encounter_status is null;

alter table public.opd_visits
  alter column encounter_status set default 'open',
  alter column encounter_status set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'opd_visits_encounter_status_check'
      and conrelid = 'public.opd_visits'::regclass
  ) then
    alter table public.opd_visits
      add constraint opd_visits_encounter_status_check
      check (encounter_status in ('open', 'closed'));
  end if;
end
$$;

create index if not exists opd_visits_open_patient_date_idx
  on public.opd_visits (patient_id, visit_date desc)
  where encounter_status = 'open';

do $$
declare
  visit_id_type text;
  table_name text;
  constraint_name text;
begin
  select format_type(attribute.atttypid, attribute.atttypmod)
  into visit_id_type
  from pg_attribute as attribute
  where attribute.attrelid = 'public.opd_visits'::regclass
    and attribute.attname = 'id'
    and not attribute.attisdropped;

  if visit_id_type is null then
    raise exception 'public.opd_visits.id was not found';
  end if;

  foreach table_name in array array['vital_signs', 'lab_results', 'staff_notes']
  loop
    execute format(
      'alter table public.%I add column if not exists opd_visit_id %s',
      table_name,
      visit_id_type
    );

    constraint_name := table_name || '_opd_visit_id_fkey';
    if not exists (
      select 1
      from pg_constraint
      where conname = constraint_name
        and conrelid = format('public.%I', table_name)::regclass
    ) then
      execute format(
        'alter table public.%I add constraint %I foreign key (opd_visit_id) references public.opd_visits(id) on delete set null',
        table_name,
        constraint_name
      );
    end if;
  end loop;
end
$$;

create index if not exists vital_signs_opd_visit_id_idx
  on public.vital_signs (opd_visit_id)
  where opd_visit_id is not null;

create index if not exists lab_results_opd_visit_id_idx
  on public.lab_results (opd_visit_id)
  where opd_visit_id is not null;

create index if not exists staff_notes_opd_visit_id_idx
  on public.staff_notes (opd_visit_id)
  where opd_visit_id is not null;

commit;
