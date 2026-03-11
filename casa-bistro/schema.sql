-- =====================
-- EXTENSIONS
-- =====================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- =====================
-- PRICE MODE TYPE
-- =====================
do $$
begin
  create type public.menu_price_mode as enum ('fixed', 'variable', 'tbd');
exception
  when duplicate_object then null;
end $$;

-- =====================
-- PROFILES
-- =====================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'staff' check (role in ('admin', 'staff'))
);

alter table public.profiles enable row level security;

-- =====================
-- KITCHENS
-- =====================
create table if not exists public.kitchens (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.kitchens enable row level security;

create table if not exists public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references public.kitchens(id) on delete cascade,
  name text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint menu_categories_name_kitchen_unique unique (name, kitchen_id)
);

alter table public.menu_categories enable row level security;

alter table public.profiles
  add column if not exists kitchen_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_kitchen_id_fkey'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_kitchen_id_fkey
      foreign key (kitchen_id) references public.kitchens(id) on delete set null;
  end if;
end $$;

create index if not exists idx_profiles_kitchen
  on public.profiles(kitchen_id);

insert into public.kitchens (name, slug, description)
values
  ('Cenara Wuse Kitchen', 'cenara-wuse-kitchen', 'Cenara restaurant located in Wuse'),
  ('Bistro Maitama Kitchen', 'bistro-maitama-kitchen', 'Bistro restaurant located in Maitama')
on conflict (slug) do update
set name = excluded.name,
    description = excluded.description;

alter table public.menu_categories
  add column if not exists kitchen_id uuid;

update public.menu_categories
set kitchen_id = (
  select id
  from public.kitchens
  where slug = 'cenara-wuse-kitchen'
  limit 1
)
where kitchen_id is null;

alter table public.menu_categories
  alter column kitchen_id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'menu_categories_kitchen_id_fkey'
      and conrelid = 'public.menu_categories'::regclass
  ) then
    alter table public.menu_categories
      add constraint menu_categories_kitchen_id_fkey
      foreign key (kitchen_id) references public.kitchens(id) on delete cascade;
  end if;
end $$;

alter table public.menu_categories
  drop constraint if exists menu_categories_name_key;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'menu_categories_name_kitchen_unique'
      and conrelid = 'public.menu_categories'::regclass
  ) then
    alter table public.menu_categories
      add constraint menu_categories_name_kitchen_unique unique (name, kitchen_id);
  end if;
end $$;

-- =====================
-- MENU ITEMS
-- =====================
create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),

  category_id uuid references public.menu_categories(id) on delete set null,

  name text not null,
  description text,
  sku text unique,

  price_mode public.menu_price_mode not null default 'fixed',
  price_amount numeric(10,2),

  image_url text,

  is_active boolean not null default true,
  is_featured boolean not null default false,
  is_visible boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint menu_items_price_consistency check (
    (price_mode = 'fixed' and price_amount is not null and price_amount > 0) or
    (price_mode = 'variable' and price_amount is null) or
    (price_mode = 'tbd' and price_amount is null)
  )
);

alter table public.menu_items enable row level security;

-- =====================
-- MENU ITEM PRICE OPTIONS
-- =====================
create table if not exists public.menu_item_price_options (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  label text not null,
  price_amount numeric(10,2) not null check (price_amount > 0),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (item_id, label)
);

alter table public.menu_item_price_options enable row level security;

-- =====================
-- MENU ITEM IMAGES
-- =====================
create table if not exists public.menu_item_images (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  image_url text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.menu_item_images enable row level security;

-- =====================
-- ADDONS
-- =====================
create table if not exists public.menu_addons (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.menu_addons enable row level security;

-- =====================
-- ITEM ADDONS MAPPING
-- =====================
create table if not exists public.menu_item_addons (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  addon_id uuid not null references public.menu_addons(id) on delete cascade,
  unique (item_id, addon_id)
);

alter table public.menu_item_addons enable row level security;

-- =====================
-- PRICE AUDIT LOGS
-- =====================
create table if not exists public.price_audit_logs (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  old_price numeric(10,2),
  new_price numeric(10,2),
  user_id uuid references auth.users(id),
  reason text,
  created_at timestamptz not null default now()
);

alter table public.price_audit_logs enable row level security;

-- =====================
-- INDEXES
-- =====================
create index if not exists idx_menu_categories_sort
  on public.menu_categories(sort_order, name);

create index if not exists idx_menu_items_category
  on public.menu_items(category_id, is_active, is_visible);

create index if not exists idx_menu_items_name
  on public.menu_items(name);

create index if not exists idx_menu_item_price_options_item
  on public.menu_item_price_options(item_id, sort_order, is_active);

create index if not exists idx_price_audit_logs_item_created
  on public.price_audit_logs(item_id, created_at desc);

-- =====================
-- HELPER FUNCTION
-- =====================
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
select exists (
  select 1 from public.profiles
  where id = auth.uid() and role = 'admin'
);
$$;

-- =====================
-- STORAGE SETUP
-- =====================

insert into storage.buckets (id, name, public)
values ('menu-images', 'menu-images', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Public read menu images" on storage.objects;
drop policy if exists "Admins upload menu images" on storage.objects;
drop policy if exists "Admins update menu images" on storage.objects;
drop policy if exists "Admins delete menu images" on storage.objects;

create policy "Public read menu images"
on storage.objects
for select
to public
using (bucket_id = 'menu-images');

create policy "Admins upload menu images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'menu-images'
  and public.is_admin()
);

create policy "Admins update menu images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'menu-images'
  and public.is_admin()
)
with check (
  bucket_id = 'menu-images'
  and public.is_admin()
);

create policy "Admins delete menu images"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'menu-images'
  and public.is_admin()
);

-- =====================
-- RLS POLICIES
-- =====================

drop policy if exists "Admins full access menu_categories" on public.menu_categories;
drop policy if exists "Admins full access menu_items" on public.menu_items;
drop policy if exists "Admins full access menu_item_price_options" on public.menu_item_price_options;
drop policy if exists "Admins full access images" on public.menu_item_images;
drop policy if exists "Admins full access addons" on public.menu_addons;
drop policy if exists "Admins full access item_addons" on public.menu_item_addons;
drop policy if exists "Admins full access price_logs" on public.price_audit_logs;

drop policy if exists "Staff read menu" on public.menu_items;
drop policy if exists "Staff read categories" on public.menu_categories;
drop policy if exists "Staff read price_options" on public.menu_item_price_options;
drop policy if exists "Staff read price_logs" on public.price_audit_logs;
drop policy if exists "Users read own profile" on public.profiles;
drop policy if exists "Users update own profile" on public.profiles;
drop policy if exists "Admins full access profiles" on public.profiles;

create policy "Users read own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "Users update own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id and role = 'staff');

create policy "Admins full access profiles"
on public.profiles
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access menu_categories"
on public.menu_categories
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access menu_items"
on public.menu_items
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access menu_item_price_options"
on public.menu_item_price_options
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access images"
on public.menu_item_images
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access addons"
on public.menu_addons
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access item_addons"
on public.menu_item_addons
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins full access price_logs"
on public.price_audit_logs
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Staff read menu"
on public.menu_items
for select
to authenticated
using (is_active = true);

create policy "Staff read categories"
on public.menu_categories
for select
to authenticated
using (is_active = true);

create policy "Staff read price_options"
on public.menu_item_price_options
for select
to authenticated
using (is_active = true);

create policy "Staff read price_logs"
on public.price_audit_logs
for select
to authenticated
using (true);

-- =====================
-- AUTO PROFILE CREATION
-- =====================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, full_name, role, kitchen_id)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    'staff',
    nullif(new.raw_user_meta_data ->> 'kitchen_id', '')::uuid
  )
  on conflict (id) do update
  set email = excluded.email,
      full_name = excluded.full_name,
      kitchen_id = coalesce(excluded.kitchen_id, public.profiles.kitchen_id);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- =====================
-- AUTO UPDATE updated_at
-- =====================
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at_menu_categories on public.menu_categories;
create trigger set_updated_at_menu_categories
before update on public.menu_categories
for each row execute procedure public.handle_updated_at();

drop trigger if exists set_updated_at_menu_items on public.menu_items;
create trigger set_updated_at_menu_items
before update on public.menu_items
for each row execute procedure public.handle_updated_at();

drop trigger if exists set_updated_at_menu_item_price_options on public.menu_item_price_options;
create trigger set_updated_at_menu_item_price_options
before update on public.menu_item_price_options
for each row execute procedure public.handle_updated_at();

drop trigger if exists set_updated_at_menu_addons on public.menu_addons;
create trigger set_updated_at_menu_addons
before update on public.menu_addons
for each row execute procedure public.handle_updated_at();

-- =====================
-- SEED MENU CATEGORIES
-- =====================
insert into public.menu_categories (name, kitchen_id, sort_order)
select seed.name, kitchen.id, seed.sort_order
from (
  values
    ('Breakfast', 1),
    ('Appetizers', 2),
    ('Sandwiches', 3),
    ('Platters', 4),
    ('Salads', 5),
    ('Entrees (Italian Inspired)', 6),
    ('Sides', 7),
    ('African Cuisine', 8),
    ('Pasta', 9),
    ('Desserts', 10),
    ('Soft Drinks', 11),
    ('Coffee', 12),
    ('Tea', 13),
    ('Milkshakes', 14),
    ('Fresh Juices', 15),
    ('Smoothies', 16),
    ('Wine', 17),
    ('Whiskey', 18),
    ('Champagne', 19),
    ('Vodka', 20),
    ('Beer (Can)', 21),
    ('Cocktails', 22),
    ('Mocktails', 23)
) as seed(name, sort_order)
join public.kitchens kitchen on kitchen.slug = 'cenara-wuse-kitchen'
on conflict (name, kitchen_id) do update
set sort_order = excluded.sort_order,
    is_active = true;

-- =====================
-- SEED MENU ITEMS
-- =====================
insert into public.menu_items (name, description, price_mode, price_amount, sku, category_id)
select
  seed.name,
  seed.description,
  seed.price_mode::public.menu_price_mode,
  seed.price_amount,
  seed.sku,
  c.id
