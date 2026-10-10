import Foundation

/// How the guide opens (SPEC F-23): all seven pages on first launch, or pages 1–5 from Settings › How to use.
enum GuideMode: String, Identifiable {
    case firstLaunch
    case howToUse

    var id: String { rawValue }
}
