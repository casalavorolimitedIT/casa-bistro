"use client";

import { useEffect, useState } from "react";

const ScrollTop = () => {
  const [showScrollTop, setShowScrollTop] = useState(false);

  useEffect(() => {
    const onScroll = () => setShowScrollTop(window.scrollY > 320);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const scrollToTop = () => window.scrollTo({ top: 0, behavior: "smooth" });
  return (
    <>
      {/* ── Scroll-to-top button ── */}
      <button
        type="button"
        aria-label="Back to top"
        onClick={scrollToTop}
        className={[
          "fixed bottom-8 right-6 z-50 flex h-12 w-12 items-center justify-center",
          "rounded-full border border-[#d1b87a]/60 bg-black/80 backdrop-blur-sm",
          "text-[#d1b87a] shadow-[0_0_18px_2px_rgba(209,184,122,0.18)]",
          "transition-all duration-500 ease-in-out",
          "hover:border-[#d1b87a] hover:shadow-[0_0_28px_6px_rgba(209,184,122,0.35)] hover:scale-110",
          "active:scale-95",
          showScrollTop
            ? "opacity-100 translate-y-0 pointer-events-auto"
            : "opacity-0 translate-y-6 pointer-events-none",
        ].join(" ")}
      >
        {/* Animated arrow */}
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth={1.6}
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-5 w-5 transition-transform duration-300 group-hover:-translate-y-0.5"
        >
          <path d="M12 19V5" />
          <path d="M5 12l7-7 7 7" />
        </svg>

        {/* Subtle rotating ring */}
        <span
          className={[
            "absolute inset-0 rounded-full border border-[#d1b87a]/20",
            "transition-all duration-700",
            showScrollTop
              ? "scale-100 opacity-100 cenare-spin"
              : "scale-75 opacity-0",
          ].join(" ")}
        />
      </button>
    </>
  );
};

export default ScrollTop;
