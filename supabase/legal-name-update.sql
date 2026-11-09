-- Owner-authorized Tilo legal-name correction. Publish and verify both PDFs first.
-- Public URLs and historical consent rows are preserved.
begin;
do $legal_update$
declare
    definition text;
    previous_version constant text := '2026-11-03-24e387172fe8';
    current_version constant text := '2026-11-06-99d6afcc3037';
    expected_md5 constant text := 'df285853067ee17ed9da868843f948fa';
begin
    definition := pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure);
    if position(current_version in definition) > 0 then
        if md5(replace(definition, current_version, previous_version)) <> expected_md5 then
            raise exception 'Unexpected deployed function; review before retrying';
        end if;
        return;
    end if;
    if md5(definition) <> expected_md5 or position(previous_version in definition) = 0 then
        raise exception 'Unexpected deployed function; no changes applied';
    end if;
    execute replace(definition, previous_version, current_version);
    definition := pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure);
    if position(previous_version in definition) > 0
       or md5(replace(definition, current_version, previous_version)) <> expected_md5 then
        raise exception 'Version-only update verification failed';
    end if;
end;
$legal_update$;
select
    position('2026-11-06-99d6afcc3037' in pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure)) > 0 as current_version_present,
    position('2026-11-03-24e387172fe8' in pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure)) = 0 as old_version_removed,
    md5(replace(pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure), '2026-11-06-99d6afcc3037', '2026-11-03-24e387172fe8')) = 'df285853067ee17ed9da868843f948fa' as only_version_changed,
    (select count(*) from public.agreement_consents) as consent_count,
    (select md5(coalesce(string_agg(user_id::text || ':' || version || ':' || adult_confirmed::text || ':' || accepted_at::text, ',' order by user_id,version), '')) from public.agreement_consents) as consents_md5;
commit;
