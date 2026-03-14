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

`schema.sql` now includes a complete Bistro seed block under:

- `BISTRO MAITAMA - SEED DATA`

Run `schema.sql` in Supabase, then validate Bistro menu exists:

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

Important pricing note:

- `fixed` items use `price_amount`
- `variable` items use `price_options`; `price_amount` is expected to be `null`
- `tbd` items have no live amount yet

Do not treat `price_amount` as the display price for every row. For variable items, the landing page should render `From ₦...` using the minimum active option price in `price_options`.

## Step 6: Add fetch helper in each external site

Example helper (`lib/menu-api.ts`):

```ts
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export type KitchenSlug = "cenare-wuse-kitchen" | "bistro-maitama-kitchen";

export type MenuPriceOption = {
  id: string;
  label: string;
  price_amount: number;
  sort_order: number;
};

export type MenuApiRow = {
  category_name: string;
  item_name: string;
  item_description: string | null;
  item_sku: string | null;
  image_url: string | null;
  category_sort_order: number | null;
  price_mode: "fixed" | "variable" | "tbd";
  price_amount: number | null;
  price_options: MenuPriceOption[];
  addons: Array<{ id: string; name: string; price: number }>;
};

export type NormalizedMenuItem = MenuApiRow & {
  display_price: number | null;
  display_price_label: string;
};

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

  return response.json() as Promise<MenuApiRow[]>;
}

export function normalizeMenuItems(rows: MenuApiRow[]): NormalizedMenuItem[] {
  return rows.map((row) => {
    if (row.price_mode === "variable") {
      const prices = row.price_options
        .map((option) => Number(option.price_amount))
        .filter((price) => Number.isFinite(price));

      const minPrice = prices.length > 0 ? Math.min(...prices) : null;

      return {
        ...row,
        display_price: minPrice,
        display_price_label:
          minPrice === null
            ? "Variable pricing"
            : `From ₦${new Intl.NumberFormat("en-NG", {
                minimumFractionDigits: 0,
              }).format(minPrice)}`,
      };
    }

    if (row.price_mode === "tbd" || row.price_amount === null) {
      return {
        ...row,
        display_price: null,
        display_price_label: "Price TBD",
      };
    }

    return {
      ...row,
      display_price: row.price_amount,
      display_price_label: new Intl.NumberFormat("en-NG", {
        style: "currency",
        currency: "NGN",
        minimumFractionDigits: 0,
      }).format(row.price_amount),
    };
  });
}
```

## Step 7: Render the normalized price per website

Example:

```ts
const rows = await fetchMenuByKitchenSlug("cenare-wuse-kitchen");
const items = normalizeMenuItems(rows);

items.map((item) => item.display_price_label);
```

- Cenare site: call `fetchMenuByKitchenSlug("cenare-wuse-kitchen")`
- Bistro site: call `fetchMenuByKitchenSlug("bistro-maitama-kitchen")`
- For variable items, render `display_price_label` instead of raw `price_amount`

## Step 8: Add a minimal smoke test checklist

1. Cenare page loads with Cenare categories/items only.
2. Bistro page loads with Bistro categories/items only.
3. Hidden/inactive items do not appear.
4. Variable-price items render as `From ₦...` using `price_options`, not `price_amount`.
5. Fixed-price items render from `price_amount`.
6. No service role key is exposed in frontend code.
7. API errors show fallback UI instead of blank page.

## Optional: Proxy through Kitchen CMS API

If you do not want direct Supabase calls from external apps, add a proxy endpoint in this repo:

- `app/api/landing/cenare/route.ts`
- `app/api/landing/bistro/route.ts`

Each route can fetch with a server client and return normalized JSON.
This approach hides direct Supabase details from external websites.
