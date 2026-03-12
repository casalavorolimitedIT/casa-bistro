# Cenare and Bistro API Integration Guide

This guide shows how to expose and consume menu data from Supabase for the external landing pages.

## Kitchen slugs to use

- Cenare: `cenare-wuse-kitchen`
- Bistro: `bistro-maitama-kitchen`

These slugs are defined in `schema.sql` in the kitchens seed.

## Step 1: Confirm environment variables

In each external app (Cenare site and Bistro site), set:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://<your-project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
```

Get both values from Supabase Dashboard:

- `Project Settings` -> `API` -> `Project URL`
- `Project Settings` -> `API` -> `anon public`

## Step 2: Verify kitchen records exist

Run this SQL in Supabase SQL editor:

```sql
select id, name, slug, is_active
from public.kitchens
where slug in ('cenare-wuse-kitchen', 'bistro-maitama-kitchen');
```

Expected result: both kitchens appear.

## Step 3: Seed Bistro data (required)

Bistro records are required before Bistro landing can return real menu content.

1. Open `schema.sql`.
2. Locate Bistro seed section near comments about Bistro categories/items.
3. Replace placeholders with real Bistro categories and items.
4. Run the updated SQL in Supabase.
5. Validate Bistro menu exists:

```sql
select c.name as category_name, i.name as item_name, i.price_mode, i.price_amount
from public.menu_items i
join public.menu_categories c on c.id = i.category_id
join public.kitchens k on k.id = c.kitchen_id
where k.slug = 'bistro-maitama-kitchen'
order by c.sort_order, i.name;
```

## Step 4: Enable safe public read access (RLS)

If external landing pages are public, create a read policy that only returns visible/active records.

```sql
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;

create policy if not exists "public read active categories"
on public.menu_categories
for select
to anon
using (is_active = true);

create policy if not exists "public read visible active items"
on public.menu_items
for select
to anon
using (is_active = true and is_visible = true);
```

Adjust conditions if your business rules differ.

## Step 5: Query Supabase REST API by kitchen slug

Supabase REST base URL:

```text
https://<your-project-ref>.supabase.co/rest/v1
```

### Cenare request

```http
GET /rest/v1/v_menu_full?kitchen_slug=eq.cenare-wuse-kitchen&is_active=eq.true&is_visible=eq.true&select=category_name,item_name,item_description,price_mode,price_amount,image_url,item_sku,category_sort_order,price_options,addons
apikey: <anon-key>
Authorization: Bearer <anon-key>
```

### Bistro request

```http
GET /rest/v1/v_menu_full?kitchen_slug=eq.bistro-maitama-kitchen&is_active=eq.true&is_visible=eq.true&select=category_name,item_name,item_description,price_mode,price_amount,image_url,item_sku,category_sort_order,price_options,addons
apikey: <anon-key>
Authorization: Bearer <anon-key>
```

Note: use `public.v_menu_full` as the single menu API view defined in `schema.sql`.

## Step 6: Add fetch helper in each external site

Example helper (`lib/menu-api.ts`):

```ts
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export type KitchenSlug = "cenare-wuse-kitchen" | "bistro-maitama-kitchen";

export async function fetchMenuByKitchenSlug(kitchenSlug: KitchenSlug) {
  const query = new URLSearchParams({
    kitchen_slug: `eq.${kitchenSlug}`,
    is_active: "eq.true",
    is_visible: "eq.true",
    select:
      "category_name,item_name,item_description,price_mode,price_amount,image_url,item_sku,category_sort_order,price_options,addons",
    order: "category_sort_order.asc,item_name.asc",
  });

  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/v_menu_full?${query.toString()}`,
    {
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      },
      next: { revalidate: 60 },
    },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Menu API error ${response.status}: ${text}`);
  }

  return response.json();
}
```

## Step 7: Use the helper per website

- Cenare site: call `fetchMenuByKitchenSlug("cenare-wuse-kitchen")`
- Bistro site: call `fetchMenuByKitchenSlug("bistro-maitama-kitchen")`

## Step 8: Add a minimal smoke test checklist

1. Cenare page loads with Cenare categories/items only.
2. Bistro page loads with Bistro categories/items only.
3. Hidden/inactive items do not appear.
4. No service role key is exposed in frontend code.
5. API errors show fallback UI instead of blank page.

## Optional: Proxy through Kitchen CMS API

If you do not want direct Supabase calls from external apps, add a proxy endpoint in this repo:

- `app/api/landing/cenare/route.ts`
- `app/api/landing/bistro/route.ts`

Each route can fetch with a server client and return normalized JSON.
This approach hides direct Supabase details from external websites.
