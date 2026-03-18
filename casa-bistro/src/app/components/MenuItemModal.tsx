"use client";

import { useEffect, useCallback } from "react";
import SmartImage from "./smart-images";

type Addon = {
  id: string;
  name: string;
  price: number;
};

type PriceOption = {
  id: string;
  label: string;
  price_amount: number;
  sort_order: number;
};

export type ModalMenuItem = {
  name: string;
  description: string | null;
  price_mode: string;
  price_amount: number | null;
  image_url: string | null;
  sku: string;
  category_name: string;
  addons?: Addon[];
  price_options?: PriceOption[];
};

function formatPrice(item: ModalMenuItem): string {
  if (item.price_mode === "tbd") return "Price on request";

  if (item.price_mode === "variable") {
    const sorted = [...(item.price_options ?? [])].sort(
      (a, b) => a.sort_order - b.sort_order,
    );
    if (sorted.length === 0) return "Variable pricing";
    const lowest = sorted[0].price_amount;
    const highest = sorted[sorted.length - 1].price_amount;
    if (lowest === highest) return `₦${lowest.toLocaleString()}`;
    return `₦${lowest.toLocaleString()} – ₦${highest.toLocaleString()}`;
  }

  if (item.price_amount === null) return "–";
  return `₦${item.price_amount.toLocaleString()}`;
}

interface MenuItemModalProps {
  item: ModalMenuItem | null;
  onClose: () => void;
}

export default function MenuItemModal({ item, onClose }: MenuItemModalProps) {
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    },
    [onClose],
  );

  useEffect(() => {
    if (!item) return;
    document.addEventListener("keydown", handleKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "";
    };
  }, [item, handleKeyDown]);

  if (!item) return null;

  const sortedOptions = [...(item.price_options ?? [])].sort(
    (a, b) => a.sort_order - b.sort_order,
  );
  const addons = item.addons ?? [];

  return (
    /* Backdrop */
    <div
      role="dialog"
      aria-modal="true"
      aria-label={item.name}
      className="fixed inset-0 z-50 flex items-end justify-center sm:items-center"
      onClick={onClose}
    >
      {/* Dim overlay */}
      <div className="absolute inset-0 bg-black/75 backdrop-blur-sm" />

      {/* Panel */}
      <div
        className="relative z-10 w-full max-w-lg mx-auto sm:rounded-sm overflow-hidden
                   bg-[#0d0d0d] border border-[#d1b87a]/20
                   shadow-[0_0_60px_rgba(209,184,122,0.08)]
                   animate-modal-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* ── Hero image ── */}
        <div className="relative w-full aspect-[16/9] bg-black">
          <SmartImage
            src={item.image_url ?? "/placeholder.png"}
            alt={item.name}
            fill
            className="object-cover brightness-75"
            fallbackVariant="initials"
            label={item.name}
            wrapperClassName="w-full h-full"
          />

          {/* Category pill on top-left */}
          <span
            className="absolute top-4 left-4 px-2.5 py-1 text-[10px] uppercase tracking-[0.25em]
                       text-[#d1b87a] border border-[#d1b87a]/40 bg-black/60 backdrop-blur-sm"
          >
            {item.category_name}
          </span>

          {/* Close button */}
          <button
            type="button"
            aria-label="Close"
            onClick={onClose}
            className="absolute top-3 right-3 w-8 h-8 flex items-center justify-center
                       rounded-full bg-black/60 backdrop-blur-sm
                       text-[#d1b87a] hover:bg-[#d1b87a]/20 transition-colors"
          >
            <svg
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth={1.8}
              className="w-4 h-4"
            >
              <path d="M18 6 6 18M6 6l12 12" strokeLinecap="round" />
            </svg>
          </button>

          {/* Price badge on bottom-right of image */}
          <div
            className="absolute bottom-4 right-4 px-3 py-1.5
                       bg-black/70 backdrop-blur-sm border border-[#d1b87a]/40"
          >
            <span className="text-[#d1b87a] text-base font-light tracking-wide">
              {formatPrice(item)}
            </span>
          </div>
        </div>

        {/* ── Body ── */}
        <div className="px-6 py-5 space-y-4">
          {/* Name */}
          <h2 className="text-2xl font-light text-[#f5e3b0] tracking-wide leading-snug">
            {item.name}
          </h2>

          {/* Gold divider */}
          <div className="h-px w-12 bg-[#d1b87a]/60" />

          {/* Description */}
          {item.description && (
            <p className="text-sm leading-relaxed text-[#b09478]">
              {item.description}
            </p>
          )}

          {/* Variable price options */}
          {item.price_mode === "variable" && sortedOptions.length > 0 && (
            <div className="space-y-1.5">
              <p className="text-[10px] uppercase tracking-[0.3em] text-[#d1b87a]/60">
                Options
              </p>
              <ul className="divide-y divide-[#d1b87a]/10">
                {sortedOptions.map((opt) => (
                  <li
                    key={opt.id}
                    className="flex items-center justify-between py-2"
                  >
                    <span className="text-sm text-[#c9a96e]">{opt.label}</span>
                    <span className="text-sm text-[#d1b87a]">
                      ₦{opt.price_amount.toLocaleString()}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Add-ons */}
          {addons.length > 0 && (
            <div className="space-y-1.5">
              <p className="text-[10px] uppercase tracking-[0.3em] text-[#d1b87a]/60">
                Choice of
              </p>
              <div className="flex flex-wrap gap-2">
                {addons.map((addon) => (
                  <span
                    key={addon.id}
                    className="inline-flex items-center gap-1 px-2.5 py-1
                               border border-[#d1b87a]/25 text-xs text-[#c9a96e]"
                  >
                    {addon.name}
                    {addon.price > 0 && (
                      <span className="text-[#ac9272]">
                        +₦{addon.price.toLocaleString()}
                      </span>
                    )}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* SKU — subtle footer */}
          <p className="pt-1 text-[10px] tracking-widest text-[#ac9272]/50 uppercase">
            Ref: {item.sku}
          </p>
        </div>
      </div>
    </div>
  );
}
