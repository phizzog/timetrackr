import Foundation
import Testing
@testable import TimeTrackrCore

struct SummaryServiceTests {
    @Test
    func computesTodayAndWeekTotals() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8, hour: 12))!
        let todayStart = calendar.date(byAdding: .hour, value: -2, to: now)!
        let weekStart = calendar.date(byAdding: .day, value: -2, to: now)!
        let older = calendar.date(byAdding: .day, value: -10, to: now)!

        let entries = [
            EntryRecord(projectID: UUID(), projectName: "Alpha", startedAt: todayStart, endedAt: now),
            EntryRecord(projectID: UUID(), projectName: "Beta", startedAt: weekStart, endedAt: weekStart.addingTimeInterval(1800)),
            EntryRecord(projectID: UUID(), projectName: "Gamma", startedAt: older, endedAt: older.addingTimeInterval(7200))
        ]

        let snapshot = SummaryService.makeSnapshot(entries: entries, now: now, calendar: calendar)

        #expect(snapshot.today == 7200)
        #expect(snapshot.week == 9000)
        #expect(snapshot.totalEntries == 3)
    }

    @Test
    func formatsDurationsForMenuBarDisplay() {
        #expect(SummaryService.format(duration: 3905) == "01h 05m")
        #expect(SummaryService.format(duration: 125) == "02m 05s")
    }
}