from (
  values
    ('Casa Breakfast Experience', 'A spread of fruits, pastries, hot plate of choice, hot chocolate or coffee, and fresh juice.', 'fixed', 35000::numeric, 'BREAKFAST-001', 'Breakfast'),

    ('Tangy Chicken Bites Bruschetta', 'Tender chicken breast covered in house-made sauce and sesame seeds on toasted baguette with tomato salsa.', 'fixed', 8500::numeric, 'APP-001', 'Appetizers'),
    ('Sicilian Arancini', 'Deep-fried creamy risotto stuffed with minced beef topped with parmesan crumbs.', 'fixed', 9500::numeric, 'APP-002', 'Appetizers'),
    ('Crispy Danbunama Cheesy Taco', 'Crispy taco shells filled with locally made dried meat, corn, avocado salsa, and melted cheddar cheese.', 'fixed', 11500::numeric, 'APP-003', 'Appetizers'),
    ('Sicilian Spicy Wings', 'Deep-fried wings covered in spicy soy sriracha sauce.', 'fixed', 13500::numeric, 'APP-004', 'Appetizers'),
    ('Shrimp Mayo Spring Roll', 'Sauteed shrimp mixed with shredded vegetables and mayo wrapped in pastry sheets.', 'fixed', 15500::numeric, 'APP-005', 'Appetizers'),
    ('Cheesy Garlic Bread', 'Enriched dough dipped in herbed melted butter topped with mozzarella cheese.', 'fixed', 7500::numeric, 'APP-006', 'Appetizers'),
    ('Crispy Wings and Ranch', 'Seasoned battered wings served with ranch dressing.', 'fixed', 13500::numeric, 'APP-007', 'Appetizers'),
    ('Battered Prawns', 'Tempura battered prawns served with sweet chili sauce and tartar dressing.', 'fixed', 17500::numeric, 'APP-008', 'Appetizers'),

    ('Ram/Beef Suya Wrap', 'Tender spiced beef fillets with lettuce and tomatoes wrapped in toasted tortilla with cocktail sauce. Served with fries or yam chips.', 'fixed', 11500::numeric, 'SAND-001', 'Sandwiches'),
    ('Rosemary Chicken Wrap', 'Pan-seared chicken breast with mixed vegetables wrapped in toasted tortilla. Served with fries or yam chips.', 'fixed', 8500::numeric, 'SAND-002', 'Sandwiches'),
    ('Classic Club Sandwich', 'Two-layer sandwich with chicken, eggs, turkey ham or bacon, tomato, and lettuce. Served with fries or yam chips.', 'fixed', 12500::numeric, 'SAND-003', 'Sandwiches'),
    ('Ram Yaji Burger', 'Minced yaji-seasoned patties with lettuce and tomatoes in toasted burger buns. Served with fries or yam chips.', 'fixed', 12500::numeric, 'SAND-004', 'Sandwiches'),

    ('Casa Golden Platter', 'Sicilian chicken wings, mini chicken wrap, battered prawns, rice of choice, and fries.', 'fixed', 45000::numeric, 'PLAT-001', 'Platters'),
    ('Taco Array Platter', 'Chef special chicken, shrimp, and beef taco platter served with salsa and guacamole.', 'fixed', 25000::numeric, 'PLAT-002', 'Platters'),
    ('Whole Fish Plate', 'Spicy grilled croaker fish served with fries and slaw.', 'fixed', 26500::numeric, 'PLAT-003', 'Platters'),

    ('Classic Caesar Salad', 'Mixed greens lettuce with pan-seared chicken, croutons, and parmesan cheese. Dressing: vinaigrette or creamy.', 'fixed', 22000::numeric, 'SALAD-001', 'Salads'),
    ('Kilishi Potato Salad', 'Boiled potatoes, lettuce, apples, cherry tomatoes, and spicy dried beef with creamy dressing.', 'fixed', 20000::numeric, 'SALAD-002', 'Salads'),
    ('Tafarnuwa Seafood Salad', 'Mixed lettuce, cherry tomatoes, pan-seared seafood, oranges, carrots, and pickled onions.', 'fixed', 32000::numeric, 'SALAD-003', 'Salads'),
    ('Yaji Chicken Salad', 'Cabbage, lettuce, cherry tomatoes, pickled carrot, corn kernels, and grilled yaji-spiced chicken.', 'fixed', 22000::numeric, 'SALAD-004', 'Salads'),

    ('Spicy Riddi Lamb Cutlets', 'Pan-seared lamb chops with sesame oil and spices served with a side.', 'fixed', 28000::numeric, 'ENT-001', 'Entrees (Italian Inspired)'),
    ('Spicy Osso Buco on Herbed Rice', 'Slow-cooked beef oxtail with vegetables served on herbed rice.', 'fixed', 25000::numeric, 'ENT-002', 'Entrees (Italian Inspired)'),
    ('Jollof Rice and Meatballs', 'Braised basmati rice in spicy tomato sauce with meatballs.', 'fixed', 18500::numeric, 'ENT-003', 'Entrees (Italian Inspired)'),
    ('Peppersoup Stuffed Masa', 'Rice cakes infused with peppersoup spices stuffed with vegetables and served with pepper sauce.', 'tbd', null::numeric, 'ENT-004', 'Entrees (Italian Inspired)'),
    ('Tuscan Chicken Supreme', 'Pan-seared chicken breast served with chili tomato sauce.', 'fixed', 27000::numeric, 'ENT-005', 'Entrees (Italian Inspired)'),

    ('Coconut Rice', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-001', 'Sides'),
    ('Jollof Rice', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-002', 'Sides'),
    ('Herbed Rice', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-003', 'Sides'),
    ('Mashed Potatoes', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-004', 'Sides'),
    ('French Fries', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-005', 'Sides'),
    ('Sweet Potato Fries', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-006', 'Sides'),
    ('Yam Fries', 'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-007', 'Sides'),

    ('Egusi Soup', 'Melon seed soup with pumpkin leaves and goat meat served with swallow.', 'fixed', 17000::numeric, 'AFR-001', 'African Cuisine'),
    ('Eforiro Soup', 'Palm fruit vegetable soup with dried fish and assorted meats.', 'fixed', 19000::numeric, 'AFR-002', 'African Cuisine'),
    ('Okro Soup', 'Okra soup made with beef stock, palm oil, and assorted meats.', 'fixed', 19000::numeric, 'AFR-003', 'African Cuisine'),
    ('Afang Soup', 'Vegetable soup with periwinkle braised in palm oil.', 'fixed', 22000::numeric, 'AFR-004', 'African Cuisine'),
    ('Peppe A Casa', 'Spicy peppersoup with yam chunks served with bread rolls and choice of protein.', 'fixed', 18000::numeric, 'AFR-005', 'African Cuisine'),

    ('Danbunama Ragu', 'Creamy tomato sauce with shredded beef served with pasta.', 'fixed', 17000::numeric, 'PASTA-001', 'Pasta'),
    ('Herbed Prawns Aglio Olio', 'Pasta tossed in olive oil, herbs, garlic, and prawns.', 'fixed', 19000::numeric, 'PASTA-002', 'Pasta'),
    ('Classic Cream Carbonara', 'Creamy egg-yolk and parmesan sauce with garlic and crispy beef bacon.', 'fixed', 16000::numeric, 'PASTA-003', 'Pasta'),
    ('Crispy Chicken Alfredo', 'Golden-fried chicken breast served with creamy Alfredo pasta.', 'fixed', 16500::numeric, 'PASTA-004', 'Pasta'),
    ('Spaghetti Neapolitan', 'Tomato-based spaghetti with bell peppers, onions, herbs, and chili oil.', 'fixed', 10500::numeric, 'PASTA-005', 'Pasta'),

    ('Dankwa Creme Cake', 'Dankwa-inspired cake layered with caramel crumble and vanilla creme.', 'fixed', 9800::numeric, 'DESSERT-001', 'Desserts'),
    ('Classic Tiramisu', 'Espresso-soaked ladyfingers layered with mascarpone cream.', 'fixed', 12000::numeric, 'DESSERT-002', 'Desserts'),
    ('Strawberry Panna Cotta', 'Cream dessert topped with strawberry coulis.', 'fixed', 7500::numeric, 'DESSERT-003', 'Desserts'),
    ('Deconstructed Lemon Cheesecake', 'Lemon cheesecake with biscuit crust and lemon curd.', 'fixed', 10000::numeric, 'DESSERT-004', 'Desserts'),

    ('Water (Inhouse)', 'Still drinking water.', 'fixed', 5000.0::numeric, 'SD-001', 'Soft Drinks'),
    ('Softies', 'Assorted soft drinks from the standard selection.', 'fixed', 3000.0::numeric, 'SD-002', 'Soft Drinks'),
    ('Redbull', 'Energy drink.', 'fixed', 6000.0::numeric, 'SD-003', 'Soft Drinks'),
    ('Soda', 'Club soda.', 'fixed', 3000.0::numeric, 'SD-004', 'Soft Drinks'),
    ('Tonic', 'Tonic water.', 'fixed', 3000.0::numeric, 'SD-005', 'Soft Drinks'),
    ('Bitter Lemon', 'Bitter lemon soda.', 'fixed', 3000.0::numeric, 'SD-006', 'Soft Drinks'),

    ('Casa Gold Shot (Double Espresso)', 'Double espresso shot.', 'fixed', 8000.0::numeric, 'COF-001', 'Coffee'),
    ('Americano', 'Espresso with hot water.', 'fixed', 6500.0::numeric, 'COF-002', 'Coffee'),
    ('Cafe Latte', 'Espresso with steamed milk.', 'fixed', 6500.0::numeric, 'COF-003', 'Coffee'),
    ('Cappuccino', 'Espresso with steamed milk foam.', 'fixed', 7500.0::numeric, 'COF-004', 'Coffee'),
    ('Vanilla Frappuccino', 'Blended iced coffee with vanilla.', 'fixed', 11500.0::numeric, 'COF-005', 'Coffee'),
    ('Caramel Frappuccino', 'Blended iced coffee with caramel.', 'fixed', 11500.0::numeric, 'COF-006', 'Coffee'),
    ('Cookies and Cream Frappuccino', 'Blended iced coffee with cookie cream.', 'fixed', 15500.0::numeric, 'COF-007', 'Coffee'),
    ('Triple Chocolate Frappuccino', 'Blended iced coffee with chocolate.', 'fixed', 15500.0::numeric, 'COF-008', 'Coffee'),
    ('Iced Coffee', 'Chilled brewed coffee.', 'fixed', 9000.0::numeric, 'COF-009', 'Coffee'),

    ('Green Tea', 'Steeped green tea.', 'fixed', 6000.0::numeric, 'TEA-001', 'Tea'),
    ('Black Tea', 'Steeped black tea.', 'fixed', 6000.0::numeric, 'TEA-002', 'Tea'),
    ('Chamomile Tea', 'Herbal chamomile infusion.', 'fixed', 6000.0::numeric, 'TEA-003', 'Tea'),
    ('Cardamom Tea', 'Spiced tea with cardamom.', 'fixed', 6000.0::numeric, 'TEA-004', 'Tea'),
    ('Mint Tea', 'Refreshing mint infusion.', 'fixed', 6000.0::numeric, 'TEA-005', 'Tea'),
    ('Iced Tea', 'Chilled brewed tea.', 'fixed', 8000.0::numeric, 'TEA-006', 'Tea'),

    ('Chocolate Milkshake', 'Classic chocolate milkshake.', 'fixed', 10000.0::numeric, 'MS-001', 'Milkshakes'),
    ('Vanilla Milkshake', 'Classic vanilla milkshake.', 'fixed', 10000.0::numeric, 'MS-002', 'Milkshakes'),
    ('Caramel Milkshake', 'Classic caramel milkshake.', 'fixed', 10000.0::numeric, 'MS-003', 'Milkshakes'),
    ('Oreo Milkshake', 'Oreo milkshake.', 'fixed', 13000.0::numeric, 'MS-004', 'Milkshakes'),
    ('Bounty Milkshake', 'Bounty milkshake.', 'fixed', 13000.0::numeric, 'MS-005', 'Milkshakes'),
    ('Baileys Milkshake (Alcoholic)', 'Baileys-infused milkshake.', 'fixed', 15000.0::numeric, 'MS-006', 'Milkshakes'),

    ('Orange Juice', 'Fresh orange juice.', 'fixed', 7500.0::numeric, 'FJ-001', 'Fresh Juices'),
    ('Watermelon Juice', 'Fresh watermelon juice.', 'fixed', 7500.0::numeric, 'FJ-002', 'Fresh Juices'),
    ('Pineapple Juice', 'Fresh pineapple juice.', 'fixed', 7500.0::numeric, 'FJ-003', 'Fresh Juices'),
    ('Lemonade', 'Fresh lemonade.', 'fixed', 7500.0::numeric, 'FJ-004', 'Fresh Juices'),
    ('Hibiscus Juice', 'Fresh hibiscus drink.', 'fixed', 7500.0::numeric, 'FJ-005', 'Fresh Juices'),

    ('Cinnamon Bliss', 'Signature smoothie.', 'fixed', 13000.0::numeric, 'SM-001', 'Smoothies'),
    ('Mixed Berries', 'Signature smoothie.', 'fixed', 13000.0::numeric, 'SM-002', 'Smoothies'),
    ('Sunrise Smoothie', 'Signature smoothie.', 'fixed', 13000.0::numeric, 'SM-003', 'Smoothies'),
    ('Green Glow', 'Signature smoothie.', 'fixed', 13000.0::numeric, 'SM-004', 'Smoothies'),
    ('Avocado Dream', 'Signature smoothie.', 'fixed', 13000.0::numeric, 'SM-005', 'Smoothies'),
    ('Matcha Energy', 'Signature smoothie.', 'fixed', 13000.0::numeric, 'SM-006', 'Smoothies'),

    ('Sandeman', 'Wine bottle.', 'fixed', 55000.0::numeric, 'WINE-001', 'Wine'),
    ('Escudo Rojo', 'Wine bottle.', 'fixed', 70000.0::numeric, 'WINE-002', 'Wine'),
    ('Nederburg', 'Wine bottle.', 'fixed', 70000.0::numeric, 'WINE-003', 'Wine'),
    ('Carlo Rossi', 'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-004', 'Wine'),
    ('Four Cousins', 'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-005', 'Wine'),

    ('Glenfiddich 21', 'Whiskey bottle.', 'fixed', 120000.0::numeric, 'WHISKEY-001', 'Whiskey'),
    ('Glenfiddich 23', 'Whiskey bottle.', 'fixed', 130000.0::numeric, 'WHISKEY-002', 'Whiskey'),
    ('Macallan 18', 'Whiskey bottle.', 'fixed', 110000.0::numeric, 'WHISKEY-003', 'Whiskey'),
    ('Macallan 15', 'Whiskey bottle.', 'fixed', 65000.0::numeric, 'WHISKEY-004', 'Whiskey'),
    ('Singleton 15', 'Whiskey bottle.', 'fixed', 35000.0::numeric, 'WHISKEY-005', 'Whiskey'),

    ('Dom Perignon', 'Champagne bottle.', 'fixed', 130000.0::numeric, 'CHAMP-001', 'Champagne'),
    ('Armand de Brignac', 'Champagne bottle.', 'fixed', 150000.0::numeric, 'CHAMP-002', 'Champagne'),
    ('Moet and Chandon', 'Champagne bottle.', 'fixed', 30000.0::numeric, 'CHAMP-003', 'Champagne'),

    ('Grey Goose', 'Vodka bottle.', 'fixed', 400000.0::numeric, 'VODKA-001', 'Vodka'),
    ('Belvedere', 'Vodka bottle.', 'fixed', 250000.0::numeric, 'VODKA-002', 'Vodka'),
    ('Absolut', 'Vodka bottle.', 'fixed', 60000.0::numeric, 'VODKA-003', 'Vodka'),
    ('Ciroc', 'Vodka bottle.', 'fixed', 60000.0::numeric, 'VODKA-004', 'Vodka'),

    ('Heineken', 'Can beer.', 'fixed', 8000.0::numeric, 'BEER-001', 'Beer (Can)'),
    ('Budweiser', 'Can beer.', 'fixed', 7500.0::numeric, 'BEER-002', 'Beer (Can)'),
    ('Life', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-003', 'Beer (Can)'),
    ('Hero', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-004', 'Beer (Can)'),
    ('Legend', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-005', 'Beer (Can)'),

    ('Porn Star Martini', 'Cocktail.', 'fixed', 20000.0::numeric, 'COCKTAIL-001', 'Cocktails'),
    ('Long Island Iced Tea', 'Cocktail.', 'fixed', 16500.0::numeric, 'COCKTAIL-002', 'Cocktails'),
    ('Aperol Spritz', 'Cocktail.', 'fixed', 15000.0::numeric, 'COCKTAIL-003', 'Cocktails'),
    ('Gin and Tonic', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-004', 'Cocktails'),
    ('Strawberry Daiquiri', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-005', 'Cocktails'),
    ('Pina Colada', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-006', 'Cocktails'),
    ('Moscow Mule', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-007', 'Cocktails'),

    ('Virgin Pina Colada', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-001', 'Mocktails'),
    ('Virgin Strawberry Daiquiri', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-002', 'Mocktails'),
    ('Virgin Mojito', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-003', 'Mocktails'),
    ('Virgin Mimosa', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-004', 'Mocktails'),
    ('Sunrise Supreme', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-005', 'Mocktails'),
    ('Sunset Spritzer', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-006', 'Mocktails'),
    ('Berry Lemonade', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-007', 'Mocktails'),
    ('Cucumber Mint Cooler', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-008', 'Mocktails'),
    ('Strawberry Lemonade', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-009', 'Mocktails'),
    ('Blueberry Mojito', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-010', 'Mocktails')
) as seed(name, description, price_mode, price_amount, sku, category_name)
join public.menu_categories c
  on c.name = seed.category_name
 and c.kitchen_id = (select id from public.kitchens where slug = 'cenara-wuse-kitchen')
on conflict (sku) do update
set name = excluded.name,
    description = excluded.description,
    price_mode = excluded.price_mode,
    price_amount = excluded.price_amount,
    category_id = excluded.category_id,
    is_active = true,
    is_visible = true;


-- =====================
-- SEED VARIABLE PRICE OPTIONS (SIDES)
-- =====================
insert into public.menu_item_price_options (item_id, label, price_amount, sort_order)
select i.id, p.label, p.price_amount, p.sort_order
from public.menu_items i
join (
  values
    ('Single', 6500::numeric, 1),
    ('4 Pax', 20000::numeric, 2),
    ('6 Pax', 35000::numeric, 3)
) as p(label, price_amount, sort_order)
  on true
where i.sku in ('SIDE-001', 'SIDE-002', 'SIDE-003', 'SIDE-004', 'SIDE-005', 'SIDE-006', 'SIDE-007')
on conflict (item_id, label) do update
set price_amount = excluded.price_amount,
    sort_order = excluded.sort_order,
    is_active = true;

-- =====================
-- SEED ADDONS
-- =====================
insert into public.menu_addons (name, price)
values
  ('American Signature Breakfast', 0),
  ('English Classic Breakfast', 0),
  ('Nigerian Breakfast', 0),
  ('Cream', 1500.0),
  ('Coconut Milk', 1500.0),
  ('Almond Milk', 1500.0),
  ('Oat Milk', 1500.0),
  ('Soy Milk', 1500.0),
  ('Date Syrup', 1500.0),
  ('Whipped Cream', 2000.0)
on conflict (name) do update
set price = excluded.price;

-- =====================
-- MAP BREAKFAST OPTIONS TO BREAKFAST EXPERIENCE
-- =====================
insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('American Signature Breakfast', 'English Classic Breakfast', 'Nigerian Breakfast')
where i.sku = 'BREAKFAST-001'
on conflict (item_id, addon_id) do nothing;
-- =====================================================================
-- FULL SCHEMA — MULTI-KITCHEN (FRESH INSTALL)
-- Covers: Cenara Wuse Kitchen + Bistro Maitama Kitchen
-- =====================================================================


-- =====================
-- EXTENSIONS
-- =====================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";


-- =====================
-- PRICE MODE TYPE
-- =====================
do $$
begin
  create type public.menu_price_mode as enum ('fixed', 'variable', 'tbd');
exception
  when duplicate_object then null;
end $$;


-- =====================
-- PROFILES
-- =====================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'staff' check (role in ('admin', 'staff'))
);

alter table public.profiles enable row level security;


-- =====================
-- KITCHENS
-- =====================
create table if not exists public.kitchens (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.kitchens enable row level security;


-- =====================
-- MENU CATEGORIES
-- =====================
create table if not exists public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references public.kitchens(id) on delete cascade,
  name text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint menu_categories_name_kitchen_unique unique (name, kitchen_id)
);

alter table public.menu_categories enable row level security;


-- =====================
-- MENU ITEMS
-- =====================
create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.menu_categories(id) on delete set null,
  name text not null,
  description text,
  sku text unique,
  price_mode public.menu_price_mode not null default 'fixed',
  price_amount numeric(10,2),
  image_url text,
  is_active boolean not null default true,
  is_featured boolean not null default false,
  is_visible boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint menu_items_price_consistency check (
    (price_mode = 'fixed' and price_amount is not null and price_amount > 0) or
    (price_mode = 'variable' and price_amount is null) or
    (price_mode = 'tbd' and price_amount is null)
  )
);

alter table public.menu_items enable row level security;


-- =====================
-- MENU ITEM PRICE OPTIONS
-- =====================
create table if not exists public.menu_item_price_options (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  label text not null,
  price_amount numeric(10,2) not null check (price_amount > 0),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (item_id, label)
);

alter table public.menu_item_price_options enable row level security;


-- =====================
-- MENU ITEM IMAGES
-- =====================
create table if not exists public.menu_item_images (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  image_url text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.menu_item_images enable row level security;


-- =====================
-- ADDONS
-- =====================
create table if not exists public.menu_addons (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.menu_addons enable row level security;


-- =====================
-- ITEM ADDONS MAPPING
-- =====================
create table if not exists public.menu_item_addons (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  addon_id uuid not null references public.menu_addons(id) on delete cascade,
  unique (item_id, addon_id)
);

alter table public.menu_item_addons enable row level security;


-- =====================
-- PRICE AUDIT LOGS
-- =====================
create table if not exists public.price_audit_logs (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.menu_items(id) on delete cascade,
  old_price numeric(10,2),
  new_price numeric(10,2),
  user_id uuid references auth.users(id),
  reason text,
  created_at timestamptz not null default now()
);

alter table public.price_audit_logs enable row level security;


-- =====================
-- INDEXES
-- =====================
create index if not exists idx_menu_categories_kitchen
  on public.menu_categories(kitchen_id, sort_order, name);

create index if not exists idx_menu_items_category
  on public.menu_items(category_id, is_active, is_visible);

create index if not exists idx_menu_items_name
  on public.menu_items(name);

create index if not exists idx_menu_item_price_options_item
  on public.menu_item_price_options(item_id, sort_order, is_active);

create index if not exists idx_price_audit_logs_item_created
  on public.price_audit_logs(item_id, created_at desc);


-- =====================
-- HELPER FUNCTIONS
-- =====================
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;


-- =====================
-- STORAGE SETUP
-- =====================
insert into storage.buckets (id, name, public)
values ('menu-images', 'menu-images', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Public read menu images"   on storage.objects;
drop policy if exists "Admins upload menu images" on storage.objects;
drop policy if exists "Admins update menu images" on storage.objects;
drop policy if exists "Admins delete menu images" on storage.objects;

create policy "Public read menu images"
on storage.objects for select to public
using (bucket_id = 'menu-images');

create policy "Admins upload menu images"
on storage.objects for insert to authenticated
with check (bucket_id = 'menu-images' and public.is_admin());

create policy "Admins update menu images"
on storage.objects for update to authenticated
using  (bucket_id = 'menu-images' and public.is_admin())
with check (bucket_id = 'menu-images' and public.is_admin());

create policy "Admins delete menu images"
on storage.objects for delete to authenticated
using (bucket_id = 'menu-images' and public.is_admin());


-- =====================
-- RLS POLICIES
-- =====================
drop policy if exists "Users read own profile"                     on public.profiles;
drop policy if exists "Users update own profile"                   on public.profiles;
drop policy if exists "Admins full access profiles"                on public.profiles;
drop policy if exists "Admins full access kitchens"                on public.kitchens;
drop policy if exists "Public read kitchens"                       on public.kitchens;
drop policy if exists "Staff read kitchens"                        on public.kitchens;
drop policy if exists "Admins full access menu_categories"         on public.menu_categories;
drop policy if exists "Staff read categories"                      on public.menu_categories;
drop policy if exists "Admins full access menu_items"              on public.menu_items;
drop policy if exists "Staff read menu"                            on public.menu_items;
drop policy if exists "Admins full access menu_item_price_options" on public.menu_item_price_options;
drop policy if exists "Staff read price_options"                   on public.menu_item_price_options;
drop policy if exists "Admins full access images"                  on public.menu_item_images;
drop policy if exists "Admins full access addons"                  on public.menu_addons;
drop policy if exists "Admins full access item_addons"             on public.menu_item_addons;
drop policy if exists "Admins full access price_logs"              on public.price_audit_logs;
drop policy if exists "Staff read price_logs"                      on public.price_audit_logs;

-- Profiles
create policy "Users read own profile"
on public.profiles for select to authenticated
using (auth.uid() = id);

create policy "Users update own profile"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id and role = 'staff');

create policy "Admins full access profiles"
on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Kitchens
create policy "Admins full access kitchens"
on public.kitchens for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Public read kitchens"
on public.kitchens for select to public
using (is_active = true);

create policy "Staff read kitchens"
on public.kitchens for select to authenticated
using (is_active = true);

-- Menu categories
create policy "Admins full access menu_categories"
on public.menu_categories for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Staff read categories"
on public.menu_categories for select to authenticated
using (
  is_active = true
  and exists (
    select 1 from public.kitchens k
    where k.id = kitchen_id and k.is_active = true
  )
);

-- Menu items
create policy "Admins full access menu_items"
on public.menu_items for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Staff read menu"
on public.menu_items for select to authenticated
using (is_active = true);

-- Price options
create policy "Admins full access menu_item_price_options"
on public.menu_item_price_options for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Staff read price_options"
on public.menu_item_price_options for select to authenticated
using (is_active = true);

-- Images
create policy "Admins full access images"
on public.menu_item_images for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Addons
create policy "Admins full access addons"
on public.menu_addons for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Item addons mapping
create policy "Admins full access item_addons"
on public.menu_item_addons for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Price audit logs
create policy "Admins full access price_logs"
on public.price_audit_logs for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Staff read price_logs"
on public.price_audit_logs for select to authenticated
using (true);


-- =====================
-- AUTO PROFILE CREATION
-- =====================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, full_name, role, kitchen_id)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    'staff',
    nullif(new.raw_user_meta_data ->> 'kitchen_id', '')::uuid
  )
  on conflict (id) do update
  set email     = excluded.email,
      full_name = excluded.full_name,
      kitchen_id = coalesce(excluded.kitchen_id, public.profiles.kitchen_id);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();


-- =====================
-- AUTO UPDATE updated_at
-- =====================
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at_kitchens                on public.kitchens;
drop trigger if exists set_updated_at_menu_categories         on public.menu_categories;
drop trigger if exists set_updated_at_menu_items              on public.menu_items;
drop trigger if exists set_updated_at_menu_item_price_options on public.menu_item_price_options;
drop trigger if exists set_updated_at_menu_addons             on public.menu_addons;

create trigger set_updated_at_kitchens
before update on public.kitchens
for each row execute procedure public.handle_updated_at();

create trigger set_updated_at_menu_categories
before update on public.menu_categories
for each row execute procedure public.handle_updated_at();

create trigger set_updated_at_menu_items
before update on public.menu_items
for each row execute procedure public.handle_updated_at();

create trigger set_updated_at_menu_item_price_options
before update on public.menu_item_price_options
for each row execute procedure public.handle_updated_at();

create trigger set_updated_at_menu_addons
before update on public.menu_addons
for each row execute procedure public.handle_updated_at();


-- =====================
-- CONVENIENCE VIEW
-- =====================
drop view if exists public.v_menu_items_full;
drop view if exists public.v_menu_full;

create view public.v_menu_full as
select
  mi.id,
  mi.category_id,
  mi.name,
  mi.description,
  mi.sku,
  mi.price_mode,
  mi.price_amount,
  mi.image_url,
  mi.is_active,
  mi.is_featured,
  mi.is_visible,
  mi.created_at,
  mi.updated_at,
  mi.id          as item_id,
  mi.name        as item_name,
  mi.description as item_description,
  mi.sku         as item_sku,
  mc.name        as category_name,
  mc.sort_order  as category_sort_order,
  k.id           as kitchen_id,
  k.name         as kitchen_name,
  k.slug         as kitchen_slug,
  coalesce(po.price_options, '[]'::jsonb) as price_options,
  coalesce(ad.addons, '[]'::jsonb)        as addons
from public.menu_items mi
left join public.menu_categories mc on mc.id = mi.category_id
left join public.kitchens k         on k.id  = mc.kitchen_id
left join lateral (
  select jsonb_agg(
           jsonb_build_object(
             'id', mipo.id,
             'label', mipo.label,
             'price_amount', mipo.price_amount,
             'sort_order', mipo.sort_order
           )
           order by mipo.sort_order, mipo.label
         ) as price_options
  from public.menu_item_price_options mipo
  where mipo.item_id = mi.id
    and mipo.is_active = true
) po on true
left join lateral (
  select jsonb_agg(
           jsonb_build_object(
             'id', ma.id,
             'name', ma.name,
             'price', ma.price
           )
           order by ma.name
         ) as addons
  from public.menu_item_addons mia
  join public.menu_addons ma on ma.id = mia.addon_id
  where mia.item_id = mi.id
) ad on true;


-- =====================================================================
-- SEED DATA
-- =====================================================================


-- =====================
-- SEED KITCHENS
-- =====================
insert into public.kitchens (name, slug, description)
values
  ('Cenara Wuse Kitchen',    'cenara-wuse-kitchen',    'Cenara restaurant located in Wuse'),
  ('Bistro Maitama Kitchen', 'bistro-maitama-kitchen', 'Bistro restaurant located in Maitama')
on conflict (slug) do update
set name        = excluded.name,
    description = excluded.description,
    is_active   = true;


-- =====================
-- SEED CENARA CATEGORIES
-- =====================
insert into public.menu_categories (name, kitchen_id, sort_order)
select seed.name, k.id, seed.sort_order
from (
  values
    ('Breakfast',                  1),
    ('Appetizers',                 2),
    ('Sandwiches',                 3),
    ('Platters',                   4),
    ('Salads',                     5),
    ('Entrees (Italian Inspired)', 6),
    ('Sides',                      7),
    ('African Cuisine',            8),
    ('Healthy Northern Options',   9),
    ('Pasta',                     10),
    ('Afro Italian Fusion',       11),
    ('Desserts',                  12),
    ('Soft Drinks',               13),
    ('Coffee',                    14),
    ('Tea',                       15),
    ('Milkshakes',                16),
    ('Fresh Juices',              17),
    ('Smoothies',                 18),
    ('Wine',                      19),
    ('Whiskey',                   20),
    ('Champagne',                 21),
    ('Brandy',                    22),
    ('Tequila',                   23),
    ('Vodka',                     24),
    ('Gin & Bitters',             25),
    ('Beer (Can)',                26),
    ('Cocktails',                 27),
    ('Mocktails',                 28)
) as seed(name, sort_order)
join public.kitchens k on k.slug = 'cenara-wuse-kitchen'
on conflict (name, kitchen_id) do update
set sort_order = excluded.sort_order,
    is_active  = true;


-- =====================
-- SEED CENARA MENU ITEMS
-- =====================
insert into public.menu_items (name, description, price_mode, price_amount, sku, category_id)
select
  seed.name,
  seed.description,
  seed.price_mode::public.menu_price_mode,
  seed.price_amount,
  seed.sku,
  c.id
from (
  values
    ('Breakfast at Casa', 'A spread of fruits, pastries, a hot plate of choice, hot chocolate or coffee, and fresh juice.', 'fixed', 35000::numeric, 'BREAKFAST-001', 'Breakfast'),

    ('Tangy Chicken Bites Bruschetta', 'Tender chicken breast covered in house-made sauce and sesame seeds on toasted baguette with tomato salsa.', 'fixed', 8500::numeric, 'APP-001', 'Appetizers'),
    ('Sicilian Arancini', 'Deep-fried creamy risotto stuffed with minced beef topped with parmesan crumbs.', 'fixed', 9500::numeric, 'APP-002', 'Appetizers'),
    ('Crispy Danbunama Cheesy Taco', 'Crispy taco shells filled with locally made dried meat, corn, avocado salsa, and melted cheddar cheese.', 'fixed', 11500::numeric, 'APP-003', 'Appetizers'),
    ('Sicilian Spicy Wings', 'Deep-fried wings covered in spicy soy sriracha sauce.', 'fixed', 13500::numeric, 'APP-004', 'Appetizers'),
    ('Shrimp Mayo Spring Roll', 'Sauteed shrimp mixed with shredded vegetables and mayo wrapped in pastry sheets.', 'fixed', 15500::numeric, 'APP-005', 'Appetizers'),
    ('Cheesy Garlic Bread', 'Enriched dough dipped in herbed melted butter topped with mozzarella cheese.', 'fixed', 7500::numeric, 'APP-006', 'Appetizers'),
    ('Crispy Wings and Ranch', 'Seasoned battered wings served with ranch dressing.', 'fixed', 13500::numeric, 'APP-007', 'Appetizers'),
    ('Battered Prawns', 'Tempura battered prawns served with sweet chili sauce and tartar dressing.', 'fixed', 17500::numeric, 'APP-008', 'Appetizers'),

    ('Ram/Beef Suya Wrap', 'Tender spiced beef fillets with lettuce and tomatoes wrapped in toasted tortilla with cocktail sauce. Served with fries or yam chips.', 'fixed', 11500::numeric, 'SAND-001', 'Sandwiches'),
    ('Rosemary Chicken Wrap', 'Pan-seared chicken breast with mixed vegetables wrapped in toasted tortilla. Served with fries or yam chips.', 'fixed', 8500::numeric, 'SAND-002', 'Sandwiches'),
    ('Classic Club Sandwich', 'Two-layer sandwich with chicken, eggs, turkey ham or bacon, tomato, and lettuce. Served with fries or yam chips.', 'fixed', 12500::numeric, 'SAND-003', 'Sandwiches'),
    ('Ram Yaji Burger', 'Minced yaji-seasoned patties with lettuce and tomatoes in toasted burger buns. Served with fries or yam chips.', 'fixed', 12500::numeric, 'SAND-004', 'Sandwiches'),

    ('Casa Golden Platter', 'Sicilian chicken wings, mini chicken wrap, battered prawns, rice of choice, and fries.', 'fixed', 45000::numeric, 'PLAT-001', 'Platters'),
    ('Taco Array Platter', 'Chef special chicken, shrimp, and beef taco platter served with salsa and guacamole.', 'fixed', 25000::numeric, 'PLAT-002', 'Platters'),
    ('Whole Fish Plate', 'Spicy grilled croaker fish served with fries and slaw.', 'fixed', 26500::numeric, 'PLAT-003', 'Platters'),

    ('Classic Caesar Salad', 'Mixed greens lettuce with pan-seared chicken, croutons, and parmesan cheese. Dressing: vinaigrette or creamy.', 'fixed', 22000::numeric, 'SALAD-001', 'Salads'),
    ('Kilishi Potato Salad', 'Boiled potatoes, lettuce, apples, cherry tomatoes, and spicy dried beef with creamy dressing.', 'fixed', 20000::numeric, 'SALAD-002', 'Salads'),
    ('Tafarnuwa Seafood Salad', 'Mixed lettuce, cherry tomatoes, pan-seared seafood, oranges, carrots, and pickled onions.', 'fixed', 32000::numeric, 'SALAD-003', 'Salads'),
    ('Yaji Chicken Salad', 'Cabbage, lettuce, cherry tomatoes, pickled carrot, corn kernels, and grilled yaji-spiced chicken.', 'fixed', 22000::numeric, 'SALAD-004', 'Salads'),

    ('Spicy Riddi Lamb Cutlets', 'Pan-seared lamb chops with sesame oil and spices served with a side.', 'fixed', 28000::numeric, 'ENT-001', 'Entrees (Italian Inspired)'),
    ('Spicy Osso Buco on Herbed Rice', 'Slow-cooked beef oxtail with vegetables served on herbed rice.', 'fixed', 25000::numeric, 'ENT-002', 'Entrees (Italian Inspired)'),
    ('Jollof Rice and Meatballs', 'Braised basmati rice in spicy tomato sauce with meatballs.', 'fixed', 18500::numeric, 'ENT-003', 'Entrees (Italian Inspired)'),
    ('Peppersoup Stuffed Masa', 'Rice cakes infused with peppersoup spices stuffed with vegetables and served with pepper sauce.', 'tbd', null::numeric, 'ENT-004', 'Entrees (Italian Inspired)'),
    ('Tuscan Chicken Supreme', 'Pan-seared chicken breast served with chili tomato sauce.', 'fixed', 27000::numeric, 'ENT-005', 'Entrees (Italian Inspired)'),

    ('Coconut Rice',      'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-001', 'Sides'),
    ('Jollof Rice',       'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-002', 'Sides'),
    ('Herbed Rice',       'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-003', 'Sides'),
    ('Mashed Potatoes',   'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-004', 'Sides'),
    ('French Fries',      'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-005', 'Sides'),
    ('Sweet Potato Fries','Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-006', 'Sides'),
    ('Yam Fries',         'Side dish portioned by serving size.', 'variable', null::numeric, 'SIDE-007', 'Sides'),

    ('Egusi Soup',   'Melon seed soup with pumpkin leaves and goat meat served with swallow.', 'fixed', 17000::numeric, 'AFR-001', 'African Cuisine'),
    ('Eforiro Soup', 'Palm fruit vegetable soup with dried fish and assorted meats.',           'fixed', 19000::numeric, 'AFR-002', 'African Cuisine'),
    ('Okro Soup',    'Okra soup made with beef stock, palm oil, and assorted meats.',           'fixed', 19000::numeric, 'AFR-003', 'African Cuisine'),
    ('Afang Soup',   'Vegetable soup with periwinkle braised in palm oil.',                     'fixed', 22000::numeric, 'AFR-004', 'African Cuisine'),
    ('Peppe A Casa', 'Spicy peppersoup with yam chunks served with bread rolls and choice of protein.', 'fixed', 18000::numeric, 'AFR-005', 'African Cuisine'),

    ('Local Kulikuli Salad', 'A bowl of mixed vegetables paired with handmade kulikuli chunks and a creamy dressing.', 'tbd', null::numeric, 'HNO-001', 'Healthy Northern Options'),
    ('Sesame Vegetable Frittatas', 'A pan-fried mix of shredded vegetables and eggs seasoned with sesame oil.', 'tbd', null::numeric, 'HNO-002', 'Healthy Northern Options'),
    ('Pasta', 'A simple, hearty pasta dish made with fresh, wholesome ingredients.', 'tbd', null::numeric, 'HNO-003', 'Healthy Northern Options'),

    ('Danbunama Ragu',         'Creamy tomato sauce with shredded beef served with pasta.',              'fixed', 17000::numeric, 'PASTA-001', 'Pasta'),
    ('Herbed Prawns Aglio Olio','Pasta tossed in olive oil, herbs, garlic, and prawns.',                'fixed', 19000::numeric, 'PASTA-002', 'Pasta'),
    ('Classic Cream Carbonara','Creamy egg-yolk and parmesan sauce with garlic and crispy beef bacon.', 'fixed', 16000::numeric, 'PASTA-003', 'Pasta'),
    ('Crispy Chicken Alfredo', 'Golden-fried chicken breast served with creamy Alfredo pasta.',         'fixed', 16500::numeric, 'PASTA-004', 'Pasta'),
    ('Spaghetti Neapolitan',   'Tomato-based spaghetti with bell peppers, onions, herbs, and chili oil.','fixed', 10500::numeric, 'PASTA-005', 'Pasta'),

    ('Ram/Beef Suya Baguette Sandwich', 'Tender spiced beef fillets on fresh lettuce and sliced tomatoes with house cocktail sauce in a toasted baguette.', 'fixed', 11500::numeric, 'AIF-001', 'Afro Italian Fusion'),
    ('Crispy Danbunama Cheesy Taco', 'Crispy taco shells filled with locally made dried meat, corn, avocado salsa, and melted cheddar cheese.', 'fixed', 11500::numeric, 'AIF-002', 'Afro Italian Fusion'),
    ('Yaji Crisp Parmesan Potatoes', 'Squashed deep-fried yaji-spiced potatoes served with spicy tomato sauce.', 'tbd', null::numeric, 'AIF-003', 'Afro Italian Fusion'),
    ('Danbunama Ragu', 'Creamy tomato-based sauce mixed with locally made shredded beef and served with pasta of your choice.', 'fixed', 17000::numeric, 'AIF-004', 'Afro Italian Fusion'),
    ('Peppersoup Stuffed Masa', 'Rice cakes infused with peppersoup spices stuffed with vegetables and served with pepper sauce.', 'tbd', null::numeric, 'AIF-005', 'Afro Italian Fusion'),
    ('Kilishi Potato Salad', 'A hearty mix of boiled potatoes, lettuce, apples, cherry tomatoes, and spicy dried beef served with a creamy dressing.', 'fixed', 20000::numeric, 'AIF-006', 'Afro Italian Fusion'),
    ('Tafarnuwa Seafood Salad', 'A bowl of mixed lettuce, cherry tomatoes, garlic pan-seared mixed seafood, oranges, carrots, and pickled onions.', 'fixed', 32000::numeric, 'AIF-007', 'Afro Italian Fusion'),
    ('Ram Yaji Burger', 'Minced yaji-seasoned meat patties on tomato and lettuce between toasted burger buns.', 'fixed', 12500::numeric, 'AIF-008', 'Afro Italian Fusion'),

    ('Dankwa Creme Cake',           'Dankwa-inspired cake layered with caramel crumble and vanilla creme.', 'fixed', 9800::numeric,  'DESSERT-001', 'Desserts'),
    ('Classic Tiramisu',            'Espresso-soaked ladyfingers layered with mascarpone cream.',           'fixed', 12000::numeric, 'DESSERT-002', 'Desserts'),
    ('Strawberry Panna Cotta',      'Cream dessert topped with strawberry coulis.',                        'fixed', 7500::numeric,  'DESSERT-003', 'Desserts'),
    ('Deconstructed Lemon Cheesecake','Lemon cheesecake with biscuit crust and lemon curd.',              'fixed', 10000::numeric, 'DESSERT-004', 'Desserts'),

    ('Water (Inhouse)', 'Still drinking water.',                          'fixed', 5000.0::numeric, 'SD-001', 'Soft Drinks'),
    ('Softies',         'Assorted soft drinks from the standard selection.','fixed', 3000.0::numeric, 'SD-002', 'Soft Drinks'),
    ('Redbull',         'Energy drink.',                                   'fixed', 6000.0::numeric, 'SD-003', 'Soft Drinks'),
    ('Soda',            'Club soda.',                                      'fixed', 3000.0::numeric, 'SD-004', 'Soft Drinks'),
    ('Tonic',           'Tonic water.',                                    'fixed', 3000.0::numeric, 'SD-005', 'Soft Drinks'),
    ('Bitter Lemon',    'Bitter lemon soda.',                              'fixed', 3000.0::numeric, 'SD-006', 'Soft Drinks'),

    ('Casa Gold Shot (Double Espresso)', 'Double espresso shot.',           'fixed', 8000.0::numeric,  'COF-001', 'Coffee'),
    ('Americano',                        'Espresso with hot water.',        'fixed', 6500.0::numeric,  'COF-002', 'Coffee'),
    ('Cafe Latte',                       'Espresso with steamed milk.',     'fixed', 6500.0::numeric,  'COF-003', 'Coffee'),
    ('Cappuccino',                       'Espresso with steamed milk foam.','fixed', 7500.0::numeric,  'COF-004', 'Coffee'),
    ('Vanilla Frappuccino',              'Blended iced coffee with vanilla.','fixed', 11500.0::numeric, 'COF-005', 'Coffee'),
    ('Caramel Frappuccino',              'Blended iced coffee with caramel.','fixed', 11500.0::numeric, 'COF-006', 'Coffee'),
    ('Cookies and Cream Frappuccino',    'Blended iced coffee with cookie cream.','fixed', 15500.0::numeric, 'COF-007', 'Coffee'),
    ('Triple Chocolate Frappuccino',     'Blended iced coffee with chocolate.',   'fixed', 15500.0::numeric, 'COF-008', 'Coffee'),
    ('Iced Coffee',                      'Chilled brewed coffee.',          'fixed', 9000.0::numeric,  'COF-009', 'Coffee'),

    ('Green Tea',    'Steeped green tea.',         'fixed', 6000.0::numeric, 'TEA-001', 'Tea'),
    ('Black Tea',    'Steeped black tea.',         'fixed', 6000.0::numeric, 'TEA-002', 'Tea'),
    ('Chamomile Tea','Herbal chamomile infusion.', 'fixed', 6000.0::numeric, 'TEA-003', 'Tea'),
    ('Cardamom Tea', 'Spiced tea with cardamom.',  'fixed', 6000.0::numeric, 'TEA-004', 'Tea'),
    ('Mint Tea',     'Refreshing mint infusion.',  'fixed', 6000.0::numeric, 'TEA-005', 'Tea'),
    ('Iced Tea',     'Chilled brewed tea.',        'fixed', 8000.0::numeric, 'TEA-006', 'Tea'),

    ('Chocolate Milkshake',      'Classic chocolate milkshake.', 'fixed', 10000.0::numeric, 'MS-001', 'Milkshakes'),
    ('Vanilla Milkshake',        'Classic vanilla milkshake.',   'fixed', 10000.0::numeric, 'MS-002', 'Milkshakes'),
    ('Caramel Milkshake',        'Classic caramel milkshake.',   'fixed', 10000.0::numeric, 'MS-003', 'Milkshakes'),
    ('Oreo Milkshake',           'Oreo milkshake.',              'fixed', 13000.0::numeric, 'MS-004', 'Milkshakes'),
    ('Bounty Milkshake',         'Bounty milkshake.',            'fixed', 13000.0::numeric, 'MS-005', 'Milkshakes'),
    ('Baileys Milkshake (Alcoholic)','Baileys-infused milkshake.','fixed', 15000.0::numeric, 'MS-006', 'Milkshakes'),

    ('Orange Juice',    'Fresh orange juice.',    'fixed', 7500.0::numeric, 'FJ-001', 'Fresh Juices'),
    ('Watermelon Juice','Fresh watermelon juice.','fixed', 7500.0::numeric, 'FJ-002', 'Fresh Juices'),
    ('Pineapple Juice', 'Fresh pineapple juice.', 'fixed', 7500.0::numeric, 'FJ-003', 'Fresh Juices'),
    ('Lemonade',        'Fresh lemonade.',        'fixed', 7500.0::numeric, 'FJ-004', 'Fresh Juices'),
    ('Hibiscus Juice',  'Fresh hibiscus drink.',  'fixed', 7500.0::numeric, 'FJ-005', 'Fresh Juices'),
    ('Casa Tropicana (Special)', 'Special fruit selection with two picks and optional ginger or lemon additions.', 'fixed', 15000.0::numeric, 'FJ-006', 'Fresh Juices'),

    ('Cinnamon Bliss',  'Apple, cinnamon, and oats.', 'fixed', 13000.0::numeric, 'SM-001', 'Smoothies'),
    ('Mixed Berries',   'Blueberry, raspberry, strawberry, honey, and Greek yogurt.', 'fixed', 13000.0::numeric, 'SM-002', 'Smoothies'),
    ('Sunrise Smoothie','Papaya, orange, pineapple, and ginger.', 'fixed', 13000.0::numeric, 'SM-003', 'Smoothies'),
    ('Green Glow',      'Spinach, kale, pineapple, mango, and coconut water.', 'fixed', 13000.0::numeric, 'SM-004', 'Smoothies'),
    ('Avocado Dream',   'Avocado, banana, almond milk, honey, and date.', 'fixed', 13000.0::numeric, 'SM-005', 'Smoothies'),
    ('Matcha Energy',   'Matcha, banana, honey, and almond milk.', 'fixed', 13000.0::numeric, 'SM-006', 'Smoothies'),

    ('Sandeman',    'Wine bottle.', 'fixed', 55000.0::numeric, 'WINE-001', 'Wine'),
    ('Escudo Rojo', 'Wine bottle.', 'fixed', 70000.0::numeric, 'WINE-002', 'Wine'),
    ('Nederburg',   'Wine bottle.', 'fixed', 70000.0::numeric, 'WINE-003', 'Wine'),
    ('Carlo Rossi', 'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-004', 'Wine'),
    ('Four Cousins','Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-005', 'Wine'),
    ('Mouton Cadet', 'Wine bottle.', 'fixed', 51000.0::numeric, 'WINE-006', 'Wine'),
    ('Drosdty-Hof',  'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-007', 'Wine'),
    ('Lamothe Parrot', 'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-008', 'Wine'),
    ('Robertson', 'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-009', 'Wine'),
    ('Declan', 'Wine bottle.', 'fixed', 35000.0::numeric, 'WINE-010', 'Wine'),

    ('Glenfiddich (21 Years)', 'Whiskey bottle.', 'fixed', 1200000.0::numeric, 'WHISKEY-001', 'Whiskey'),
    ('Glenfiddich (23 Years)', 'Whiskey bottle.', 'fixed', 1300000.0::numeric, 'WHISKEY-002', 'Whiskey'),
    ('The Macallan (Double Cask) (18 Years)', 'Whiskey bottle.', 'fixed', 1100000.0::numeric, 'WHISKEY-003', 'Whiskey'),
    ('The Macallan (Double Cask) (15 Years)', 'Whiskey bottle.', 'fixed', 650000.0::numeric, 'WHISKEY-004', 'Whiskey'),
    ('Singleton (15 Years)', 'Whiskey bottle.', 'fixed', 350000.0::numeric, 'WHISKEY-005', 'Whiskey'),
    ('Singleton (12 Years)', 'Whiskey bottle.', 'fixed', 300000.0::numeric, 'WHISKEY-006', 'Whiskey'),
    ('Jameson Black Barrel', 'Whiskey bottle.', 'fixed', 250000.0::numeric, 'WHISKEY-007', 'Whiskey'),
    ('Jameson Green', 'Whiskey bottle.', 'fixed', 120000.0::numeric, 'WHISKEY-008', 'Whiskey'),
    ('Wild Turkey', 'Whiskey bottle.', 'fixed', 120000.0::numeric, 'WHISKEY-009', 'Whiskey'),
    ('Monkey Shoulder', 'Whiskey bottle.', 'fixed', 65000.0::numeric, 'WHISKEY-010', 'Whiskey'),

    ('Don Perignon (Luminous) - Brut', 'Champagne bottle.', 'fixed', 1300000.0::numeric, 'CHAMP-001', 'Champagne'),
    ('Don Perignon (Luminous) - Rose', 'Champagne bottle.', 'fixed', 1500000.0::numeric, 'CHAMP-002', 'Champagne'),
    ('Armand de Brignac Ace of Spade (Rose)', 'Champagne bottle.', 'fixed', 1500000.0::numeric, 'CHAMP-003', 'Champagne'),
    ('Armand de Brignac Ace of Spade (Brut)', 'Champagne bottle.', 'fixed', 1350000.0::numeric, 'CHAMP-004', 'Champagne'),
    ('Moet et Chandon Nectar Rose', 'Champagne bottle.', 'fixed', 360000.0::numeric, 'CHAMP-005', 'Champagne'),
    ('Moet et Chandon Nectar Brut', 'Champagne bottle.', 'fixed', 300000.0::numeric, 'CHAMP-006', 'Champagne'),
    ('Laurent Perrier Rose', 'Champagne bottle.', 'fixed', 390000.0::numeric, 'CHAMP-007', 'Champagne'),
    ('Laurent Perrier Brut', 'Champagne bottle.', 'fixed', 290000.0::numeric, 'CHAMP-008', 'Champagne'),
    ('Veuve Cliquot Rich Rose', 'Champagne bottle.', 'fixed', 455000.0::numeric, 'CHAMP-009', 'Champagne'),
    ('Veuve Cliquot Brut', 'Champagne bottle.', 'fixed', 375000.0::numeric, 'CHAMP-010', 'Champagne'),

    ('Hennessy XO', 'Brandy bottle.', 'fixed', 1300000.0::numeric, 'BRANDY-001', 'Brandy'),
    ('Hennessy VSOP', 'Brandy bottle.', 'fixed', 350000.0::numeric, 'BRANDY-002', 'Brandy'),
    ('Hennessy VS', 'Brandy bottle.', 'fixed', 210000.0::numeric, 'BRANDY-003', 'Brandy'),
    ('Remy Martin XO', 'Brandy bottle.', 'fixed', 1050000.0::numeric, 'BRANDY-004', 'Brandy'),
    ('Remy Martin VSOP', 'Brandy bottle.', 'fixed', 245000.0::numeric, 'BRANDY-005', 'Brandy'),
    ('Martell Blue Swift', 'Brandy bottle.', 'fixed', 310000.0::numeric, 'BRANDY-006', 'Brandy'),
    ('Martell VS', 'Brandy bottle.', 'fixed', 215000.0::numeric, 'BRANDY-007', 'Brandy'),

    ('Tequila Olmeca', 'Tequila bottle.', 'fixed', 700000.0::numeric, 'TEQUILA-001', 'Tequila'),
    ('Tequila Sierra', 'Tequila bottle.', 'fixed', 450000.0::numeric, 'TEQUILA-002', 'Tequila'),
    ('Casamigos Blanco', 'Tequila bottle.', 'fixed', 400000.0::numeric, 'TEQUILA-003', 'Tequila'),
    ('Casamigos Reposado', 'Tequila bottle.', 'fixed', 450000.0::numeric, 'TEQUILA-004', 'Tequila'),
    ('Casamigos Anejo', 'Tequila bottle.', 'fixed', 500000.0::numeric, 'TEQUILA-005', 'Tequila'),
    ('Don Julio Anejo', 'Tequila bottle.', 'fixed', 500000.0::numeric, 'TEQUILA-006', 'Tequila'),
    ('Don Julio Reposado', 'Tequila bottle.', 'fixed', 450000.0::numeric, 'TEQUILA-007', 'Tequila'),
    ('Don Julio 1942', 'Tequila bottle.', 'fixed', 1200000.0::numeric, 'TEQUILA-008', 'Tequila'),
    ('Clase Azul Plata', 'Tequila bottle.', 'fixed', 650000.0::numeric, 'TEQUILA-009', 'Tequila'),
    ('Clase Azul Reposado', 'Tequila bottle.', 'fixed', 1200000.0::numeric, 'TEQUILA-010', 'Tequila'),

    ('Grey Goose', 'Vodka bottle.', 'fixed', 400000.0::numeric, 'VODKA-001', 'Vodka'),
    ('Belvedere', 'Vodka bottle.', 'fixed', 250000.0::numeric, 'VODKA-002', 'Vodka'),
    ('Belvedere Intense', 'Vodka bottle.', 'fixed', 350000.0::numeric, 'VODKA-003', 'Vodka'),
    ('Belvedere Nobel', 'Vodka bottle.', 'fixed', 260000.0::numeric, 'VODKA-004', 'Vodka'),
    ('Belvedere Gold', 'Vodka bottle.', 'fixed', 400000.0::numeric, 'VODKA-005', 'Vodka'),
    ('Absolut Vodka', 'Vodka bottle.', 'fixed', 60000.0::numeric, 'VODKA-006', 'Vodka'),
    ('Ciroc Vodka', 'Vodka bottle.', 'fixed', 60000.0::numeric, 'VODKA-007', 'Vodka'),
    ('Smirnoff Vodka Red', 'Vodka bottle.', 'fixed', 55000.0::numeric, 'VODKA-008', 'Vodka'),
    ('Smirnoff Vodka Blue', 'Vodka bottle.', 'fixed', 55000.0::numeric, 'VODKA-009', 'Vodka'),
    ('Sky Vodka', 'Vodka bottle.', 'fixed', 55000.0::numeric, 'VODKA-010', 'Vodka'),

    ('Bombay', 'Gin bottle.', 'fixed', 40000.0::numeric, 'GINBIT-001', 'Gin & Bitters'),
    ('Gordon''s Gin', 'Gin bottle.', 'fixed', 35000.0::numeric, 'GINBIT-002', 'Gin & Bitters'),
    ('Hendrick''s', 'Gin bottle.', 'fixed', 25000.0::numeric, 'GINBIT-003', 'Gin & Bitters'),
    ('Campari Big', 'Bitters bottle.', 'fixed', 75000.0::numeric, 'GINBIT-004', 'Gin & Bitters'),
    ('Campari Small', 'Bitters bottle.', 'fixed', 67000.0::numeric, 'GINBIT-005', 'Gin & Bitters'),
    ('Jagermeister', 'Bitters bottle.', 'fixed', 65000.0::numeric, 'GINBIT-006', 'Gin & Bitters'),
    ('Orijin Bitters Big', 'Bitters bottle.', 'fixed', 30000.0::numeric, 'GINBIT-007', 'Gin & Bitters'),
    ('Orijin Bitters Small', 'Bitters bottle.', 'fixed', 20000.0::numeric, 'GINBIT-008', 'Gin & Bitters'),

    ('Heineken Can', 'Can beer.', 'fixed', 8000.0::numeric, 'BEER-001', 'Beer (Can)'),
    ('Can Stout', 'Can beer.', 'fixed', 8000.0::numeric, 'BEER-002', 'Beer (Can)'),
    ('Budweiser Can', 'Can beer.', 'fixed', 7500.0::numeric, 'BEER-003', 'Beer (Can)'),
    ('Life Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-004', 'Beer (Can)'),
    ('Desperados Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-005', 'Beer (Can)'),
    ('Hero Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-006', 'Beer (Can)'),
    ('Legend Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-007', 'Beer (Can)'),
    ('Goldberg Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-008', 'Beer (Can)'),
    ('Radler Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-009', 'Beer (Can)'),
    ('Double Black', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-010', 'Beer (Can)'),
    ('Trophy Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-011', 'Beer (Can)'),
    ('Extra Smooth Can', 'Can beer.', 'fixed', 6500.0::numeric, 'BEER-012', 'Beer (Can)'),

    ('Porn Star Martini', 'Cocktail.', 'fixed', 20000.0::numeric, 'COCKTAIL-001', 'Cocktails'),
    ('Long Island Ice Tea', 'Cocktail.', 'fixed', 16500.0::numeric, 'COCKTAIL-002', 'Cocktails'),
    ('Aperol Spritz', 'Cocktail.', 'fixed', 15000.0::numeric, 'COCKTAIL-003', 'Cocktails'),
    ('Gin and Tonic', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-004', 'Cocktails'),
    ('Mai Tai', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-005', 'Cocktails'),
    ('Strawberry Daquiri', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-006', 'Cocktails'),
    ('Pina Colada', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-007', 'Cocktails'),
    ('Whisky Sour', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-008', 'Cocktails'),
    ('Negroni', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-009', 'Cocktails'),
    ('Manhattan', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-010', 'Cocktails'),
    ('Moscow Mule', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-011', 'Cocktails'),
    ('Screwdriver', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-012', 'Cocktails'),
    ('Cosmopolitan', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-013', 'Cocktails'),
    ('Mojito', 'Cocktail.', 'fixed', 14000.0::numeric, 'COCKTAIL-014', 'Cocktails'),
    ('Sidecar', 'Cocktail.', 'fixed', 14000.0::numeric, 'COCKTAIL-015', 'Cocktails'),
    ('Sex on the Beach', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-016', 'Cocktails'),
    ('Old Fashioned', 'Cocktail.', 'fixed', 14500.0::numeric, 'COCKTAIL-017', 'Cocktails'),
    ('Mimosa', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-018', 'Cocktails'),
    ('Martini', 'Cocktail. Price pending.', 'tbd', null::numeric, 'COCKTAIL-019', 'Cocktails'),
    ('Margarita', 'Cocktail. Price pending.', 'tbd', null::numeric, 'COCKTAIL-020', 'Cocktails'),
    ('White Russian', 'Cocktail.', 'fixed', 14000.0::numeric, 'COCKTAIL-021', 'Cocktails'),
    ('Tequila Sunrise', 'Cocktail.', 'fixed', 14000.0::numeric, 'COCKTAIL-022', 'Cocktails'),
    ('Amaretto Sour', 'Cocktail.', 'fixed', 13500.0::numeric, 'COCKTAIL-023', 'Cocktails'),

    ('Virgin Pina Colada', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-001', 'Mocktails'),
    ('Virgin Strawberry Daquiri', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-002', 'Mocktails'),
    ('Virgin Mojito', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-003', 'Mocktails'),
    ('Virgin Mimosa', 'Cranberry juice, apple juice, orange juice, and sparkling apple cider. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-004', 'Mocktails'),
    ('Sunrise Supreme', 'Orange, pineapple, watermelon, and Redbull. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-005', 'Mocktails'),
    ('Sunset Spritzer', 'Orange juice, pomegranate juice, and sparkling water. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-006', 'Mocktails'),
    ('Berry Lemonade', 'Mixed berry juice, lemonade, and simple syrup. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-007', 'Mocktails'),
    ('Cucumber Mint Cooler', 'Cucumber, mint, lime, simple syrup, and seltzer. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-008', 'Mocktails'),
    ('Strawberry Lemonade', 'Mocktail. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-009', 'Mocktails'),
    ('Blueberry Mojito', 'Fresh blueberries, mint, lime, and Sprite. Price pending.', 'tbd', null::numeric, 'MOCKTAIL-010', 'Mocktails')
) as seed(name, description, price_mode, price_amount, sku, category_name)
join public.menu_categories c
  on  c.name       = seed.category_name
  and c.kitchen_id = (select id from public.kitchens where slug = 'cenara-wuse-kitchen')
on conflict (sku) do update
set name         = excluded.name,
    description  = excluded.description,
    price_mode   = excluded.price_mode,
    price_amount = excluded.price_amount,
    category_id  = excluded.category_id,
    is_active    = true,
    is_visible   = true;


-- =====================
-- SEED CENARA VARIABLE PRICE OPTIONS (SIDES)
-- =====================
insert into public.menu_item_price_options (item_id, label, price_amount, sort_order)
select i.id, p.label, p.price_amount, p.sort_order
from public.menu_items i
join (
  values
    ('Single', 6500::numeric,  1),
    ('4 Pax',  20000::numeric, 2),
    ('6 Pax',  35000::numeric, 3)
) as p(label, price_amount, sort_order) on true
where i.sku in ('SIDE-001','SIDE-002','SIDE-003','SIDE-004','SIDE-005','SIDE-006','SIDE-007')
on conflict (item_id, label) do update
set price_amount = excluded.price_amount,
    sort_order   = excluded.sort_order,
    is_active    = true;


-- =====================
-- SEED ADDONS
-- =====================
insert into public.menu_addons (name, price)
values
  ('American Signature Breakfast', 0),
  ('English Classic Breakfast',    0),
  ('Nigerian Breakfast',           0),
  ('Fries',                         0),
  ('Yam Chips',                     0),
  ('Vinaigrette Dressing',          0),
  ('Creamy Dressing',               0),
  ('Chicken',                       0),
  ('Ram',                           0),
  ('Beef',                          0),
  ('Fish',                          0),
  ('Coke',                          0),
  ('Fanta',                         0),
  ('Sprite',                        0),
  ('Tonic Water',                   0),
  ('Bitter Lemon (Softies)',        0),
  ('Bottle Water',                  0),
  ('Chivita Orange',                0),
  ('Chivita Pineapple',             0),
  ('Chivita Exotic',                0),
  ('Cranberry',                     0),
  ('Amstel Malta Can',              0),
  ('Amstel Malta Pet',              0),
  ('Maltina Can',                   0),
  ('Maltina Pet',                   0),
  ('Fayrouz Can',                   0),
  ('Fayrouz Pet',                   0),
  ('Cream',                      1500.0),
  ('Coconut',                    1500.0),
  ('Almond',                     1500.0),
  ('Oat',                        1500.0),
  ('Soy',                        1500.0),
  ('Date',                       1500.0),
  ('Whipped Cream',             2000.0),
  ('Apple',                         0),
  ('Carrot',                        0),
  ('Passion Fruit',                 0),
  ('Dragon Fruit',                  0),
  ('Cherry',                        0),
  ('Beetroot',                      0),
  ('Ginger',                        0),
  ('Lemon',                         0)
on conflict (name) do update
set price = excluded.price;


-- =====================
-- MAP BREAKFAST ADDONS → CENARA BREAKFAST EXPERIENCE
-- =====================
insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('American Signature Breakfast', 'English Classic Breakfast', 'Nigerian Breakfast')
where i.sku = 'BREAKFAST-001'
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('Fries', 'Yam Chips')
where i.sku in ('SAND-001', 'SAND-002', 'SAND-003', 'SAND-004')
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('Vinaigrette Dressing', 'Creamy Dressing')
where i.sku in ('SALAD-001', 'SALAD-002', 'SALAD-003', 'SALAD-004', 'HNO-001', 'AIF-006', 'AIF-007')
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('Chicken', 'Ram', 'Beef', 'Fish')
where i.sku = 'AFR-005'
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in (
    'Coke',
    'Fanta',
    'Sprite',
    'Tonic Water',
    'Bitter Lemon (Softies)',
    'Bottle Water',
    'Chivita Orange',
    'Chivita Pineapple',
    'Chivita Exotic',
    'Cranberry',
    'Amstel Malta Can',
    'Amstel Malta Pet',
    'Maltina Can',
    'Maltina Pet',
    'Fayrouz Can',
    'Fayrouz Pet'
  )
where i.sku = 'SD-002'
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('Cream', 'Coconut', 'Almond', 'Oat', 'Soy', 'Date', 'Whipped Cream')
where i.sku like 'COF-%'
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('Apple', 'Carrot', 'Pineapple', 'Passion Fruit', 'Dragon Fruit', 'Cherry', 'Beetroot', 'Ginger', 'Lemon')
where i.sku = 'FJ-006'
on conflict (item_id, addon_id) do nothing;


-- =====================================================================
-- BISTRO MAITAMA — SEED DATA
-- Uses SKU prefix 'BISTRO-' to avoid conflicts with Cenara SKUs.
-- =====================================================================

-- SEED BISTRO CATEGORIES
insert into public.menu_categories (name, kitchen_id, sort_order)
select seed.name, k.id, seed.sort_order
from (
  values
    ('Breakfast', 1),
    ('Main Course', 2),
    ('Protein', 3),
    ('Sides', 4),
    ('Peppersoup', 5),
    ('More Courses', 6),
    ('Soup', 7),
    ('Salads', 8),
    ('Drinks', 9)
) as seed(name, sort_order)
join public.kitchens k on k.slug = 'bistro-maitama-kitchen'
on conflict (name, kitchen_id) do update
set sort_order = excluded.sort_order,
    is_active = true;

-- SEED BISTRO MENU ITEMS
insert into public.menu_items (name, description, price_mode, price_amount, sku, category_id)
select
  seed.name,
  seed.description,
  seed.price_mode::public.menu_price_mode,
  seed.price_amount,
  seed.sku,
  c.id
from (
  values
    ('Full English Breakfast', null, 'fixed', 12000::numeric, 'BISTRO-BRK-001', 'Breakfast'),
    ('American Breakfast', null, 'fixed', 12000::numeric, 'BISTRO-BRK-002', 'Breakfast'),
    ('Complimentary Breakfast', 'Marked as complimentary in source menu.', 'tbd', null::numeric, 'BISTRO-BRK-003', 'Breakfast'),
    ('Yamarita', 'Yam coated in egg and bell pepper.', 'fixed', 6000::numeric, 'BISTRO-BRK-004', 'Breakfast'),
    ('Custard with Akara', 'Custard served with akara (bean cakes).', 'fixed', 6000::numeric, 'BISTRO-BRK-005', 'Breakfast'),
    ('Pancakes', 'Pancakes.', 'fixed', 6000::numeric, 'BISTRO-BRK-006', 'Breakfast'),
    ('Plantain or Yam With Egg Sauce', 'Fried or boiled.', 'fixed', 6000::numeric, 'BISTRO-BRK-007', 'Breakfast'),
    ('Sweet Potato with Egg Sauce', 'Sweet potato served with egg sauce.', 'fixed', 6000::numeric, 'BISTRO-BRK-008', 'Breakfast'),
    ('Noodles and Eggs', 'Noodles and eggs.', 'fixed', 6000::numeric, 'BISTRO-BRK-009', 'Breakfast'),
    ('Club Sandwich', null, 'fixed', 6000::numeric, 'BISTRO-BRK-010', 'Breakfast'),

    ('White Rice', 'White rice.', 'fixed', 3000::numeric, 'BISTRO-MNC-001', 'Main Course'),
    ('Jollof Rice', 'Jollof rice.', 'fixed', 5500::numeric, 'BISTRO-MNC-002', 'Main Course'),
    ('Local Jollof Rice and Beans', 'With dried fish and kpomo.', 'fixed', 5500::numeric, 'BISTRO-MNC-003', 'Main Course'),
    ('Caribbean Rice', 'With sliced plantain and diced chicken thighs.', 'fixed', 7000::numeric, 'BISTRO-MNC-004', 'Main Course'),
    ('Turkish Suya Rice', 'With diced beef.', 'fixed', 6500::numeric, 'BISTRO-MNC-005', 'Main Course'),
    ('Egg Fried Rice', 'With scrambled eggs.', 'fixed', 5500::numeric, 'BISTRO-MNC-006', 'Main Course'),
    ('Casa Special Fried Rice', 'With diced chicken, beef and sausage.', 'fixed', 7500::numeric, 'BISTRO-MNC-007', 'Main Course'),
    ('Sea Food Fried Rice', 'With shrimps.', 'fixed', 7000::numeric, 'BISTRO-MNC-008', 'Main Course'),
    ('Thai Chicken or Beef Noodles', null, 'fixed', 7500::numeric, 'BISTRO-MNC-009', 'Main Course'),
    ('Jollof Spaghetti', null, 'fixed', 5000::numeric, 'BISTRO-MNC-010', 'Main Course'),
    ('Pineapple Fried Rice', null, 'fixed', 8000::numeric, 'BISTRO-MNC-011', 'Main Course'),
    ('Penne Arrabbiata', null, 'fixed', 12000::numeric, 'BISTRO-MNC-012', 'Main Course'),
    ('Marinara Pasta', null, 'fixed', 12000::numeric, 'BISTRO-MNC-013', 'Main Course'),

    ('Grilled Chicken', 'With ketchup or barbecue.', 'fixed', 6000::numeric, 'BISTRO-PRO-001', 'Protein'),
    ('Lemon Garlic Butter Lamb Chops', 'With mashed potatoes.', 'fixed', 12000::numeric, 'BISTRO-PRO-002', 'Protein'),
    ('Honey Glazed Chicken', 'With honey, suya sauce and sesame seeds.', 'fixed', 7000::numeric, 'BISTRO-PRO-003', 'Protein'),
    ('Grilled Chicken with Teriyaki Glazed and Creamy Mash', null, 'fixed', 12000::numeric, 'BISTRO-PRO-004', 'Protein'),
    ('Grilled Chicken with Chicken Jus and Roasted Potatoes', null, 'fixed', 12000::numeric, 'BISTRO-PRO-005', 'Protein'),
    ('Spicy Cajun Garlic Butter Shrimp with Steamed Veggies', null, 'fixed', 12000::numeric, 'BISTRO-PRO-006', 'Protein'),
    ('Roasted Rack of Lamb with Lamb Jus and Creamy Mash', null, 'fixed', 12000::numeric, 'BISTRO-PRO-007', 'Protein'),
    ('Roasted Lamb Rack with Teriyaki Glazed and Roasted Potatoes', null, 'fixed', 12000::numeric, 'BISTRO-PRO-008', 'Protein'),
    ('Grilled Bone-in Chicken with Spicy Garlic Aioli and Steamed Veggies', null, 'fixed', 12000::numeric, 'BISTRO-PRO-009', 'Protein'),
    ('Chicken Milanese', null, 'fixed', 7000::numeric, 'BISTRO-PRO-010', 'Protein'),
    ('Crispy Chicken', 'Crispy chicken.', 'fixed', 6500::numeric, 'BISTRO-PRO-011', 'Protein'),
    ('Sweet and Sour Chicken', 'With pineapple and bell peppers.', 'fixed', 8000::numeric, 'BISTRO-PRO-012', 'Protein'),
    ('Chicken Skewer', 'Chicken skewer.', 'fixed', 6000::numeric, 'BISTRO-PRO-013', 'Protein'),
    ('Chicken Vegetable', 'Green vegetables.', 'fixed', 7000::numeric, 'BISTRO-PRO-014', 'Protein'),
    ('Beef Vegetable', 'Beef vegetable.', 'fixed', 7000::numeric, 'BISTRO-PRO-015', 'Protein'),
    ('Turkey', 'Turkey.', 'fixed', 7000::numeric, 'BISTRO-PRO-016', 'Protein'),
    ('Goat Meat', 'Goat meat.', 'fixed', 5500::numeric, 'BISTRO-PRO-017', 'Protein'),
    ('Beef', 'Cow meat.', 'fixed', 7000::numeric, 'BISTRO-PRO-018', 'Protein'),
    ('Fried Chicken', 'Fried chicken.', 'fixed', 7000::numeric, 'BISTRO-PRO-019', 'Protein'),
    ('Peppered Snail', 'Peppered snail.', 'fixed', 10000::numeric, 'BISTRO-PRO-020', 'Protein'),

    ('Beef Skewer', null, 'fixed', 6000::numeric, 'BISTRO-SID-001', 'Sides'),
    ('Asun', null, 'fixed', 7000::numeric, 'BISTRO-SID-002', 'Sides'),
    ('Peppered Kpomo', null, 'fixed', 4000::numeric, 'BISTRO-SID-003', 'Sides'),
    ('GizzDodo', null, 'fixed', 7000::numeric, 'BISTRO-SID-004', 'Sides'),
    ('Sharwama', null, 'fixed', 6000::numeric, 'BISTRO-SID-005', 'Sides'),
    ('Plantain', null, 'fixed', 3200::numeric, 'BISTRO-SID-006', 'Sides'),
    ('Extra Plantain', null, 'fixed', 1500::numeric, 'BISTRO-SID-007', 'Sides'),
    ('Samosa and Spring Roll', null, 'fixed', 4000::numeric, 'BISTRO-SID-008', 'Sides'),
    ('Tofu', null, 'fixed', 4000::numeric, 'BISTRO-SID-009', 'Sides'),

    ('Catfish Peppersoup', 'A cut of catfish in spicy broth.', 'fixed', 6500::numeric, 'BISTRO-PEP-001', 'Peppersoup'),
    ('Chicken Peppersoup', null, 'fixed', 7000::numeric, 'BISTRO-PEP-002', 'Peppersoup'),
    ('Goat Meat Peppersoup', null, 'fixed', 7000::numeric, 'BISTRO-PEP-003', 'Peppersoup'),

    ('Spaghetti Bolognese', 'With plum tomatoes and minced beef.', 'fixed', 9000::numeric, 'BISTRO-MOR-001', 'More Courses'),
    ('Coconut Rice', null, 'fixed', 7000::numeric, 'BISTRO-MOR-002', 'More Courses'),
    ('Goat Meat Peppersoup (Alt)', null, 'fixed', 4500::numeric, 'BISTRO-MOR-003', 'More Courses'),
    ('Local Jollof', 'With dried fish and kpomo.', 'fixed', 7000::numeric, 'BISTRO-MOR-004', 'More Courses'),
    ('Chicken Briyani Rice', 'With a serving of chicken.', 'fixed', 12000::numeric, 'BISTRO-MOR-005', 'More Courses'),
    ('Chinese Rice', 'With diced chicken and scrambled eggs.', 'fixed', 6500::numeric, 'BISTRO-MOR-006', 'More Courses'),
    ('Beef Briyani', 'With beef serving.', 'fixed', 12000::numeric, 'BISTRO-MOR-007', 'More Courses'),
    ('Porrige Beans', 'With dried fish.', 'fixed', 6500::numeric, 'BISTRO-MOR-008', 'More Courses'),
    ('Creamy Shrimp Alfredo pasta', 'With shrimp and mozzarella cheese/parmesan cheese.', 'fixed', 12000::numeric, 'BISTRO-MOR-009', 'More Courses'),
    ('Peri Peri Jollof Rice', null, 'fixed', 5500::numeric, 'BISTRO-MOR-010', 'More Courses'),
    ('Teriyaki Madness Bowl', 'With Chinese noodle, vegetables and diced proteins.', 'fixed', 10000::numeric, 'BISTRO-MOR-011', 'More Courses'),

    ('Egusi', null, 'fixed', 5000::numeric, 'BISTRO-SOU-001', 'Soup'),
    ('Ogbono', null, 'fixed', 5000::numeric, 'BISTRO-SOU-002', 'Soup'),
    ('Sea Food Okra', null, 'fixed', 20000::numeric, 'BISTRO-SOU-003', 'Soup'),
    ('Miyan Taushe', null, 'fixed', 5000::numeric, 'BISTRO-SOU-004', 'Soup'),
    ('Vegetable Soup', null, 'fixed', 4000::numeric, 'BISTRO-SOU-005', 'Soup'),
    ('Ewedu and Gbegiri', null, 'fixed', 4000::numeric, 'BISTRO-SOU-006', 'Soup'),

    ('Ceasar Salad', null, 'fixed', 18000::numeric, 'BISTRO-SAL-001', 'Salads'),
    ('Market salad', null, 'fixed', 18000::numeric, 'BISTRO-SAL-002', 'Salads'),
    ('Coleslaw', null, 'fixed', 18000::numeric, 'BISTRO-SAL-003', 'Salads'),
    ('Chef salad', null, 'fixed', 18000::numeric, 'BISTRO-SAL-004', 'Salads'),
    ('seasonal salad', null, 'fixed', 18000::numeric, 'BISTRO-SAL-005', 'Salads'),
    ('Casa Special Salad', null, 'fixed', 18000::numeric, 'BISTRO-SAL-006', 'Salads'),

    ('Smoothies', 'Banana, Strawberry, Watermelon, Apple Mint, bluespid.', 'fixed', 6000::numeric, 'BISTRO-DRK-001', 'Drinks'),
    ('Fresh Juice', 'Orange, Pineapple, Watermelon.', 'fixed', 5000::numeric, 'BISTRO-DRK-002', 'Drinks'),
    ('Mixed juice', null, 'fixed', 6000::numeric, 'BISTRO-DRK-003', 'Drinks'),
    ('Packet Juice', null, 'fixed', 3000::numeric, 'BISTRO-DRK-004', 'Drinks'),
    ('Pina Colada', null, 'fixed', 7000::numeric, 'BISTRO-DRK-005', 'Drinks'),
    ('Apple date milkshake', null, 'fixed', 7000::numeric, 'BISTRO-DRK-006', 'Drinks'),
    ('Strawberry milkshake', null, 'fixed', 7000::numeric, 'BISTRO-DRK-007', 'Drinks'),
    ('Water', null, 'fixed', 700::numeric, 'BISTRO-DRK-008', 'Drinks'),
    ('Detox Juice', null, 'fixed', 7000::numeric, 'BISTRO-DRK-009', 'Drinks')
) as seed(name, description, price_mode, price_amount, sku, category_name)
join public.menu_categories c
  on c.name = seed.category_name
 and c.kitchen_id = (select id from public.kitchens where slug = 'bistro-maitama-kitchen')
on conflict (sku) do update
set name = excluded.name,
    description = excluded.description,
    price_mode = excluded.price_mode,
    price_amount = excluded.price_amount,
    category_id = excluded.category_id,
    is_active = true,
    is_visible = true;


-- =====================
-- SEED BISTRO VARIABLE PRICE OPTIONS
-- =====================
update public.menu_items
set price_mode = 'variable',
    price_amount = null
where sku in ('BISTRO-BRK-007', 'BISTRO-MNC-009', 'BISTRO-DRK-001', 'BISTRO-DRK-002');

insert into public.menu_item_price_options (item_id, label, price_amount, sort_order)
select i.id, p.label, p.price_amount, p.sort_order
from public.menu_items i
join (
  values
    ('Plantain', 6000::numeric, 1),
    ('Yam', 6000::numeric, 2)
) as p(label, price_amount, sort_order) on true
where i.sku = 'BISTRO-BRK-007'
on conflict (item_id, label) do update
set price_amount = excluded.price_amount,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.menu_item_price_options (item_id, label, price_amount, sort_order)
select i.id, p.label, p.price_amount, p.sort_order
from public.menu_items i
join (
  values
    ('Chicken', 7500::numeric, 1),
    ('Beef', 7500::numeric, 2)
) as p(label, price_amount, sort_order) on true
where i.sku = 'BISTRO-MNC-009'
on conflict (item_id, label) do update
set price_amount = excluded.price_amount,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.menu_item_price_options (item_id, label, price_amount, sort_order)
select i.id, p.label, p.price_amount, p.sort_order
from public.menu_items i
join (
  values
    ('Banana', 6000::numeric, 1),
    ('Strawberry', 6000::numeric, 2),
    ('Watermelon', 6000::numeric, 3),
    ('Apple Mint', 6000::numeric, 4),
    ('Blue Spid', 6000::numeric, 5)
) as p(label, price_amount, sort_order) on true
where i.sku = 'BISTRO-DRK-001'
on conflict (item_id, label) do update
set price_amount = excluded.price_amount,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.menu_item_price_options (item_id, label, price_amount, sort_order)
select i.id, p.label, p.price_amount, p.sort_order
from public.menu_items i
join (
  values
    ('Orange', 5000::numeric, 1),
    ('Pineapple', 5000::numeric, 2),
    ('Watermelon', 5000::numeric, 3)
) as p(label, price_amount, sort_order) on true
where i.sku = 'BISTRO-DRK-002'
on conflict (item_id, label) do update
set price_amount = excluded.price_amount,
    sort_order = excluded.sort_order,
    is_active = true;


-- =====================
-- SEED BISTRO DRINK ADDONS
-- =====================
insert into public.menu_addons (name, price)
values
  ('Pineapple', 0),
  ('No Sugar', 0),
  ('Extra Ice', 0),
  ('Mint Leaves', 0),
  ('Ginger Shot', 1000)
on conflict (name) do update
set price = excluded.price;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('No Sugar', 'Extra Ice', 'Mint Leaves')
where i.sku in ('BISTRO-DRK-001', 'BISTRO-DRK-002', 'BISTRO-DRK-003', 'BISTRO-DRK-009')
on conflict (item_id, addon_id) do nothing;

insert into public.menu_item_addons (item_id, addon_id)
select i.id, a.id
from public.menu_items i
join public.menu_addons a
  on a.name in ('Apple', 'Carrot', 'Pineapple', 'Passion Fruit', 'Dragon Fruit', 'Cherry', 'Beetroot', 'Ginger', 'Lemon', 'Ginger Shot')
where i.sku = 'BISTRO-DRK-003'
on conflict (item_id, addon_id) do nothing;