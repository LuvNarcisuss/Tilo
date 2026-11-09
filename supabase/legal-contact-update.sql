-- Publish and verify the two approved PDFs at their existing URLs before running this script.
begin;
do $legal_update$
declare
    definition text;
    previous_version constant text := '2026-11-06-99d6afcc3037';
    current_version constant text := '2026-11-09-64fc9fdd9c7a';
    expected_md5 constant text := 'c4db78fbb803b30f6318a6084e17cdc0';
begin
    definition := pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure);
    if position(current_version in definition) > 0 then
        if md5(replace(definition, current_version, previous_version)) <> expected_md5 then
            raise exception 'Unexpected function definition after the consent update';
        end if;
        return;
    end if;
    if md5(definition) <> expected_md5 or position(previous_version in definition) = 0 then
        raise exception 'Unexpected deployed function definition';
    end if;
    execute replace(definition, previous_version, current_version);
    definition := pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure);
    if position(previous_version in definition) > 0
       or md5(replace(definition, current_version, previous_version)) <> expected_md5 then
        raise exception 'Consent version update verification failed';
    end if;
end;
$legal_update$;
commit;
