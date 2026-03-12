"use client";
import {
  QueryClient,
  QueryClientProvider,
  useQuery,
} from "@tanstack/react-query";
import Image from "next/image";
import { useMemo, useState } from "react";
import ChristmasMenu from "./components/ChristmasMenu";
import MenuError from "./components/menuError";
import SmartImage from "./components/smart-images";

type Addon = {
  id: string;
  name: string;
  price: number;
};

type MenuItem = {
  category_name: string;
  name: string;
  description: string | null;
  price_mode: string;
  price_amount: number | null;
  image_url: string | null;
  sku: string;
  category_sort_order: number;
  kitchen_slug: string;
  addons: Addon[];
};

type BistroMenuResponse = {
  kitchenSlug: string;
  count: number;
  items: MenuItem[];
};

type GroupedCategory = {
  categoryName: string;
  categorySortOrder: number;
  items: MenuItem[];
};

function isChristmasSeason(): boolean {
  const now = new Date();
  const month = now.getMonth() + 1; // 1-based
  const day = now.getDate();
  // Show from Dec 18 through Jan 2
  return (month === 12 && day >= 18) || (month === 1 && day <= 2);
}

function formatPrice(item: MenuItem): string {
  if (item.price_mode === "tbd") return "Price on request";
  if (item.price_mode === "variable") return "Variable pricing";
  if (item.price_amount === null) return "—";
  return `₦${item.price_amount.toLocaleString()}`;
}

function groupItems(items: MenuItem[]): GroupedCategory[] {
  const map = new Map<string, GroupedCategory>();
  for (const item of items) {
    const key = `${item.category_sort_order}-${item.category_name}`;
    if (!map.has(key)) {
      map.set(key, {
        categoryName: item.category_name,
        categorySortOrder: item.category_sort_order,
        items: [],
      });
    }
    map.get(key)?.items.push(item);
  }
  return Array.from(map.values()).sort(
    (a, b) => a.categorySortOrder - b.categorySortOrder,
  );
}

async function fetchBistroMenu(): Promise<BistroMenuResponse> {
  const response = await fetch("/api/landing/bistro", { method: "GET" });
  if (!response.ok) throw new Error("Could not load Bistro menu");
  return response.json() as Promise<BistroMenuResponse>;
}

