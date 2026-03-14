import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

const BISTRO_KITCHEN_SLUG = "bistro-maitama-kitchen";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

export async function GET() {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return NextResponse.json(
      {
        error:
          "Supabase environment variables are missing. Set SUPABASE_URL and SUPABASE_ANON_KEY.",
      },
      { status: 500 },
    );
  }

  const query = new URLSearchParams({
    kitchen_slug: `eq.${BISTRO_KITCHEN_SLUG}`,
    is_active: "eq.true",
    is_visible: "eq.true",
    select:
      "category_name,name,description,price_mode,price_amount,price_options,image_url,sku,category_sort_order,kitchen_slug,addons",
    order: "category_sort_order.asc,name.asc",
  });

  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/v_menu_full?${query.toString()}`,
      {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
        cache: "no-store",
      },
    );

    if (!response.ok) {
      const text = await response.text();
      console.error("Bistro proxy upstream error", {
        status: response.status,
        body: text,
      });

      return NextResponse.json(
        { error: "Failed to fetch Bistro menu" },
        { status: 502 },
      );
    }

    const items = (await response.json()) as unknown[];

    return NextResponse.json({
      kitchenSlug: BISTRO_KITCHEN_SLUG,
      count: items.length,
      items,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown server error";

    console.error("Bistro proxy request failed", message);

    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
