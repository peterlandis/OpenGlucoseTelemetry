/**
 * Optional in-memory dedupe for MVP. Key: subject_id + observed_at + raw_event_id.
 * Idempotency: duplicate submissions return DUPLICATE_EVENT when enabled.
 */
export class DedupeTracker {
  private readonly seen: Set<string> = new Set();

  public makeKey(subjectId: string, observedAt: string, rawEventId: string): string {
    return `${subjectId}\u001f${observedAt}\u001f${rawEventId}`;
  }

  public checkAndRemember(key: string): boolean {
    if (this.seen.has(key)) {
      return false;
    }
    this.seen.add(key);
    return true;
  }

  public clear(): void {
    this.seen.clear();
  }
}