function MenuContent() {
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ["bistro-menu"],
    queryFn: fetchBistroMenu,
    staleTime: 0,
    refetchInterval: 30_000,
    refetchIntervalInBackground: true,
    refetchOnWindowFocus: true,
  });

  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedPriceMode, setSelectedPriceMode] = useState("all");
  const [showChristmasMenu, setShowChristmasMenu] = useState(false);

  const showSeasonalBanner = isChristmasSeason();

  const categories = useMemo(() => {
    if (!data) return [];
    return Array.from(
      new Set(data.items.map((item) => item.category_name)),
    ).sort();
  }, [data]);

  const filteredItems = useMemo(() => {
    if (!data) return [];
    const normalizedSearch = searchTerm.trim().toLowerCase();
    return data.items.filter((item) => {
      const matchesSearch =
        normalizedSearch.length === 0 ||
        item.name.toLowerCase().includes(normalizedSearch) ||
        item.category_name.toLowerCase().includes(normalizedSearch) ||
        (item.description ?? "").toLowerCase().includes(normalizedSearch) ||
        item.sku.toLowerCase().includes(normalizedSearch);
      const matchesCategory =
        selectedCategory === "all" || item.category_name === selectedCategory;
      const matchesPriceMode =
        selectedPriceMode === "all" || item.price_mode === selectedPriceMode;
      return matchesSearch && matchesCategory && matchesPriceMode;
    });
  }, [data, searchTerm, selectedCategory, selectedPriceMode]);

  const groupedCategories = groupItems(filteredItems);

  const filtersActive =
    searchTerm.trim().length > 0 ||
    selectedCategory !== "all" ||
    selectedPriceMode !== "all";

  const clearFilters = () => {
    setSearchTerm("");
    setSelectedCategory("all");
    setSelectedPriceMode("all");
  };

  return (
    <div className="min-h-screen bg-[#0d0c0a] text-[#e8d9b5] font-sans">
      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <header className="relative h-[60vh] min-h-[380px] flex flex-col items-center justify-center overflow-hidden">
        {/* full-bleed hero image */}
        <Image
          src="/banner3.jpg"
          alt="Casa-Bistro kitchen"
          fill
          priority
          quality={85}
          className="object-cover object-center brightness-[0.35]"
        />

        {/* grain texture overlay */}
        <div
          className="absolute inset-0 opacity-30"
          style={{
            backgroundImage:
              "url(\"data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E\")",
            backgroundRepeat: "repeat",
            backgroundSize: "180px",
          }}
        />

        {/* decorative top rule */}
        <div className="relative z-10 flex flex-col items-center gap-4 px-6 text-center">
          <div className="flex items-center gap-4 w-full justify-center">
            <span className="h-px w-12 bg-[#c9a84c]" />
            <span className="text-[10px] tracking-[0.4em] uppercase text-[#c9a84c]">
              Est. Casa Lavoro
            </span>
            <span className="h-px w-12 bg-[#c9a84c]" />
          </div>

          <Image
            src="/casalogo.png"
            alt="Casa-Bistro Logo"
            width={88}
            height={88}
            className="rounded-full ring-2 ring-[#c9a84c]/40 shadow-2xl"
          />

          <h1 className="text-5xl sm:text-6xl font-light tracking-[0.08em] text-white">
            Casa<span className="text-[#c9a84c] font-semibold">-Bistro</span>
          </h1>

          <p className="text-sm tracking-widest text-[#c9a84c]/70 uppercase">
            Fine Dining · Abuja
          </p>
        </div>
      </header>

      {/* ── Seasonal Christmas Banner (Dec 18 – Jan 2) ───────────────── */}
      {showSeasonalBanner && (
        <section className="relative z-10 bg-[#0d0c0a] py-8 px-4">
          <div className="mx-auto max-w-4xl">
            <div className="relative overflow-hidden rounded-sm border border-[#c9a84c]/20">
              <Image
                src="/christmas.png"
                alt="Festive Season Special"
                width={1200}
                height={540}
                className="w-full object-cover"
              />
              <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-6">
                <p className="text-xs uppercase tracking-[0.35em] text-[#c9a84c]">
                  Limited Season Offering
                </p>
                <button
                  type="button"
                  onClick={() => setShowChristmasMenu((v) => !v)}
                  className="mt-2 inline-flex items-center gap-2 border border-[#c9a84c]/60 px-5 py-2 text-xs uppercase tracking-[0.25em] text-[#c9a84c] transition hover:bg-[#c9a84c]/10"
                >
                  {showChristmasMenu
                    ? "Hide Festive Menu"
                    : "View Festive Menu"}
                </button>
              </div>
            </div>

            {showChristmasMenu && (
              <div className="mt-6 border border-[#c9a84c]/10 bg-[#111009] p-6">
                <ChristmasMenu />
              </div>
            )}
          </div>
        </section>
      )}

      {/* ── Divider ──────────────────────────────────────────────────── */}
      <div className="flex items-center gap-6 px-6 py-10 max-w-5xl mx-auto">
        <span className="h-px flex-1 bg-[#c9a84c]/15" />
        <span className="text-[10px] tracking-[0.5em] uppercase text-[#c9a84c]/50">
          Our Menu
        </span>
        <span className="h-px flex-1 bg-[#c9a84c]/15" />
      </div>

      {/* ── Menu Body ────────────────────────────────────────────────── */}
      <main className="px-4 pb-24 md:px-10">
        {isLoading && (
          <div className="flex flex-col items-center gap-4 py-32">
            {/* animated flame loader */}
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              className="h-10 w-10 animate-pulse"
            >
              <path
                d="M12 2C12 2 7 8 7 13a5 5 0 0 0 10 0c0-5-5-11-5-11Z"
                fill="#c9a84c"
                opacity="0.6"
              />
              <path
                d="M12 10c0 0-2 3-2 5a2 2 0 0 0 4 0c0-2-2-5-2-5Z"
                fill="#e8d9b5"
              />
            </svg>
            <p className="text-xs uppercase tracking-[0.4em] text-[#c9a84c]/60">
              Preparing the menu…
            </p>
          </div>
        )}

        {isError && <MenuError message={(error as Error).message} />}

        {!isLoading && !isError && (
          <div className="max-w-5xl mx-auto space-y-14">
            {/* ── Filter bar ───────────────────────────────────────── */}
            <div className="rounded-sm border border-[#c9a84c]/10 bg-[#111009] px-5 py-4">
              <div className="flex flex-col gap-3 md:flex-row md:items-end">
                {/* Search */}
                <div className="flex-1 flex flex-col gap-1">
                  <label className="text-[9px] uppercase tracking-[0.4em] text-[#c9a84c]/50">
                    Search
                  </label>
                  <input
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    placeholder="Dish, drink, or description…"
                    className="border-b border-[#c9a84c]/20 bg-transparent py-2 text-sm text-[#e8d9b5] placeholder:text-[#7a6e54] focus:border-[#c9a84c] focus:outline-none"
                  />
                </div>

                {/* Category */}
                <div className="flex flex-col gap-1 md:w-44">
                  <label className="text-[9px] uppercase tracking-[0.4em] text-[#c9a84c]/50">
                    Category
                  </label>
                  <select
                    aria-label="Filter by category"
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                    className="border-b border-[#c9a84c]/20 bg-transparent py-2 text-sm text-[#e8d9b5] focus:border-[#c9a84c] focus:outline-none"
                  >
                    <option value="all" className="bg-[#111009]">
                      All categories
                    </option>
                    {categories.map((c) => (
                      <option key={c} value={c} className="bg-[#111009]">
                        {c}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Price mode */}
                <div className="flex flex-col gap-1 md:w-36">
                  <label className="text-[9px] uppercase tracking-[0.4em] text-[#c9a84c]/50">
                    Pricing
                  </label>
                  <select
                    aria-label="Filter by pricing type"
                    value={selectedPriceMode}
                    onChange={(e) => setSelectedPriceMode(e.target.value)}
                    className="border-b border-[#c9a84c]/20 bg-transparent py-2 text-sm text-[#e8d9b5] focus:border-[#c9a84c] focus:outline-none"
                  >
                    <option value="all" className="bg-[#111009]">
                      All pricing
                    </option>
                    <option value="fixed" className="bg-[#111009]">
                      Fixed
                    </option>
                    <option value="variable" className="bg-[#111009]">
                      Variable
                    </option>
                    <option value="tbd" className="bg-[#111009]">
                      On request
                    </option>
                  </select>
                </div>

                {/* Clear */}
                <button
                  type="button"
                  onClick={clearFilters}
                  disabled={!filtersActive}
                  className="shrink-0 self-end pb-2 text-[10px] uppercase tracking-[0.25em] text-[#c9a84c]/60 hover:text-[#c9a84c] disabled:cursor-not-allowed disabled:opacity-25 transition"
                >
                  Clear
                </button>
              </div>

              <p className="mt-4 text-[10px] uppercase tracking-widest text-[#9e8c6a]">
                {filteredItems.length}&nbsp;of&nbsp;{data?.count ?? 0}
                &nbsp;items
              </p>
            </div>

            {filteredItems.length === 0 && (
              <p className="py-20 text-center text-sm text-[#a89870] tracking-wider">
                No items match your filters.
              </p>
            )}

            {/* ── Category sections ────────────────────────────────── */}
            {groupedCategories.map((category) => (
              <section
                key={`${category.categorySortOrder}-${category.categoryName}`}
              >
                {/* Category heading */}
                <div className="mb-8 flex items-center gap-5">
                  <span className="h-5 w-px bg-[#c9a84c]" />
                  <h2 className="text-[11px] font-semibold uppercase tracking-[0.45em] text-[#c9a84c]">
                    {category.categoryName}
                  </h2>
                  <span className="h-px flex-1 bg-[#c9a84c]/12" />
                </div>

                {/* Items */}
                <div className="divide-y divide-[#c9a84c]/10">
                  {category.items.map((item) => (
                    <article
                      key={item.sku}
                      className="group grid grid-cols-1 gap-0.5 py-6 sm:grid-cols-[1fr_auto]"
                    >
                      {/* Left: name + description */}
                      <div className="flex gap-3">
                        <SmartImage
                          src={item.image_url ?? "/placeholder.png"}
                          alt={item.name}
                          width={40}
                          height={40}
                          className="object-cover w-[40px] h-[40px] object-center brightness-[0.65] aspect-square rounded-sm self-start"
                        />
                        <div className="w-full">
                          <div className="flex items-start justify-between gap-6 sm:block w-full">
                            <h3 className="text-[15px] font-medium text-[#f0e4c3] leading-snug tracking-wide">
                              {item.name}
                            </h3>
                            {/* price shown inline on mobile */}
                            <span className="shrink-0 text-sm text-[#c9a84c] sm:hidden">
                              {formatPrice(item)}
                            </span>
                          </div>

                          {item.description && (
                            <p className="mt-1.5 max-w-lg text-sm leading-relaxed text-[#d6c08a]">
                              {item.description}
                            </p>
                          )}

                          {item.addons.length > 0 && (
                            <p className="mt-3 text-[11px] text-[#a89870] leading-relaxed">
                              <span className="mr-1.5 uppercase tracking-[0.2em] text-[#9e8c6a]">
                                Choice of:
                              </span>
                              {item.addons
                                .map((addon) =>
                                  addon.price > 0
                                    ? `${addon.name} (+₦${addon.price.toLocaleString()})`
                                    : addon.name,
                                )
                                .join("  ·  ")}
                            </p>
                          )}
                        </div>
                      </div>

                      {/* Right: price on desktop */}
                      <div className="hidden sm:flex sm:items-start sm:justify-end">
                        <span className="mt-0.5 text-sm font-medium text-[#c9a84c] tracking-wide">
                          {formatPrice(item)}
                        </span>
                      </div>
                    </article>
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </main>

      {/* ── Footer ───────────────────────────────────────────────────── */}
      <footer className="border-t border-[#c9a84c]/10 py-10 text-center">
        <div className="flex items-center justify-center gap-4 mb-4">
          <span className="h-px w-8 bg-[#c9a84c]/30" />
          <Image
            src="/casalogo.png"
            alt="Casa-Bistro"
            width={36}
            height={36}
            className="rounded-full opacity-60"
          />
          <span className="h-px w-8 bg-[#c9a84c]/30" />
        </div>
        <p className="text-[10px] tracking-[0.4em] uppercase text-[#9e8c6a]">
          Casa-Bistro · Casa Lavoro Limited
        </p>
      </footer>
    </div>
  );
}

export default function Home() {
  const [queryClient] = useState(() => new QueryClient());
  return (
    <QueryClientProvider client={queryClient}>
      <MenuContent />
    </QueryClientProvider>
  );
}
