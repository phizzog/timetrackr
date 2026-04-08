import Foundation
import SwiftData

@Model
public final class Project {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var clientName: String
    public var colorHex: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        clientName: String = "",
        colorHex: String = "#4F46E5",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}

@Model
public final class TimeEntry {
    @Attribute(.unique) public var id: UUID
    public var projectID: UUID
    public var projectName: String
    public var startedAt: Date
    public var endedAt: Date
    public var notes: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        projectID: UUID,
        projectName: String,
        startedAt: Date,
        endedAt: Date,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectID = projectID
        self.projectName = projectName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
        self.createdAt = createdAt
    }

    public var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

public struct ActiveSession: Equatable, Sendable {
    public var projectID: UUID
    public var startedAt: Date
    public var accumulatedDuration: TimeInterval
    public var pausedAt: Date?
    public var notes: String

    public init(
        projectID: UUID,
        startedAt: Date = .now,
        accumulatedDuration: TimeInterval = 0,
        pausedAt: Date? = nil,
        notes: String = ""
    ) {
        self.projectID = projectID
        self.startedAt = startedAt
        self.accumulatedDuration = accumulatedDuration
        self.pausedAt = pausedAt
        self.notes = notes
    }

    public var isPaused: Bool {
        pausedAt != nil
    }

    public func elapsed(at now: Date) -> TimeInterval {
        if let pausedAt {
            return accumulatedDuration + pausedAt.timeIntervalSince(startedAt)
        }

        return accumulatedDuration + now.timeIntervalSince(startedAt)
    }
}

public struct EntryRecord: Equatable, Sendable {
    public let id: UUID
    public let projectID: UUID
    public let projectName: String
    public let startedAt: Date
    public let endedAt: Date
    public let notes: String

    public init(
        id: UUID = UUID(),
        projectID: UUID,
        projectName: String,
        startedAt: Date,
        endedAt: Date,
        notes: String = ""
    ) {
        self.id = id
        self.projectID = projectID
        self.projectName = projectName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
    }

    public init(entry: TimeEntry) {
        self.init(
            id: entry.id,
            projectID: entry.projectID,
            projectName: entry.projectName,
            startedAt: entry.startedAt,
            endedAt: entry.endedAt,
            notes: entry.notes
        )
    }

    public var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}
