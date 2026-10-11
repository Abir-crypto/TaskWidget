import SwiftData

/// The store's migration plan (ios.md §6). Version 2 adds the settings row's theme color (T-33); nothing else
/// changes, so a lightweight stage moves a version-1 store across with its data.
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [v1ToV2] }

    static let v1ToV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
}
