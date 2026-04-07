"use client";

import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import { menuData } from "./MenuData";
import ChristmasMenu from "./components/ChristmasMenu";
import CasaMenuItemReviewSheet from "./components/CasaMenuItemReviewSheet";
import CasaRestaurantReviewPrompt from "./components/CasaRestaurantReviewPrompt";

type MenuItem = {
  id: number;
  name: string;
  price: number;
  description?: string;
  items?: MenuItem[];
};

type MenuCategory = {
  id: number;
  name: string;
  items: MenuItem[];
};

type ReviewStat = {
  count: number;
  avgRating: number;
};

type ActiveReviewItem = {
  sku: string;
  name: string;
  price: number;
  description?: string;
  categoryName: string;
};

const KITCHEN_SLUG = "bistro-maitama-kitchen";

function toMainSku(categoryId: number, itemId: number) {
  return `casa-${categoryId}-${itemId}`;
}

function toSubSku(categoryId: number, itemId: number, subItemId: number) {
  return `casa-${categoryId}-${itemId}-${subItemId}`;
}

function StatBadge({ stat }: { stat?: ReviewStat }) {
  if (!stat || stat.count <= 0) return null;

  return (
    <p className="mt-2 text-xs font-medium text-amber-700 dark:text-amber-300">
      ★ {stat.avgRating.toFixed(1)} ({stat.count} review{stat.count > 1 ? "s" : ""})
    </p>
  );
}

