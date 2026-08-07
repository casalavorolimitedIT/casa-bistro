-- Backfill sku for menu_items where sku is null.
--
-- Why: src/app/page.tsx only renders the "Review dish" button when item.sku is
-- set, and menu_item_reviews rows are keyed by item_sku. Items without a sku
-- can never be reviewed. 59 items across all kitchens currently have sku null.
--
-- Prefix strategy (in order):
--   1. Reuse the prefix already used by other items in the same category
--      (e.g. Breakfast/bistro already uses BISTRO-BRK-###, Can Beer uses BEER-###).
--   2. Fall back to <KITCHEN>-<CAT3>, e.g. BISTRO-LOC for Local Cuisines.
-- Numbering continues from the highest existing number for that prefix, so no
-- existing sku is touched and the unique constraint holds.
--
-- Run in the Supabase SQL editor (needs write access; the anon key cannot do this).
-- Idempotent: re-running is a no-op once every item has a sku.

begin;

with target as (
  select
    mi.id,
    mi.category_id,
    upper(split_part(k.slug, '-', 1)) as kitchen_prefix,
    mc.name                           as category_name
  from public.menu_items mi
  join public.menu_categories mc on mc.id = mi.category_id
  join public.kitchens k         on k.id  = mc.kitchen_id
  where mi.sku is null
),
existing_prefix as (
  select
    mi.category_id,
    (regexp_match(mi.sku, '^(.*)-[0-9]+$'))[1] as prefix,
    count(*)                                   as n
  from public.menu_items mi
  where mi.sku ~ '^[A-Z0-9-]+-[0-9]+$'
  group by 1, 2
),
best_prefix as (
  select distinct on (category_id) category_id, prefix
  from existing_prefix
  order by category_id, n desc, prefix
),
resolved as (
  select
    t.id,
    coalesce(
      b.prefix,
      t.kitchen_prefix || '-' ||
      upper(substr(regexp_replace(t.category_name, '[^a-zA-Z]', '', 'g'), 1, 3))
    ) as prefix
  from target t
  left join best_prefix b on b.category_id = t.category_id
),
numbered as (
  select
    r.id,
    r.prefix,
    row_number() over (partition by r.prefix order by r.id) as rn,
    coalesce((
      select max((regexp_match(mi2.sku, '([0-9]+)$'))[1]::int)
      from public.menu_items mi2
      where mi2.sku like r.prefix || '-%'
    ), 0) as base
  from resolved r
)
update public.menu_items mi
set sku        = n.prefix || '-' || lpad((n.base + n.rn)::text, 3, '0'),
    updated_at = now()
from numbered n
where mi.id = n.id;

-- Verify: expect 0 rows.
-- select count(*) from public.menu_items where sku is null;

commit;
