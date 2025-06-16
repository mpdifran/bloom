import Fluent

extension ChatMessageIssueReport {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(ChatMessageIssueReport.schema)
        .field(.ChatMessageIssueReport.id, .string, .identifier(auto: false))
        .field(.ChatMessageIssueReport.responseID, .string, .required)
        .field(.ChatMessageIssueReport.notes, .string)
        .field(.ChatMessageIssueReport.userID, .string, .references(User.schema, "id"))
        .field(.ChatMessageIssueReport.createdAt, .datetime)
        .field(.ChatMessageIssueReport.updatedAt, .datetime)
        .create()
    }
    
    func revert(on database: any Database) async throws {
      try await database.schema(ChatMessageIssueReport.schema).delete()
    }
  }
  
  struct AddState: AsyncMigration {
    func prepare(on database: any Database) async throws {
      let stateEnumType = try await database.enum(State.self)
        .case(.open)
        .case(.archived)
        .create()
      
      try await database.schema(ChatMessageIssueReport.schema)
        .field(.ChatMessageIssueReport.state, stateEnumType, .required, .custom("DEFAULT 'open'"))
        .update()
    }
    
    func revert(on database: any Database) async throws {
      try await database.schema(ChatMessageIssueReport.schema)
        .deleteField(.ChatMessageIssueReport.state)
        .update()
      
      try await database.enum(State.self).delete()
    }
  }
  
  struct AddAppVersion: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(ChatMessageIssueReport.schema)
        .field(.ChatMessageIssueReport.appVersion, .string)
        .update()
    }
    
    func revert(on database: any Database) async throws {
      try await database.schema(ChatMessageIssueReport.schema)
        .deleteField(.ChatMessageIssueReport.appVersion)
        .update()
    }
  }
}