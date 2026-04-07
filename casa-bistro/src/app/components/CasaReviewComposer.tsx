"use client";

import { useState } from "react";

type ReviewTarget = "item" | "restaurant";

interface CasaReviewComposerProps {
  kitchenSlug: string;
  itemSku?: string;
  itemName?: string;
  defaultTarget?: ReviewTarget;
  allowTargetSwitch?: boolean;
  triggerSource: string;
  onSubmitted?: () => void;
}

const FEEDBACK_MIN = 10;
const FEEDBACK_MAX = 600;

export default function CasaReviewComposer({
  kitchenSlug,
  itemSku,
  itemName,
  defaultTarget = "item",
  allowTargetSwitch = false,
  triggerSource,
  onSubmitted,
}: CasaReviewComposerProps) {
  const [targetType, setTargetType] = useState<ReviewTarget>(defaultTarget);
  const [rating, setRating] = useState(0);
  const [feedback, setFeedback] = useState("");
  const [reviewerName, setReviewerName] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  const canSubmit =
    rating >= 1 &&
    feedback.trim().length >= FEEDBACK_MIN &&
    feedback.trim().length <= FEEDBACK_MAX &&
    !isSubmitting;

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setIsSuccess(false);

    if (!canSubmit) {
      setError("Please add a star rating and at least 10 characters of feedback.");
      return;
    }

    if (targetType === "item" && !itemSku) {
      setError("Item review is currently unavailable for this menu item.");
      return;
    }

    setIsSubmitting(true);

    try {
      const response = await fetch("/api/landing/casa/reviews", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          targetType,
          kitchenSlug,
          itemSku,
          itemName,
          rating,
          feedback: feedback.trim(),
          reviewerName: reviewerName.trim() || null,
          triggerSource,
        }),
      });

      const result = (await response.json()) as { error?: string };

      if (!response.ok) {
        throw new Error(result.error ?? "Could not submit your review.");
      }

      setIsSuccess(true);
      setRating(0);
      setFeedback("");
      setReviewerName("");
      onSubmitted?.();
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Could not submit your review.",
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      {allowTargetSwitch && (
        <div className="inline-flex rounded-md border border-orange-300/40 p-1 text-xs">
          <button
            type="button"
            onClick={() => setTargetType("item")}
            className={`px-2 py-1 transition-colors ${
              targetType === "item"
                ? "bg-orange-500/20 text-orange-100"
                : "text-orange-200 hover:text-orange-100"
            }`}
          >
            This dish
          </button>
          <button
            type="button"
            onClick={() => setTargetType("restaurant")}
            className={`px-2 py-1 transition-colors ${
              targetType === "restaurant"
                ? "bg-orange-500/20 text-orange-100"
                : "text-orange-200 hover:text-orange-100"
            }`}
          >
            Restaurant
          </button>
        </div>
      )}

      <div className="space-y-1">
        <p className="text-xs text-orange-100">
          {targetType === "item"
            ? "Did this dish hit the spot?"
            : "How was your overall experience?"}
        </p>
        <div className="flex items-center gap-1">
          {[1, 2, 3, 4, 5].map((value) => (
            <button
              key={value}
              type="button"
              aria-label={`Rate ${value} star${value > 1 ? "s" : ""}`}
              onClick={() => setRating(value)}
              className="text-xl leading-none"
            >
              <span className={value <= rating ? "text-orange-300" : "text-orange-900"}>
                ★
              </span>
            </button>
          ))}
        </div>
      </div>

      <input
        value={reviewerName}
        onChange={(event) => setReviewerName(event.target.value)}
        placeholder="Your name (optional)"
        maxLength={80}
        className="w-full rounded-md border border-orange-300/40 bg-black/40 px-3 py-2 text-sm text-orange-50 placeholder:text-orange-200/70 focus:border-orange-300/70 focus:outline-none"
      />

      <textarea
        value={feedback}
        onChange={(event) => setFeedback(event.target.value)}
        rows={3}
        maxLength={FEEDBACK_MAX}
        placeholder="Rate it in 10 seconds"
        className="w-full resize-none rounded-md border border-orange-300/40 bg-black/40 px-3 py-2 text-sm text-orange-50 placeholder:text-orange-200/70 focus:border-orange-300/70 focus:outline-none"
      />

      <div className="flex items-center justify-between">
        <p className="text-[10px] uppercase tracking-[0.2em] text-orange-200/80">
          {feedback.trim().length}/{FEEDBACK_MAX}
        </p>
        <button
          type="submit"
          disabled={!canSubmit}
          className="rounded-md border border-orange-300/50 px-3 py-1.5 text-xs uppercase tracking-[0.2em] text-orange-100 transition hover:bg-orange-500/20 disabled:cursor-not-allowed disabled:opacity-45"
        >
          {isSubmitting ? "Sending..." : "Submit review"}
        </button>
      </div>

      {error && <p className="text-xs text-red-200">{error}</p>}
      {isSuccess && (
        <p className="text-xs text-emerald-200">
          Thanks, your review was submitted for moderation.
        </p>
      )}
    </form>
  );
}
