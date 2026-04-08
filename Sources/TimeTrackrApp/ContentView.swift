import SwiftUI
#if canImport(TimeTrackrCore)
import TimeTrackrCore
#endif

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                timerPanel
                projectPanel
                summaryPanel
                entriesPanel
                exportPanel
            }
            .padding(16)
        }
        .frame(width: 380, height: 620)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TimeTrackr")
                .font(.title2.weight(.semibold))
            Text("Track time without leaving the menubar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var timerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer")
                .font(.headline)

            Picker("Project", selection: projectSelection) {
                ForEach(model.projects, id: \.id) { project in
                    Text(project.clientName.isEmpty ? project.name : "\(project.name) · \(project.clientName)")
                        .tag(Optional(project.id))
                }
            }

            TextField("What are you working on?", text: notesBinding, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            if let session = model.activeSession {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.projectName(for: session.projectID))
                        .font(.headline)
                    Text(SummaryService.format(duration: session.elapsed(at: model.currentTime)))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    HStack {
                        Button(session.isPaused ? "Resume" : "Pause") {
                            model.togglePause()
                        }
                        .keyboardShortcut(.space, modifiers: [])

                        Button("Stop") {
                            model.stopTimer()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
            } else {
                Button("Start Timer") {
                    model.startTimer()
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var projectPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Projects")
                .font(.headline)

            TextField("Project name", text: projectNameBinding)
                .textFieldStyle(.roundedBorder)
            TextField("Client name", text: clientNameBinding)
                .textFieldStyle(.roundedBorder)

            Button("Add Project") {
                model.addProject()
            }

            ForEach(model.projects, id: \.id) { project in
                HStack {
                    Circle()
                        .fill(Color(hex: project.colorHex))
                        .frame(width: 10, height: 10)
                    Text(project.name)
                    Spacer()
                    if !project.clientName.isEmpty {
                        Text(project.clientName)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
    }

    private var summaryPanel: some View {
        HStack(spacing: 12) {
            summaryCard(title: "Today", value: SummaryService.format(duration: model.summary.today))
            summaryCard(title: "This Week", value: SummaryService.format(duration: model.summary.week))
        }
    }

    private var entriesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Entries")
                .font(.headline)

            if model.entries.isEmpty {
                Text("No entries yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(model.entries.prefix(6)), id: \.id) { entry in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.projectName)
                                .font(.subheadline.weight(.medium))
                            Text(entry.startedAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(SummaryService.format(duration: entry.duration))
                            Button("Delete") {
                                model.deleteEntry(entry)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var exportPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export")
                .font(.headline)

            HStack {
                Button("CSV") {
                    model.exportEntries(format: .csv)
                }
                Button("JSON") {
                    model.exportEntries(format: .json)
                }
            }

            if let exportMessage = model.exportMessage {
                Text(exportMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

    private var projectSelection: Binding<UUID?> {
        Binding(
            get: { model.selectedProjectID },
            set: { model.selectedProjectID = $0 }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { model.notesDraft },
            set: { model.notesDraft = $0 }
        )
    }

    private var projectNameBinding: Binding<String> {
        Binding(
            get: { model.projectNameDraft },
            set: { model.projectNameDraft = $0 }
        )
    }

    private var clientNameBinding: Binding<String> {
        Binding(
            get: { model.clientNameDraft },
            set: { model.clientNameDraft = $0 }
        )
    }
}

private extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard let value = Int(trimmed, radix: 16) else {
            self = .accentColor
            return
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }
}
