-- MG Store — Row Level Security.
-- Lectura pública para el catálogo, escritura sólo para admin,
-- pedidos: cualquier anon puede insertar (para el checkout), solo admin lee.

alter table mgstore.categories  enable row level security;
alter table mgstore.brands      enable row level security;
alter table mgstore.products    enable row level security;
alter table mgstore.orders      enable row level security;
alter table mgstore.order_items enable row level security;

-- Nada de "if not exists" para policies antes de PG 15+ — dropeamos y recreamos.
drop policy if exists categories_public_read on mgstore.categories;
drop policy if exists categories_admin_write on mgstore.categories;
drop policy if exists brands_public_read     on mgstore.brands;
drop policy if exists brands_admin_write     on mgstore.brands;
drop policy if exists products_public_read   on mgstore.products;
drop policy if exists products_admin_write   on mgstore.products;
drop policy if exists orders_public_insert   on mgstore.orders;
drop policy if exists orders_admin_select    on mgstore.orders;
drop policy if exists orders_admin_update    on mgstore.orders;
drop policy if exists order_items_public_insert on mgstore.order_items;
drop policy if exists order_items_admin_select  on mgstore.order_items;

-- Lectura pública: cualquier fila activa; los admins ven todo.
create policy categories_public_read on mgstore.categories for select
  using (active or mgstore.is_admin());
create policy brands_public_read on mgstore.brands for select
  using (active or mgstore.is_admin());
create policy products_public_read on mgstore.products for select
  using (active or mgstore.is_admin());

-- Escritura: solo admins.
create policy categories_admin_write on mgstore.categories for all
  using (mgstore.is_admin()) with check (mgstore.is_admin());
create policy brands_admin_write on mgstore.brands for all
  using (mgstore.is_admin()) with check (mgstore.is_admin());
create policy products_admin_write on mgstore.products for all
  using (mgstore.is_admin()) with check (mgstore.is_admin());

-- Orders: cualquiera puede crear un pedido (checkout), solo admin lee/actualiza.
create policy orders_public_insert on mgstore.orders for insert
  with check (true);
create policy orders_admin_select on mgstore.orders for select
  using (mgstore.is_admin());
create policy orders_admin_update on mgstore.orders for update
  using (mgstore.is_admin()) with check (mgstore.is_admin());

create policy order_items_public_insert on mgstore.order_items for insert
  with check (true);
create policy order_items_admin_select on mgstore.order_items for select
  using (mgstore.is_admin());
