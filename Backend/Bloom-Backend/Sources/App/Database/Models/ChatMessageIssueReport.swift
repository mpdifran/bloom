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
  
  @Enum(key: "state")
  var state: State
  
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
    state: State = .open,
    userID: User.IDValue? = nil
  ) {
    self.id = id
    self.responseID = responseID
    self.notes = notes
    self.state = state
    self.$user.id = userID
  }
}

extension ChatMessageIssueReport {
  enum State: String, Codable, FluentEnum {
    static let schema = "chat_issue_report_state"
    
    case open
    case archived
  }
}