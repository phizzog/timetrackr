import Foundation

public enum ExportFormat: String, CaseIterable, Sendable {
    case csv
    case json

    public var fileExtension: String {
        rawValue
    }
}

public enum ExportService {
    public static func data(for entries: [EntryRecord], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            return Data(csv(entries: entries).utf8)
        case .json:
            let payload = entries.map(ExportEntry.init)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(payload)
        }
    }

    public static func csv(entries: [EntryRecord]) -> String {
        let header = "project,start,end,duration_seconds,notes"
        let rows = entries.map { entry in
            [
                escaped(entry.projectName),
                iso(entry.startedAt),
                iso(entry.endedAt),
                String(Int(entry.duration.rounded())),
                escaped(entry.notes)
            ].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private static func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func escaped(_ value: String) -> String {
        let cleaned = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(cleaned)\""
    }
}

private struct ExportEntry: Codable {
    let id: UUID
    let projectID: UUID
    let projectName: String
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int
    let notes: String

    init(entry: EntryRecord) {
        id = entry.id
        projectID = entry.projectID
        projectName = entry.projectName
        startedAt = entry.startedAt
        endedAt = entry.endedAt
        durationSeconds = Int(entry.duration.rounded())
        notes = entry.notes
    }
}
