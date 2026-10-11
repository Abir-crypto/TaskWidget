import Foundation
import SwiftData

/// Opens the SwiftData store in the App Group, shared by the app and the widget extension (ios.md §6).
enum StoreFactory {
    static let appGroup = "group.akumatech.tempo"
    static let fileName = "Tempo.store"

    /// The process's one container. Each read or write makes its own fresh `ModelContext` from it.
    static let shared: Result<ModelContainer, any Error> = Result { try make(inMemory: false) }

    /// Where the shared store lives, inside the App Group container.
    static func storeURL(fileName: String = fileName) throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw StorageError.appGroupUnavailable
        }
        return container.appending(path: fileName)
    }

    static func make(inMemory: Bool) throws -> ModelContainer {
        if inMemory {
            let schema = Schema(versionedSchema: SchemaV3.self)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
        }
        return try make(url: storeURL())
    }

    /// Opens a store file at `url`. Two containers on the same file behave like the app and the extension.
    static func make(url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: config)
    }
}
