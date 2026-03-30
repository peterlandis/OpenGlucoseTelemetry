import type { DedupeTracker } from "../normalization/dedupe.js";

export type SubmitOptions = {
  dedupe?: DedupeTracker;
};
