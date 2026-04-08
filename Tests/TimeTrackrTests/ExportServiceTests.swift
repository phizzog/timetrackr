import Foundation
import Testing
@testable import TimeTrackrCore

struct ExportServiceTests {
    @Test
    func createsCSVWithEscapedFields() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = EntryRecord(
            projectID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            projectName: "Client Work",
            startedAt: start,
            endedAt: start.addingTimeInterval(3600),
            notes: "Quoted \"note\""
        )

        let csv = ExportService.csv(entries: [entry])

        #expect(csv.contains("project,start,end,duration_seconds,notes"))
        #expect(csv.contains("\"Client Work\""))
        #expect(csv.contains("\"Quoted \"\"note\"\"\""))
    }

    @Test
    func createsJSONPayload() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = EntryRecord(
            projectID: UUID(),
            projectName: "Focus",
            startedAt: start,
            endedAt: start.addingTimeInterval(900),
            notes: "Deep work"
        )

        let data = try ExportService.data(for: [entry], format: .json)
        let json = String(decoding: data, as: UTF8.self)

        #expect(json.contains("\"projectName\" : \"Focus\""))
        #expect(json.contains("\"durationSeconds\" : 900"))
    }
}
