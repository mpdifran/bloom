import Fluent
import Vapor

final class ChatMessageIssueReport: Model, Content, @unchecked Sendable {
    static let schema = "chat_message_issue_reports"
    
    @ID(custom: "id", generatedBy: .user)
    var id: String?
    
    @Field(key: "response_id")
    var responseID: String
    
    @OptionalField(key: "notes")
    var notes: String?
    
    @OptionalParent(key: "user_id")
    var user: User?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: String = UUID().uuidString,
        responseID: String,
        notes: String? = nil,
        userID: User.IDValue? = nil
    ) {
        self.id = id
        self.responseID = responseID
        self.notes = notes
        self.$user.id = userID
    }
}