import Fluent

extension ChatMessageIssueReport {
    struct Create: AsyncMigration {
        func prepare(on database: any Database) async throws {
            try await database.schema(ChatMessageIssueReport.schema)
                .field("id", .string, .identifier(auto: false))
                .field("response_id", .string, .required)
                .field("notes", .string)
                .field("user_id", .string, .references(User.schema, "id"))
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(ChatMessageIssueReport.schema).delete()
        }
    }
}