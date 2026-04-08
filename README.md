# TimeTrackr

TimeTrackr is a lightweight macOS menu bar app for tracking focused work sessions without keeping a full window open all day.

## Features

- Start, pause, resume, and stop a timer from the menu bar
- Organize work by project and optional client name
- View today and week summaries at a glance
- Review and delete saved entries
- Export time entries as CSV or JSON
- Stores data locally with SwiftData

## Requirements

- macOS 14 or newer
- Xcode 16 or newer, or a Swift 6 toolchain

## Development

Build:

```bash
swift build
```

Run tests:

```bash
swift test
```

Open in Xcode:

```bash
open TimeTrackr.xcodeproj
```

## Project Structure

- `Sources/TimeTrackrApp`: SwiftUI menu bar app
- `Sources/TimeTrackrCore`: shared models, summaries, and export logic
- `Tests/TimeTrackrTests`: package tests

## License

MIT
