import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

const DEFAULT_KITCHEN_SLUG = "bistro-maitama-kitchen";
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

const FEEDBACK_MIN = 10;
const FEEDBACK_MAX = 600;

type ReviewPayload = {
  targetType?: "item" | "restaurant";
  kitchenSlug?: string;
  itemSku?: string;
  itemName?: string;
  rating?: number;
  feedback?: string;
  reviewerName?: string | null;
  triggerSource?: string;
};

type ReadTarget = "item" | "restaurant";

function getHeaders() {
  return {
    apikey: SUPABASE_ANON_KEY ?? "",
    Authorization: `Bearer ${SUPABASE_ANON_KEY ?? ""}`,
    "Content-Type": "application/json",
  };
}

function ensureEnv() {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return NextResponse.json(
      {
        error:
          "Supabase environment variables are missing. Set SUPABASE_URL and SUPABASE_ANON_KEY.",
      },
      { status: 500 },
    );
  }

  return null;
}

function validatePayload(payload: ReviewPayload): string | null {
  if (!payload.targetType || !["item", "restaurant"].includes(payload.targetType)) {
    return "targetType must be item or restaurant.";
  }

  if (!payload.rating || !Number.isInteger(payload.rating) || payload.rating < 1 || payload.rating > 5) {
    return "rating must be an integer between 1 and 5.";
  }

  const feedbackLength = payload.feedback?.trim().length ?? 0;
  if (feedbackLength < FEEDBACK_MIN || feedbackLength > FEEDBACK_MAX) {
    return `feedback must be between ${FEEDBACK_MIN} and ${FEEDBACK_MAX} characters.`;
  }

  if (payload.targetType === "item" && !payload.itemSku) {
    return "itemSku is required for item reviews.";
  }

  return null;
}

export async function POST(request: Request) {
  const envError = ensureEnv();
  if (envError) return envError;

  let payload: ReviewPayload;
  try {
    payload = (await request.json()) as ReviewPayload;
  } catch {
    return NextResponse.json({ error: "Invalid JSON payload." }, { status: 400 });
  }

  const validationError = validatePayload(payload);
  if (validationError) {
    return NextResponse.json({ error: validationError }, { status: 400 });
  }

  const kitchenSlug = payload.kitchenSlug?.trim() || DEFAULT_KITCHEN_SLUG;
  const reviewerName = payload.reviewerName?.trim() || null;
  const triggerSource = payload.triggerSource?.trim() || "unknown";
  const feedback = payload.feedback!.trim();
  const sessionId = request.headers.get("x-forwarded-for") ?? "anonymous";

  const insertBody =
    payload.targetType === "item"
      ? {
          kitchen_slug: kitchenSlug,
          item_sku: payload.itemSku,
          item_name: payload.itemName?.trim() || null,
          rating: payload.rating,
          feedback,
          reviewer_name: reviewerName,
          session_id: sessionId,
          trigger_source: triggerSource,
          status: "pending",
        }
      : {
          kitchen_slug: kitchenSlug,
          rating: payload.rating,
          feedback,
          reviewer_name: reviewerName,
          session_id: sessionId,
          trigger_source: triggerSource,
          status: "pending",
        };

  const tableName =
    payload.targetType === "item" ? "menu_item_reviews" : "restaurant_reviews";

  const response = await fetch(`${SUPABASE_URL}/rest/v1/${tableName}`, {
    method: "POST",
    headers: {
      ...getHeaders(),
      Prefer: "return=minimal",
    },
    body: JSON.stringify(insertBody),
    cache: "no-store",
  });

  if (!response.ok) {
    const details = await response.text();
    console.error("Casa review insert failed", { status: response.status, details });

    return NextResponse.json(
      { error: "Unable to submit review right now." },
      { status: 502 },
    );
  }

  return NextResponse.json({ ok: true, status: "pending" }, { status: 201 });
}

export async function GET(request: Request) {
  const envError = ensureEnv();
  if (envError) return envError;

  const { searchParams } = new URL(request.url);
  const kitchenSlug = searchParams.get("kitchenSlug") ?? DEFAULT_KITCHEN_SLUG;
  const target = (searchParams.get("target") ?? "item") as ReadTarget;

  if (!(["item", "restaurant"] as const).includes(target)) {
    return NextResponse.json(
      { error: "target must be item or restaurant." },
      { status: 400 },
    );
  }

  if (target === "item") {
    const itemSku = searchParams.get("itemSku");

    const query = new URLSearchParams({
      kitchen_slug: `eq.${kitchenSlug}`,
      status: "eq.approved",
      select:
        "id,item_sku,item_name,rating,feedback,reviewer_name,created_at,trigger_source",
      order: "created_at.desc",
      limit: "500",
    });

    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/menu_item_reviews?${query.toString()}`,
      {
        headers: getHeaders(),
        cache: "no-store",
      },
    );

    if (!response.ok) {
      const details = await response.text();
      console.error("Failed to read Casa approved item reviews", details);
      return NextResponse.json(
        { error: "Unable to read approved reviews." },
        { status: 502 },
      );
    }

    const rows = (await response.json()) as Array<{
      item_sku: string;
      rating: number;
    }>;

    const filteredRows = itemSku
      ? rows.filter((row) => row.item_sku === itemSku)
      : rows;

    const count = filteredRows.length;
    const avgRating =
      count > 0
        ? filteredRows.reduce((sum, row) => sum + Number(row.rating), 0) / count
        : 0;

    const aggregatesByItem = Object.values(
      filteredRows.reduce<
        Record<string, { itemSku: string; count: number; total: number; avgRating: number }>
      >((acc, row) => {
        const key = row.item_sku;
        if (!key) return acc;

        if (!acc[key]) {
          acc[key] = { itemSku: key, count: 0, total: 0, avgRating: 0 };
        }

        acc[key].count += 1;
        acc[key].total += Number(row.rating);
        acc[key].avgRating = acc[key].total / acc[key].count;
        return acc;
      }, {}),
    ).map((entry) => ({
      itemSku: entry.itemSku,
      count: entry.count,
      avgRating: Number(entry.avgRating.toFixed(1)),
    }));

    return NextResponse.json({
      target: "item",
      itemSku,
      count,
      avgRating,
      aggregatesByItem,
      reviews: filteredRows,
    });
  }

  const query = new URLSearchParams({
    kitchen_slug: `eq.${kitchenSlug}`,
    status: "eq.approved",
    select: "id,rating,feedback,reviewer_name,created_at,trigger_source",
    order: "created_at.desc",
    limit: "100",
  });

  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/restaurant_reviews?${query.toString()}`,
    {
      headers: getHeaders(),
      cache: "no-store",
    },
  );

  if (!response.ok) {
    const details = await response.text();
    console.error("Failed to read Casa restaurant reviews", details);
    return NextResponse.json(
      { error: "Unable to read approved reviews." },
      { status: 502 },
    );
  }

  const rows = (await response.json()) as Array<{ rating: number }>;
  const count = rows.length;
  const avgRating =
    count > 0 ? rows.reduce((sum, row) => sum + Number(row.rating), 0) / count : 0;

  return NextResponse.json({
    target: "restaurant",
    count,
    avgRating,
    reviews: rows,
  });
}
