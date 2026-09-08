-- MG Store — schema base (Supabase self-hosted).
-- Idempotente: se puede correr varias veces sin romper.
-- Orden: extensiones -> tablas -> índices -> trigger updated_at -> helper is_admin().

create extension if not exists "uuid-ossp";
create extension if not exists "citext";

-- ---------------------------------------------------------------------------
-- Taxonomías
-- ---------------------------------------------------------------------------

create table if not exists public.categories (
  id            uuid primary key default uuid_generate_v4(),
  slug          citext unique not null,
  name          text not null,
  description   text,
  hero_image_url text,
  sort_order    int  not null default 0,
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table if not exists public.brands (
  id            uuid primary key default uuid_generate_v4(),
  slug          citext unique not null,
  name          text not null,
  logo_url      text,
  on_dark_bg    boolean not null default false, -- si el logo requiere fondo oscuro
  sort_order    int  not null default 0,
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Productos
-- ---------------------------------------------------------------------------

create table if not exists public.products (
  id                 uuid primary key default uuid_generate_v4(),
  slug               citext unique not null,
  name               text not null,
  description        text,
  brand_id           uuid references public.brands(id)     on delete set null,
  category_id        uuid references public.categories(id) on delete set null,
  price_gs           integer not null check (price_gs >= 0),
  wholesale_price_gs integer          check (wholesale_price_gs is null or wholesale_price_gs >= 0),
  stock              integer not null default 0 check (stock >= 0),
  featured           boolean not null default false,
  image_url          text,
  gallery            jsonb   not null default '[]'::jsonb,   -- URLs extra
  sort_order         int     not null default 0,
  active             boolean not null default true,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index if not exists idx_products_category on public.products(category_id);
create index if not exists idx_products_brand    on public.products(brand_id);
create index if not exists idx_products_active   on public.products(active) where active;
create index if not exists idx_products_featured on public.products(featured) where featured;
-- Búsqueda por texto simple sobre name (Postgres FTS con Spanish si querés)
create index if not exists idx_products_name_trgm on public.products
  using gin (name gin_trgm_ops);
create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------------
-- Pedidos (para trackear los que llegaron por WhatsApp o para checkout futuro)
-- ---------------------------------------------------------------------------

create table if not exists public.orders (
  id             uuid primary key default uuid_generate_v4(),
  order_number   bigserial unique,
  customer_name  text,
  customer_phone text,
  customer_email citext,
  source         text not null default 'whatsapp' check (source in ('whatsapp','web','admin')),
  status         text not null default 'pending'  check (status in ('pending','contacted','paid','delivered','cancelled')),
  subtotal_gs    integer not null default 0,
  total_gs       integer not null default 0,
  notes          text,
  raw_payload    jsonb, -- si el frontend quiere guardar los items sin resolver todavía
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table if not exists public.order_items (
  id             uuid primary key default uuid_generate_v4(),
  order_id       uuid not null references public.orders(id) on delete cascade,
  product_id     uuid references public.products(id) on delete set null,
  product_name   text not null,      -- snapshot
  brand_name     text,               -- snapshot
  quantity       integer not null default 1 check (quantity > 0),
  unit_price_gs  integer not null,
  subtotal_gs    integer not null,
  created_at     timestamptz not null default now()
);

create index if not exists idx_order_items_order on public.order_items(order_id);
create index if not exists idx_orders_status     on public.orders(status);
create index if not exists idx_orders_created    on public.orders(created_at desc);

-- ---------------------------------------------------------------------------
-- Trigger updated_at
-- ---------------------------------------------------------------------------

create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  for t in select unnest(array['categories','brands','products','orders'])
  loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format(
      'create trigger set_updated_at before update on public.%I ' ||
      'for each row execute function public.tg_set_updated_at()', t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Helper is_admin(): un usuario es admin si en su JWT (app_metadata.role)
-- vale 'admin'. Se setea con supabase-cli o desde Studio en el user metadata.
-- ---------------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean language sql stable as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin',
    false
  );
$$;
