# MG Store — DB (Supabase self-hosted)

Todo el schema y las políticas para arrancar el backend en una instancia de
Supabase (self-hosted o cloud, es la misma API). Los scripts son idempotentes:
correlos varias veces sin miedo.

## Orden de ejecución

En Supabase Studio → **SQL Editor** pegá y ejecutá cada archivo en este orden:

1. `001_schema.sql` — extensiones, tablas (`categories`, `brands`, `products`,
   `orders`, `order_items`), índices, trigger `updated_at`, helper `is_admin()`.
2. `002_rls.sql` — Row Level Security. Público lee catálogo activo y crea
   pedidos; sólo admin escribe catálogo y lee/actualiza pedidos.
3. `003_storage.sql` — bucket público `mg-media` para fotos y logos, con
   escritura sólo admin.
4. `004_seed_taxonomy.sql` — carga las 10 categorías y 7 marcas del sitio.
5. `005_seed_products.sql` — 62 productos con precios, stock y foto local
   (`img/NN.webp`). Migralos a storage cuando quieras (ver más abajo).

## Cómo crear el usuario admin

En Studio → **Authentication → Users → Add user** creá tu cuenta con email +
password. Después, en la fila del usuario abrí *Metadata* y en
**Raw app metadata** (no user metadata) pegá:

```json
{ "role": "admin" }
```

Guardá. La función `public.is_admin()` chequea `auth.jwt().app_metadata.role`,
así que cualquier fila de RLS con `using (public.is_admin())` va a permitir
tus queries autenticadas. También cae por default a `user_metadata.role` si
preferís setearlo desde el cliente.

## Cómo consumirlo desde el frontend

En el sitio (o en `admin.html`) cargá el SDK de Supabase por CDN:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  const supabase = window.supabase.createClient(
    'https://TU-SUPABASE-URL',
    'TU_ANON_KEY_PUBLICA'
  );
</script>
```

Ejemplos:

```js
// Catálogo público (sin login) — RLS filtra por active=true
const { data: products } = await supabase
  .from('products')
  .select('id, name, price_gs, image_url, stock, brand:brands(name), category:categories(name)')
  .eq('active', true)
  .order('sort_order');

// Crear pedido desde el checkout de WhatsApp
const { data: order } = await supabase
  .from('orders')
  .insert({ customer_phone: '0974864605', source: 'whatsapp', total_gs: 300000 })
  .select().single();
await supabase.from('order_items').insert([
  { order_id: order.id, product_id, product_name, quantity: 2, unit_price_gs: 150000, subtotal_gs: 300000 }
]);

// Login admin (usás el email/password de arriba)
await supabase.auth.signInWithPassword({ email, password });
// Ahora las inserts/updates de products, brands, categories pasan RLS.
```

## Migrar imágenes locales → Storage

El seed apunta a `img/NN.webp` (los assets del repo). Cuando quieras servir
todo desde Supabase Storage:

1. Desde Studio → **Storage → mg-media** subí los `img/*.webp` (mantené la
   estructura o llamalos con el slug del producto).
2. Actualizá `image_url` en `products` a la URL pública del bucket:
   `https://TU-SUPABASE-URL/storage/v1/object/public/mg-media/<archivo>`.

Podés hacer el update en batch con SQL si mantenés los nombres:

```sql
update public.products
   set image_url = replace(image_url, 'img/', 'https://TU-URL/storage/v1/object/public/mg-media/');
```

## Cheatsheet de tablas

| tabla | qué guarda |
|---|---|
| `categories` | universos de producto (Drones, RC, etc.) |
| `brands` | marcas (Ecopower, LUO, …) con `on_dark_bg` para logos claros |
| `products` | precio en gs (`price_gs`), stock, `image_url`, gallery jsonb |
| `orders` | pedido, cliente, source ('whatsapp'/'web'), status |
| `order_items` | 1..N items por orden con snapshot de nombre y precio |

Las columnas `_gs` son enteros: guardá en guaraníes (no centavos). El helper
`gs()` del frontend hace el format.