export default function Home() {
  const [showChristmasMenu] = useState(false);
  const [activeItem, setActiveItem] = useState<ActiveReviewItem | null>(null);
  const [reviewStats, setReviewStats] = useState<Record<string, ReviewStat>>({});

  useEffect(() => {
    let cancelled = false;

    async function loadReviewStats() {
      try {
        const response = await fetch(
          `/api/landing/casa/reviews?target=item&kitchenSlug=${KITCHEN_SLUG}`,
          {
            method: "GET",
            cache: "no-store",
          },
        );

        if (!response.ok) return;

        const payload = (await response.json()) as {
          aggregatesByItem?: Array<{ itemSku: string; count: number; avgRating: number }>;
        };

        if (cancelled || !payload.aggregatesByItem) return;

        const mapped = payload.aggregatesByItem.reduce<Record<string, ReviewStat>>(
          (acc, entry) => {
            acc[entry.itemSku] = {
              count: entry.count,
              avgRating: entry.avgRating,
            };
            return acc;
          },
          {},
        );

        setReviewStats(mapped);
      } catch {
        // Silently ignore; reviews are additive, not blocking.
      }
    }

    void loadReviewStats();

    return () => {
      cancelled = true;
    };
  }, []);

  const categories = useMemo(
    () => Object.keys(menuData).map((categoryKey) => menuData[categoryKey] as MenuCategory),
    [],
  );

  return (
    <>
      {showChristmasMenu ? <ChristmasMenu /> : null}

      <div className="relative min-h-screen overflow-hidden p-6 font-sans text-gray-800 sm:p-10 dark:text-gray-800">
        <div className="fixed inset-0 z-0">
          <Image
            src="/banner3.jpg"
            alt="Casa-Bistro background"
            fill
            sizes="100vw"
            className="object-cover blur-sm"
            quality={80}
            priority
          />
          <div className="absolute inset-0 bg-black/70" />
        </div>

        <div className="fixed inset-0 z-0 bg-white/5 opacity-100 backdrop-blur-lg transition-opacity duration-300 dark:bg-gray-900/80" />

        <header className="relative z-10 flex flex-col items-center justify-center pb-12 pt-8 text-center">
          <Image
            src="/casalogo.png"
            alt="Casa-Bistro logo"
            width={120}
            height={120}
            className="mb-4 rounded-full shadow-lg"
          />
          <h1 className="text-4xl font-extrabold tracking-tight text-gray-50 sm:text-5xl">
            Casa-Bistro
          </h1>
          <p className="mt-2 max-w-prose text-lg text-gray-200">
            Experience culinary excellence with our carefully crafted dishes.
          </p>
        </header>

        <div className="relative z-10 my-12">
          <Image
            src="/christmas.png"
            alt="Special offer"
            width={1200}
            height={600}
            className="mx-auto w-full max-w-4xl rounded-lg shadow-xl"
          />
        </div>

        <main className="relative z-10 mx-auto max-w-6xl">
          {categories.map((category) => (
            <section key={category.id} className="mb-16">
              <h2 className="mb-8 border-b-2 border-orange-400 pb-2 text-3xl font-bold text-gray-200">
                {category.name}
              </h2>

              <ul className="grid grid-cols-1 gap-8 md:grid-cols-2">
                {category.items.map((item) => {
                  const itemSku = toMainSku(category.id, item.id);
                  const itemStat = reviewStats[itemSku];

                  return (
                    <li
                      key={itemSku}
                      className="rounded-lg bg-white/80 p-6 shadow-md backdrop-blur-sm transition duration-300 hover:-translate-y-1 hover:shadow-lg dark:bg-gray-800/80"
                    >
                      <div className="mb-2 flex items-start justify-between gap-3">
                        <h3 className="text-xl font-semibold text-orange-600 dark:text-orange-400">
                          {item.name}
                        </h3>
                        <span className="text-xl font-bold text-gray-900 dark:text-gray-100">
                          ₦{item.price.toLocaleString()}
                        </span>
                      </div>

                      {item.description && (
                        <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                          {item.description}
                        </p>
                      )}

                      <StatBadge stat={itemStat} />

                      <div className="mt-3 flex justify-end">
                        <button
                          type="button"
                          onClick={() =>
                            setActiveItem({
                              sku: itemSku,
                              name: item.name,
                              price: item.price,
                              description: item.description,
                              categoryName: category.name,
                            })
                          }
                          className="rounded-md border border-orange-400/70 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-orange-700 transition hover:bg-orange-500/10 dark:text-orange-300"
                        >
                          Review this dish
                        </button>
                      </div>

                      {item.items && (
                        <ul className="mt-6 ml-4 space-y-3 border-l-2 border-gray-200 pl-4 dark:border-gray-700">
                          {item.items.map((subItem) => {
                            const subSku = toSubSku(category.id, item.id, subItem.id);
                            const subStat = reviewStats[subSku];

                            return (
                              <li
                                key={subSku}
                                className="rounded-md bg-gray-100/80 p-3 shadow-sm backdrop-blur-sm dark:bg-gray-700/80"
                              >
                                <div className="flex items-center justify-between gap-3">
                                  <span className="text-base text-gray-700 dark:text-gray-300">
                                    {subItem.name}
                                  </span>
                                  <span className="text-base font-semibold text-gray-800 dark:text-gray-200">
                                    ₦{subItem.price.toLocaleString()}
                                  </span>
                                </div>

                                {subItem.description && (
                                  <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                    {subItem.description}
                                  </p>
                                )}

                                <StatBadge stat={subStat} />

                                <div className="mt-2 flex justify-end">
                                  <button
                                    type="button"
                                    onClick={() =>
                                      setActiveItem({
                                        sku: subSku,
                                        name: subItem.name,
                                        price: subItem.price,
                                        description: subItem.description,
                                        categoryName: category.name,
                                      })
                                    }
                                    className="rounded-md border border-orange-400/60 px-2 py-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-orange-700 transition hover:bg-orange-500/10 dark:text-orange-300"
                                  >
                                    Review
                                  </button>
                                </div>
                              </li>
                            );
                          })}
                        </ul>
                      )}
                    </li>
                  );
                })}
              </ul>
            </section>
          ))}
        </main>
      </div>

      <CasaMenuItemReviewSheet
        item={activeItem}
        kitchenSlug={KITCHEN_SLUG}
        onClose={() => setActiveItem(null)}
      />

      <CasaRestaurantReviewPrompt kitchenSlug={KITCHEN_SLUG} />
    </>
  );
}
