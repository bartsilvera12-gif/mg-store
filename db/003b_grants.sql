-- MG Store — GRANTS para exponer el schema mgstore vía PostgREST.
-- Sin esto la API de Supabase no ve las tablas aunque el schema esté "exposed".

grant usage on schema mgstore to anon, authenticated, service_role;
grant select                       on all tables    in schema mgstore to anon, authenticated;
grant insert, update, delete       on all tables    in schema mgstore to authenticated;
grant all                          on all tables    in schema mgstore to service_role;
grant all                          on all sequences in schema mgstore to authenticated, service_role;
grant execute                      on all functions in schema mgstore to anon, authenticated, service_role;

alter default privileges in schema mgstore grant select on tables    to anon, authenticated;
alter default privileges in schema mgstore grant all    on tables    to service_role;
alter default privileges in schema mgstore grant all    on sequences to authenticated, service_role;
