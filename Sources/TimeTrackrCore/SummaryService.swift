import Foundation

public struct SummarySnapshot: Equatable, Sendable {
    public let today: TimeInterval
    public let week: TimeInterval
    public let totalEntries: Int

    public init(today: TimeInterval, week: TimeInterval, totalEntries: Int) {
        self.today = today
        self.week = week
        self.totalEntries = totalEntries
    }
}

public enum SummaryService {
    public static func makeSnapshot(
        entries: [EntryRecord],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> SummarySnapshot {
        let today = entries
            .filter { calendar.isDate($0.startedAt, inSameDayAs: now) }
            .reduce(0) { $0 + $1.duration }

        let week = entries
            .filter { calendar.isDate($0.startedAt, equalTo: now, toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.duration }

        return SummarySnapshot(today: today, week: week, totalEntries: entries.count)
    }

    public static func format(duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded()), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02dh %02dm", hours, minutes)
        }

        return String(format: "%02dm %02ds", minutes, seconds)
    }
}
