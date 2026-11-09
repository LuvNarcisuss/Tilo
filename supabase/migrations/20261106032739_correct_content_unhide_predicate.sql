do $fix$
declare source text;
begin
select pg_get_functiondef('private.toli_safety(text,jsonb)'::regprocedure) into source;
if position('h.kind=toli_safety.kind' in source)=0 then raise exception 'Inspect current unhide predicate before patching'; end if;
source:=replace(source,'h.kind=toli_safety.kind','h.kind=(body->>''kind'')');
execute source;
end;
$fix$;
