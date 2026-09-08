-- MG Store — bucket público 'mg-media' para imágenes de productos, logos y hero.
-- Lectura pública para servir en el frontend; escritura solo admin.

insert into storage.buckets (id, name, public)
values ('mg-media', 'mg-media', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists mg_media_public_read   on storage.objects;
drop policy if exists mg_media_admin_insert  on storage.objects;
drop policy if exists mg_media_admin_update  on storage.objects;
drop policy if exists mg_media_admin_delete  on storage.objects;

create policy mg_media_public_read on storage.objects for select
  using (bucket_id = 'mg-media');

create policy mg_media_admin_insert on storage.objects for insert
  with check (bucket_id = 'mg-media' and public.is_admin());

create policy mg_media_admin_update on storage.objects for update
  using (bucket_id = 'mg-media' and public.is_admin())
  with check (bucket_id = 'mg-media' and public.is_admin());

create policy mg_media_admin_delete on storage.objects for delete
  using (bucket_id = 'mg-media' and public.is_admin());
