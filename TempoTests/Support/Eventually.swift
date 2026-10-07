import Foundation

/// Waits until `condition` holds, checking every 50 ms, for at most `timeout`. Returns whether it held.
/// For debounced work, whose exact timing depends on how busy the simulator is.
@MainActor
func eventually(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while clock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(50))
    }
    return condition()
}
