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

    /// Gregorian calendar in UTC for ASCII fast-path parsing (avoids ICU for `encodeMillisUTC` output shapes).
    private static let utcCalendar: Calendar = {
        var cal: Calendar = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        return cal
    }()

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

    // MARK: - ASCII fast path (bulk insight validation; `encodeMillisUTC` / trusted normalizer output)

    private static func asciiDigit(_ c: UInt8) -> Int? {
        guard c >= 48, c <= 57 else { return nil }
        return Int(c - 48)
    }

    private static func asciiInt2(_ b: [UInt8], _ i: Int) -> Int? {
        guard let a: Int = asciiDigit(b[i]), let c: Int = asciiDigit(b[i + 1]) else { return nil }
        return a * 10 + c
    }

    private static func asciiInt3(_ b: [UInt8], _ i: Int) -> Int? {
        guard let x: Int = asciiDigit(b[i]), let y: Int = asciiDigit(b[i + 1]), let z: Int = asciiDigit(b[i + 2]) else {
            return nil
        }
        return x * 100 + y * 10 + z
    }

    private static func asciiInt4(_ b: [UInt8], _ i: Int) -> Int? {
        guard let a: Int = asciiDigit(b[i]), let c: Int = asciiDigit(b[i + 1]),
              let d: Int = asciiDigit(b[i + 2]), let e: Int = asciiDigit(b[i + 3])
        else {
            return nil
        }
        return a * 1000 + c * 100 + d * 10 + e
    }

    /// `YYYY-MM-DDTHH:MM:SS.sssZ` (24 ASCII chars) — matches `encodeMillisUTC` output.
    private static func dateFromMillisUTCZulu24(_ b: [UInt8]) -> Date? {
        guard b.count == 24 else { return nil }
        guard b[4] == 45, b[7] == 45, b[10] == 84, b[13] == 58, b[16] == 58, b[19] == 46, b[23] == 90 else {
            return nil
        }
        guard let year: Int = asciiInt4(b, 0), let month: Int = asciiInt2(b, 5), let day: Int = asciiInt2(b, 8),
              let hour: Int = asciiInt2(b, 11), let minute: Int = asciiInt2(b, 14), let second: Int = asciiInt2(b, 17),
              let millis: Int = asciiInt3(b, 20)
        else {
            return nil
        }
        guard month >= 1, month <= 12, day >= 1, day <= 31, hour <= 23, minute <= 59, second <= 59, millis <= 999 else {
            return nil
        }
        guard year >= 1970, year <= 2100 else { return nil }

        var components: DateComponents = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.nanosecond = millis * 1_000_000
        return utcCalendar.date(from: components)
    }

    /// `YYYY-MM-DDTHH:MM:SSZ` (20 ASCII chars), no fractional seconds.
    private static func dateFromSecondUTCZulu20(_ b: [UInt8]) -> Date? {
        guard b.count == 20 else { return nil }
        guard b[4] == 45, b[7] == 45, b[10] == 84, b[13] == 58, b[16] == 58, b[19] == 90 else { return nil }
        guard let year: Int = asciiInt4(b, 0), let month: Int = asciiInt2(b, 5), let day: Int = asciiInt2(b, 8),
              let hour: Int = asciiInt2(b, 11), let minute: Int = asciiInt2(b, 14), let second: Int = asciiInt2(b, 17)
        else {
            return nil
        }
        guard month >= 1, month <= 12, day >= 1, day <= 31, hour <= 23, minute <= 59, second <= 59 else { return nil }
        guard year >= 1970, year <= 2100 else { return nil }

        var components: DateComponents = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return utcCalendar.date(from: components)
    }

    private static func dateFromTrimmedASCIIIfZuluUTC(_ trimmed: String) -> Date? {
        let b: [UInt8] = Array(trimmed.utf8)
        if let d: Date = dateFromMillisUTCZulu24(b) {
            return d
        }
        return dateFromSecondUTCZulu20(b)
    }

    /// Parses an RFC3339/ISO8601 timestamp into a `Date`.
    public static func decode(_ string: String) -> Date? {
        let trimmed: String = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let fast: Date = dateFromTrimmedASCIIIfZuluUTC(trimmed) {
            return fast
        }
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

