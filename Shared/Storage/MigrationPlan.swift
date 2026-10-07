import SwiftData

/// The store's migration plan (ios.md §6). Version 1 is the only schema so far.
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
