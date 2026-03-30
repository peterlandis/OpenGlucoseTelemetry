import Foundation

// MARK: - Semantic rules (parity with semantic.ts)

/// Clock skew window for future `observed_at` (OGT policy).
public let OGT_FUTURE_SKEW_MS: Int64 = 15 * 60 * 1000

private let mgdlMin: Double = 20
private let mgdlMax: Double = 600

public func ogtApplySemanticRules(
    reading: OGTCanonicalGlucoseReadingV01,
    traceId: String
) -> OGTStructuredPipelineError? {
    let nowMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000.0)
    let observedMs: Int64? = ogtParseEpochMs(reading.observedAt)
    guard let observed: Int64 = observedMs else {
        return OGTStructuredPipelineError(
            code: .semanticInvalid,
            message: "observed_at is not parseable",
            traceId: traceId,
            field: "observed_at"
        )
    }
    if observed > nowMs + OGT_FUTURE_SKEW_MS {
        return OGTStructuredPipelineError(
            code: .semanticInvalid,
            message: "observed_at is too far in the future (> 15 minutes)",
            traceId: traceId,
            field: "observed_at"
        )
    }
    if reading.unit != "mg/dL" {
        return OGTStructuredPipelineError(
            code: .semanticInvalid,
            message: "Expected normalized unit mg/dL before semantic glucose range check",
            traceId: traceId,
            field: "unit"
        )
    }
    if reading.value < mgdlMin || reading.value > mgdlMax {
        return OGTStructuredPipelineError(
            code: .semanticInvalid,
            message: "Glucose value out of plausible range for mg/dL (20–600)",
            traceId: traceId,
            field: "value"
        )
    }
    if let sr: String = reading.sourceRecordedAt {
        let srMs: Int64? = ogtParseEpochMs(sr)
        guard let srm: Int64 = srMs else {
            return OGTStructuredPipelineError(
                code: .semanticInvalid,
                message: "source_recorded_at is not parseable",
                traceId: traceId,
                field: "source_recorded_at"
            )
        }
        if srm > nowMs + OGT_FUTURE_SKEW_MS {
            return OGTStructuredPipelineError(
                code: .semanticInvalid,
                message: "source_recorded_at is too far in the future (> 15 minutes)",
                traceId: traceId,
                field: "source_recorded_at"
            )
        }
    }
    return nil
}

private func ogtParseEpochMs(_ iso: String) -> Int64? {
    let f1: ISO8601DateFormatter = ISO8601DateFormatter()
    f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f1.timeZone = TimeZone(secondsFromGMT: 0)
    if let d: Date = f1.date(from: iso) {
        return Int64(d.timeIntervalSince1970 * 1000.0)
    }
    let f2: ISO8601DateFormatter = ISO8601DateFormatter()
    f2.formatOptions = [.withInternetDateTime]
    f2.timeZone = TimeZone(secondsFromGMT: 0)
    guard let d2: Date = f2.date(from: iso) else {
        return nil
    }
    return Int64(d2.timeIntervalSince1970 * 1000.0)
}
