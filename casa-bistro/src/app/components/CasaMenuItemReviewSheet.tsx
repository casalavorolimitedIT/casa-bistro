"use client";

import { useCallback, useEffect, useState } from "react";
import CasaReviewComposer from "./CasaReviewComposer";

interface CasaMenuItemReviewSheetProps {
  item: {
    sku: string;
    name: string;
    price: number;
    description?: string;
    categoryName: string;
  } | null;
  kitchenSlug: string;
  onClose: () => void;
}

export default function CasaMenuItemReviewSheet({
  item,
  kitchenSlug,
  onClose,
}: CasaMenuItemReviewSheetProps) {
  const [approvedReviews, setApprovedReviews] = useState<
    Array<{
      id: string;
      rating: number;
      feedback: string;
      reviewer_name?: string | null;
      created_at: string;
    }>
  >([]);
  const [isLoadingApprovedReviews, setIsLoadingApprovedReviews] = useState(false);

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

  useEffect(() => {
    if (!item) return;
    const activeItem = item;

    let cancelled = false;
    setIsLoadingApprovedReviews(true);

    async function loadApprovedReviews() {
      try {
        const response = await fetch(
          `/api/landing/casa/reviews?target=item&kitchenSlug=${kitchenSlug}&itemSku=${encodeURIComponent(activeItem.sku)}`,
          {
            method: "GET",
            cache: "no-store",
          },
        );

        if (!response.ok) {
          if (!cancelled) {
            setApprovedReviews([]);
          }
          return;
        }

        const payload = (await response.json()) as {
          reviews?: Array<{
            id: string;
            rating: number;
            feedback: string;
            reviewer_name?: string | null;
            created_at: string;
          }>;
        };

        if (!cancelled) {
          setApprovedReviews(payload.reviews ?? []);
        }
      } finally {
        if (!cancelled) {
          setIsLoadingApprovedReviews(false);
        }
      }
    }

    void loadApprovedReviews();

    return () => {
      cancelled = true;
    };
  }, [item, kitchenSlug]);

  if (!item) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={item.name}
      className="fixed inset-0 z-50 flex items-end justify-center sm:items-center"
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/75 backdrop-blur-sm" />

      <div
        className="relative z-10 mx-auto w-full max-w-lg overflow-hidden rounded-t-xl border border-orange-300/30 bg-[#151515] shadow-[0_0_60px_rgba(249,115,22,0.2)] animate-modal-up sm:rounded-xl"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="bg-gradient-to-r from-orange-600/25 to-orange-400/10 px-5 py-4">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-[10px] uppercase tracking-[0.3em] text-orange-200/80">
                {item.categoryName}
              </p>
              <h2 className="mt-1 text-2xl font-semibold text-orange-50">{item.name}</h2>
              <p className="mt-1 text-sm text-orange-200">₦{item.price.toLocaleString()}</p>
            </div>

            <button
              type="button"
              aria-label="Close"
              onClick={onClose}
              className="rounded-full bg-black/40 px-2 py-1 text-orange-100 hover:bg-orange-500/30"
            >
              ✕
            </button>
          </div>
        </div>

        <div className="space-y-4 px-5 py-5">
          {item.description && (
            <p className="text-sm leading-relaxed text-orange-100/90">{item.description}</p>
          )}

          <div className="space-y-2 border-t border-orange-300/20 pt-4">
            <p className="text-[10px] uppercase tracking-[0.3em] text-orange-200/80">
              Approved Reviews
            </p>

            {isLoadingApprovedReviews && (
              <p className="text-xs text-orange-100/80">Loading recent reviews...</p>
            )}

            {!isLoadingApprovedReviews && approvedReviews.length === 0 && (
              <p className="text-xs text-orange-100/80">
                No approved reviews yet. Be the first to share feedback.
              </p>
            )}

            {!isLoadingApprovedReviews && approvedReviews.length > 0 && (
              <ul className="space-y-2">
                {approvedReviews.slice(0, 3).map((review) => (
                  <li
                    key={review.id}
                    className="rounded-md border border-orange-300/25 bg-black/35 p-2.5"
                  >
                    <p className="text-xs text-orange-300">★ {review.rating.toFixed(1)}</p>
                    <p className="mt-1 text-xs leading-relaxed text-orange-100/90">
                      {review.feedback}
                    </p>
                    <p className="mt-1 text-[10px] uppercase tracking-[0.2em] text-orange-200/70">
                      {review.reviewer_name ?? "Anonymous"}
                    </p>
                  </li>
                ))}
              </ul>
            )}

            <p className="pt-1 text-[10px] uppercase tracking-[0.3em] text-orange-200/80">
              Leave your review
            </p>
            <CasaReviewComposer
              kitchenSlug={kitchenSlug}
              itemSku={item.sku}
              itemName={item.name}
              defaultTarget="item"
              allowTargetSwitch
              triggerSource="item_modal"
            />
          </div>

          <p className="text-[10px] uppercase tracking-[0.24em] text-orange-200/60">
            Ref: {item.sku}
          </p>
        </div>
      </div>
    </div>
  );
}
