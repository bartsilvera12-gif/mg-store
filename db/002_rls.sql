-- MG Store — Row Level Security.
-- Lectura pública para el catálogo, escritura sólo para admin,
-- pedidos: cualquier anon puede insertar (para el checkout), solo admin lee.

alter table public.categories  enable row level security;
alter table public.brands      enable row level security;
alter table public.products    enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

-- Nada de "if not exists" para policies antes de PG 15+ — dropeamos y recreamos.
drop policy if exists categories_public_read on public.categories;
drop policy if exists categories_admin_write on public.categories;
drop policy if exists brands_public_read     on public.brands;
drop policy if exists brands_admin_write     on public.brands;
drop policy if exists products_public_read   on public.products;
drop policy if exists products_admin_write   on public.products;
drop policy if exists orders_public_insert   on public.orders;
drop policy if exists orders_admin_select    on public.orders;
drop policy if exists orders_admin_update    on public.orders;
drop policy if exists order_items_public_insert on public.order_items;
drop policy if exists order_items_admin_select  on public.order_items;

-- Lectura pública: cualquier fila activa; los admins ven todo.
create policy categories_public_read on public.categories for select
  using (active or public.is_admin());
create policy brands_public_read on public.brands for select
  using (active or public.is_admin());
create policy products_public_read on public.products for select
  using (active or public.is_admin());

-- Escritura: solo admins.
create policy categories_admin_write on public.categories for all
  using (public.is_admin()) with check (public.is_admin());
create policy brands_admin_write on public.brands for all
  using (public.is_admin()) with check (public.is_admin());
create policy products_admin_write on public.products for all
  using (public.is_admin()) with check (public.is_admin());

-- Orders: cualquiera puede crear un pedido (checkout), solo admin lee/actualiza.
create policy orders_public_insert on public.orders for insert
  with check (true);
create policy orders_admin_select on public.orders for select
  using (public.is_admin());
create policy orders_admin_update on public.orders for update
  using (public.is_admin()) with check (public.is_admin());

create policy order_items_public_insert on public.order_items for insert
  with check (true);
create policy order_items_admin_select on public.order_items for select
  using (public.is_admin());
