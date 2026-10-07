import Core

/// One row to insert or update in a batch (`TaskStore.write`). A soft delete is a write with `deletedAt` set.
enum StoreWrite: Hashable {
    case task(TaskValue)
    case schedule(ScheduleValue)
    case completion(CompletionValue)
    case timeEntry(TimeEntryValue)
}
