-- Promover a admin@mgstore.com al rol admin.
-- El helper mgstore.is_admin() chequea auth.jwt() -> 'app_metadata' -> 'role'.
-- Después de este update tenés que cerrar sesión y volver a entrar en admin.html
-- para que el JWT nuevo traiga el rol.

update auth.users
   set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
 where id = '2accd483-029f-4abb-86fb-bac19d58d4f3';

-- Verificación: debería devolver 'admin' y el email correcto.
select id, email, raw_app_meta_data ->> 'role' as role
  from auth.users
 where id = '2accd483-029f-4abb-86fb-bac19d58d4f3';
