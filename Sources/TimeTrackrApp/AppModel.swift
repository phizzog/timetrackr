import AppKit
import Foundation
import Observation
import SwiftData
import UniformTypeIdentifiers
#if canImport(TimeTrackrCore)
import TimeTrackrCore
#endif

@MainActor
@Observable
final class AppModel {
    private let container: ModelContainer
    private let context: ModelContext
    private var tickerTask: Task<Void, Never>?

    var projects: [Project] = []
    var entries: [TimeEntry] = []
    var selectedProjectID: UUID?
    var activeSession: ActiveSession?
    var currentTime: Date = .now
    var projectNameDraft = ""
    var clientNameDraft = ""
    var notesDraft = ""
    var errorMessage: String?
    var exportMessage: String?

    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
        reload()
        seedIfNeeded()
        startTicker()
    }

    var menuBarTitle: String {
        guard let session = activeSession else {
            return "TimeTrackr"
        }

        return SummaryService.format(duration: session.elapsed(at: currentTime))
    }

    var menuBarSymbol: String {
        activeSession == nil ? "timer" : "stopwatch.fill"
    }

    var selectedProject: Project? {
        guard let selectedProjectID else {
            return projects.first
        }

        return projects.first { $0.id == selectedProjectID }
    }

    func projectName(for id: UUID) -> String {
        project(for: id)?.name ?? "Unknown Project"
    }

    var summary: SummarySnapshot {
        SummaryService.makeSnapshot(entries: entryRecords, now: currentTime)
    }

    func addProject() {
        let name = projectNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let clientName = clientNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            errorMessage = "Project name is required."
            return
        }

        context.insert(Project(name: name, clientName: clientName, colorHex: color(for: projects.count)))
        saveAndReload()
        projectNameDraft = ""
        clientNameDraft = ""
        errorMessage = nil
    }

    func startTimer() {
        guard let project = selectedProject else {
            errorMessage = "Create a project before starting a timer."
            return
        }

        activeSession = ActiveSession(projectID: project.id, startedAt: currentTime, notes: notesDraft)
        errorMessage = nil
        exportMessage = nil
    }

    func togglePause() {
        guard var session = activeSession else {
            return
        }

        if let pausedAt = session.pausedAt {
            session.accumulatedDuration += pausedAt.timeIntervalSince(session.startedAt)
            session.startedAt = currentTime
            session.pausedAt = nil
        } else {
            session.pausedAt = currentTime
        }

        activeSession = session
    }

    func stopTimer() {
        guard let session = activeSession, let project = project(for: session.projectID) else {
            activeSession = nil
            return
        }

        let endedAt = session.pausedAt ?? currentTime
        let totalDuration = session.elapsed(at: currentTime)
        let adjustedStart = endedAt.addingTimeInterval(-totalDuration)

        context.insert(
            TimeEntry(
                projectID: project.id,
                projectName: project.name,
                startedAt: adjustedStart,
                endedAt: endedAt,
                notes: session.notes
            )
        )

        activeSession = nil
        notesDraft = ""
        saveAndReload()
    }

    func exportEntries(format: ExportFormat) {
        do {
            let data = try ExportService.data(for: entryRecords, format: format)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [contentType(for: format)]
            panel.nameFieldStringValue = defaultExportFileName(for: format)
            panel.canCreateDirectories = true

            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                exportMessage = "Exported \(entries.count) entries to \(url.lastPathComponent)."
            }
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func deleteEntry(_ entry: TimeEntry) {
        context.delete(entry)
        saveAndReload()
    }

    private func reload() {
        do {
            projects = try context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)]))
            entries = try context.fetch(FetchDescriptor<TimeEntry>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))
            selectedProjectID = selectedProjectID ?? projects.first?.id
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    private func saveAndReload() {
        do {
            try context.save()
            reload()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }

    private func project(for id: UUID) -> Project? {
        projects.first { $0.id == id }
    }

    private var entryRecords: [EntryRecord] {
        entries.map(EntryRecord.init)
    }

    private func seedIfNeeded() {
        guard projects.isEmpty else {
            return
        }

        context.insert(Project(name: "General", clientName: "Internal", colorHex: "#2563EB"))
        saveAndReload()
    }

    private func startTicker() {
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.currentTime = .now
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func color(for index: Int) -> String {
        let palette = ["#2563EB", "#059669", "#D97706", "#DC2626", "#7C3AED"]
        return palette[index % palette.count]
    }

    private func contentType(for format: ExportFormat) -> UTType {
        switch format {
        case .csv:
            return .commaSeparatedText
        case .json:
            return .json
        }
    }

    private func defaultExportFileName(for format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "timetrackr-\(formatter.string(from: currentTime)).\(format.fileExtension)"
    }
}
