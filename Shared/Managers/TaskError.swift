import Core

/// Why a task operation was refused.
enum TaskError: Error, Equatable {
    /// The input breaks a rule (SPEC F-15, §7).
    case invalid(TaskRuleError)
    /// The task doesn't exist or was deleted.
    case notFound
    /// The operation doesn't apply to this type of task.
    case wrongType
    /// SPEC F-03 or F-04 doesn't allow this change now.
    case notAllowed
}
