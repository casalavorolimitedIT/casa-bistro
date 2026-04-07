"use client";

import { useEffect, useMemo, useState } from "react";
import CasaReviewComposer from "./CasaReviewComposer";

interface CasaRestaurantReviewPromptProps {
  kitchenSlug: string;
}

const TIME_THRESHOLD_MS = 25_000;
const SCROLL_THRESHOLD = 0.6;
const COOLDOWN_MS = 24 * 60 * 60 * 1000;
const STORAGE_DISMISS_UNTIL = "casa_review_prompt_dismiss_until";

export default function CasaRestaurantReviewPrompt({
  kitchenSlug,
}: CasaRestaurantReviewPromptProps) {
  const [timeMet, setTimeMet] = useState(false);
  const [scrollMet, setScrollMet] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const [isDismissed, setIsDismissed] = useState(false);

  useEffect(() => {
    const dismissUntilRaw = localStorage.getItem(STORAGE_DISMISS_UNTIL);
    const dismissUntil = dismissUntilRaw ? Number(dismissUntilRaw) : 0;

    if (dismissUntil > Date.now()) {
      setIsDismissed(true);
      return;
    }

    const timer = window.setTimeout(() => setTimeMet(true), TIME_THRESHOLD_MS);

    const onScroll = () => {
      const scrollTop = window.scrollY;
      const scrollable = document.body.scrollHeight - window.innerHeight;
      if (scrollable <= 0) return;

      if (scrollTop / scrollable >= SCROLL_THRESHOLD) {
        setScrollMet(true);
      }
    };

    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("scroll", onScroll);
    };
  }, []);

  useEffect(() => {
    if (!isDismissed && timeMet && scrollMet) {
      setIsOpen(true);
    }
  }, [isDismissed, timeMet, scrollMet]);

  const shouldRender = useMemo(
    () => !isDismissed && isOpen,
    [isDismissed, isOpen],
  );

  function dismissPrompt() {
    setIsOpen(false);
    setIsDismissed(true);
    localStorage.setItem(
      STORAGE_DISMISS_UNTIL,
      String(Date.now() + COOLDOWN_MS),
    );
  }

  if (!shouldRender) {
    return null;
  }

  return (
    <div className="fixed inset-x-0 bottom-3 z-40 px-3 sm:bottom-4 sm:px-6">
      <div className="mx-auto w-full max-w-xl rounded-lg border border-orange-300/30 bg-[#111]/95 p-4 shadow-[0_14px_38px_rgba(0,0,0,0.45)] backdrop-blur-sm">
        <div className="mb-3 flex items-start justify-between gap-3">
          <div>
            <p className="text-[10px] uppercase tracking-[0.28em] text-orange-200/80">
              Your feedback helps
            </p>
            <h3 className="mt-1 text-sm font-medium text-orange-50">
              How was your Casa-Bistro experience?
            </h3>
          </div>
          <button
            type="button"
            onClick={dismissPrompt}
            className="text-xs uppercase tracking-[0.2em] text-orange-200/80 hover:text-orange-100"
          >
            Dismiss
          </button>
        </div>

        <CasaReviewComposer
          kitchenSlug={kitchenSlug}
          defaultTarget="restaurant"
          triggerSource="restaurant_smart_prompt"
          onSubmitted={dismissPrompt}
        />
      </div>
    </div>
  );
}
