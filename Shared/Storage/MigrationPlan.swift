import SwiftData

/// The store's migration plan (ios.md §6). Version 2 adds the settings row's theme color (T-33), version 3 its
/// appearance (T-34), and version 4 a task's notes, one part-start switch per part and the missed style (T-37).
/// Every change adds or removes plain columns with defaults, so lightweight stages move older stores across with
/// their data.
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self] }
    static var stages: [MigrationStage] { [v1ToV2, v2ToV3, v3ToV4] }

    static let v1ToV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    static let v2ToV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)
    static let v3ToV4 = MigrationStage.lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self)
}
