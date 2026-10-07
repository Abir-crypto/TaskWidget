/// Something a widget button asked the app to do when it opens (SPEC §4.6). Kept on the device only.
public enum PendingOpenAction: Hashable, Codable, Sendable {
    /// Show the task picker for a generic timer finished in the Timer widget.
    case chooseTaskForTimer(FinishedTimer)
}
