import Foundation

/// Failures from the store and the device-only state.
enum StorageError: Error, Equatable {
    /// The App Group container isn't available, so the shared store can't be opened.
    case appGroupUnavailable
    /// A write would break a rule of the data model, for example a time entry with no seconds.
    case invalidValue(String)
}
