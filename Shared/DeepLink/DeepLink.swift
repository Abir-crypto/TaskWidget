import Core
import Foundation

/// A place the app can open directly, used by widgets and notifications (SPEC F-09, ios.md §11).
///
/// | URL | Opens |
/// |---|---|
/// | `tempo://today[?day=yyyymmdd][&part=noon][&task=<uuid>]` | Today, optionally at a day, part or task |
/// | `tempo://new[?day=yyyymmdd][&type=one_time\|progress\|duration]` | The editor, with presets |
/// | `tempo://missed` | The Missed tab |
/// | `tempo://timer` | The timer screen |
///
/// The task picker for a finished generic timer is opened by the pending open action, not by a URL.
enum DeepLink: Hashable {
    case today(day: DayKey? = nil, part: DayPart? = nil, taskID: UUID? = nil)
    case newTask(day: DayKey? = nil, type: TaskType? = nil)
    case missed
    case timer

    static let scheme = "tempo"

    /// Parses a URL. Unknown or malformed URLs open Today; unknown or malformed parameters are ignored.
    init(url: URL) {
        guard url.scheme?.lowercased() == DeepLink.scheme,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            self = .today()
            return
        }
        let items = components.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        let day = value("day").flatMap(Int.init).map(DayKey.init(rawValue:))
        // The host is the destination: tempo://today, tempo://new, …
        switch (components.host ?? "").lowercased() {
        case "new":
            self = .newTask(day: day, type: value("type").flatMap(TaskType.init(rawValue:)))
        case "missed":
            self = .missed
        case "timer":
            self = .timer
        default:
            self = .today(
                day: day, part: value("part").flatMap(DayPart.init(rawValue:)),
                taskID: value("task").flatMap(UUID.init(uuidString:)))
        }
    }

    /// The URL for this destination.
    var url: URL {
        var components = URLComponents()
        components.scheme = DeepLink.scheme
        var items: [URLQueryItem] = []
        switch self {
        case .today(let day, let part, let taskID):
            components.host = "today"
            if let day { items.append(URLQueryItem(name: "day", value: String(day.rawValue))) }
            if let part { items.append(URLQueryItem(name: "part", value: part.rawValue)) }
            if let taskID { items.append(URLQueryItem(name: "task", value: taskID.uuidString.lowercased())) }
        case .newTask(let day, let type):
            components.host = "new"
            if let day { items.append(URLQueryItem(name: "day", value: String(day.rawValue))) }
            if let type { items.append(URLQueryItem(name: "type", value: type.rawValue)) }
        case .missed:
            components.host = "missed"
        case .timer:
            components.host = "timer"
        }
        components.queryItems = items.isEmpty ? nil : items
        return components.url ?? URL(filePath: "/")
    }
}
