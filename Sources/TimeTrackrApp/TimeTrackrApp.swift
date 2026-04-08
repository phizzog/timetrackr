import AppKit
import SwiftData
import SwiftUI
#if canImport(TimeTrackrCore)
import TimeTrackrCore
#endif

@main
struct TimeTrackrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var refreshTimer: Timer?
    private var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appState = AppState.bootstrap()
        self.appState = appState

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 380, height: 620)
        popover.contentViewController = NSHostingController(rootView: rootView(for: appState))

        updateStatusItem()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    @objc
    private func togglePopover() {
        guard let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button, let appState else {
            return
        }

        button.image = StatusIcon.make(isRunning: appState.isRunning)
        button.imagePosition = .imageLeading
        button.title = appState.title
    }

    private func rootView(for appState: AppState) -> some View {
        Group {
            switch appState {
            case .ready(let model):
                ContentView()
                    .environment(model)
            case .failed(let message):
                Text(message)
                    .padding()
                    .frame(width: 320)
            }
        }
    }
}

@MainActor
private enum AppState {
    case ready(AppModel)
    case failed(String)

    static func bootstrap() -> AppState {
        let schema = Schema([Project.self, TimeEntry.self])
        let hasBundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String != nil

        if !hasBundleName {
            do {
                let container = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
                let model = AppModel(container: container)
                model.errorMessage = "Running with in-memory storage because the SwiftPM launcher has no app bundle."
                return .ready(model)
            } catch {
                return .failed("TimeTrackr could not start: \(error.localizedDescription)")
            }
        }

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, url: storeURL())
            )
            return .ready(AppModel(container: container))
        } catch {
            do {
                let fallback = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
                let model = AppModel(container: fallback)
                model.errorMessage = "Using in-memory storage because persistent storage could not be opened."
                return .ready(model)
            } catch {
                return .failed("TimeTrackr could not start: \(error.localizedDescription)")
            }
        }
    }

    private static func storeURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directoryURL = baseURL.appendingPathComponent("TimeTrackr", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent("TimeTrackr.store")
    }

    var title: String {
        switch self {
        case .ready(let model):
            return model.menuBarTitle
        case .failed:
            return "TimeTrackr"
        }
    }

    var symbol: String {
        switch self {
        case .ready(let model):
            return model.menuBarSymbol
        case .failed:
            return "exclamationmark.triangle"
        }
    }

    var isRunning: Bool {
        switch self {
        case .ready(let model):
            return model.activeSession != nil
        case .failed:
            return false
        }
    }
}
