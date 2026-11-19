begin;

alter table public.patients
  add column if not exists drug_allergy_status text not null default 'unknown',
  add column if not exists drug_allergies jsonb not null default '[]'::jsonb,
  add column if not exists food_allergy_status text not null default 'unknown',
  add column if not exists food_allergies jsonb not null default '[]'::jsonb,
  add column if not exists medication_risk_conditions jsonb not null default '[]'::jsonb;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'patients_drug_allergy_status_check'
      and conrelid = 'public.patients'::regclass
  ) then
    alter table public.patients
      add constraint patients_drug_allergy_status_check
      check (drug_allergy_status in ('unknown', 'none', 'has_allergy'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'patients_food_allergy_status_check'
      and conrelid = 'public.patients'::regclass
  ) then
    alter table public.patients
      add constraint patients_food_allergy_status_check
      check (food_allergy_status in ('unknown', 'none', 'has_allergy'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'patients_medication_history_arrays_check'
      and conrelid = 'public.patients'::regclass
  ) then
    alter table public.patients
      add constraint patients_medication_history_arrays_check
      check (
        jsonb_typeof(drug_allergies) = 'array'
        and jsonb_typeof(food_allergies) = 'array'
        and jsonb_typeof(medication_risk_conditions) = 'array'
        and (
          (drug_allergy_status = 'has_allergy')
          = (jsonb_array_length(drug_allergies) > 0)
        )
        and (
          (food_allergy_status = 'has_allergy')
          = (jsonb_array_length(food_allergies) > 0)
        )
      );
  end if;
end
$$;

commit;
