-- MG Store — seed de categorías y marcas (matchean el hardcode del frontend).
-- Idempotente: on conflict do nothing.

insert into mgstore.categories (slug, name, sort_order) values
  ('drones',            'Drones',              10),
  ('vehiculos-rc',      'Vehículos RC',        20),
  ('bloques-armables',  'Bloques y armables',  30),
  ('juegos',            'Juegos',              40),
  ('tecnologia',        'Tecnología',          50),
  ('audio',             'Audio',               60),
  ('foto-video',        'Foto y video',        70),
  ('herramientas',      'Herramientas',        80),
  ('hogar-mascotas',    'Hogar y mascotas',    90),
  ('cuidado-personal',  'Cuidado personal',   100)
on conflict (slug) do nothing;

insert into mgstore.brands (slug, name, on_dark_bg, sort_order) values
  ('ecopower',   'Ecopower',   false, 10),
  ('satellite',  'Satellite',  true,  20), -- SATE con fondo oscuro
  ('luo',        'LUO',        false, 30),
  ('mould-king', 'Mould King', false, 40),
  ('jie-star',   'Jie Star',   false, 50),
  ('apengbaol',  'Apengbaol',  false, 60),
  ('luk',        'LUK',        false, 70)
on conflict (slug) do nothing;
