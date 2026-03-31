import Foundation

// MARK: - RFC3339 / ISO8601 timestamp codec (single boundary)

/// Centralized timestamp parsing + normalization for OGT Swift runtime.
///
/// **Policy (parity with TypeScript `normalizeTimestamp`):**
/// - Accept RFC3339 / ISO8601 with or without fractional seconds
/// - Interpret and emit in **UTC**
/// - Normalize output to **milliseconds precision** (sub-ms dropped)
public enum OGTRFC3339: Sendable {
    private static let utc: TimeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

    private static let fractional: ISO8601DateFormatter = {
        let f: ISO8601DateFormatter = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = utc
        return f
    }()

    private static let plain: ISO8601DateFormatter = {
        let f: ISO8601DateFormatter = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = utc
        return f
    }()

    /// Parses an RFC3339/ISO8601 timestamp into a `Date`.
    public static func decode(_ string: String) -> Date? {
        let trimmed: String = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let d: Date = fractional.date(from: trimmed) {
            return d
        }
        return plain.date(from: trimmed)
    }

    /// Encodes a `Date` to RFC3339 in UTC with fractional seconds.
    ///
    /// Note: This does **not** clamp to milliseconds; call `encodeMillisUTC(_:)` when you need parity normalization.
    public static func encode(_ date: Date) -> String {
        fractional.string(from: date)
    }

    /// Returns milliseconds since epoch for an RFC3339/ISO8601 timestamp.
    public static func epochMs(_ string: String) -> Int64? {
        guard let d: Date = decode(string) else {
            return nil
        }
        return Int64(d.timeIntervalSince1970 * 1000.0)
    }

    /// Normalizes an input RFC3339/ISO8601 string to a UTC RFC3339 string with **milliseconds precision**.
    public static func normalizeToMillisUTC(_ string: String) throws -> String {
        let trimmed: String = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let d: Date = decode(trimmed) else {
            throw OGTNormalizerError.invalidDateTime(string)
        }
        return encodeMillisUTC(d)
    }

    /// Encodes a `Date` to UTC RFC3339 string rounded down to milliseconds.
    public static func encodeMillisUTC(_ date: Date) -> String {
        let ms: Int64 = Int64((date.timeIntervalSince1970 * 1000.0).rounded(.down))
        let rounded: Date = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        return fractional.string(from: rounded)
    }
}

