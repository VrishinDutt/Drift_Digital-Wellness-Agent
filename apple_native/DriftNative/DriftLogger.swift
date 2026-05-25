import Foundation

enum DriftLogCategory: String, Equatable {
    case mode
    case telemetry
    case snapshot
    case intervention
    case rhythm
    case soundscape
    case ambience
    case buffer

    var displayName: String {
        switch self {
        case .mode:
            return "Mode"
        case .telemetry:
            return "Telemetry"
        case .snapshot:
            return "Snapshot"
        case .intervention:
            return "Intervention"
        case .rhythm:
            return "Rhythm"
        case .soundscape:
            return "Soundscape"
        case .ambience:
            return "Ambience"
        case .buffer:
            return "Buffer"
        }
    }
}

struct DriftLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let category: DriftLogCategory
    let message: String
}

@MainActor
final class DriftLogger {
    private let maxEntries: Int
    private(set) var entries: [DriftLogEntry] = []

    init(maxEntries: Int = 80) {
        self.maxEntries = maxEntries
    }

    /// Local prototype diagnostics only. This logger is intentionally in-memory
    /// and bounded: no disk writes, no cloud logging, no screenshots, no URLs,
    /// no keystrokes, no clipboard data, and no page text.
    func log(_ category: DriftLogCategory, _ message: String) {
        entries.append(
            DriftLogEntry(
                timestamp: Date(),
                category: category,
                message: message
            )
        )

        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }

        #if DEBUG
        print("[Drift][\(category.displayName)] \(message)")
        #endif
    }

    func recent(limit: Int) -> [DriftLogEntry] {
        Array(entries.suffix(limit).reversed())
    }
}
