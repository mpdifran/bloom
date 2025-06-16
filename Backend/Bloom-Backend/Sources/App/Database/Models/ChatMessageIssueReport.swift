import Fluent
import Vapor

final class ChatMessageIssueReport: Model, Content, @unchecked Sendable {
  static let schema = "chat_message_issue_reports"
  
  @ID(custom: .ChatMessageIssueReport.id, generatedBy: .user)
  var id: String?
  
  @Field(key: .ChatMessageIssueReport.responseID)
  var responseID: String
  
  @OptionalField(key: .ChatMessageIssueReport.notes)
  var notes: String?
  
  @OptionalField(key: .ChatMessageIssueReport.appVersion)
  var appVersion: String?
  
  @Enum(key: .ChatMessageIssueReport.state)
  var state: State
  
  @OptionalParent(key: .ChatMessageIssueReport.userID)
  var user: User?
  
  @Timestamp(key: .ChatMessageIssueReport.createdAt, on: .create)
  var createdAt: Date?
  
  @Timestamp(key: .ChatMessageIssueReport.updatedAt, on: .update)
  var updatedAt: Date?
  
  init() { }
  
  init(
    id: String = UUID().uuidString,
    responseID: String,
    notes: String? = nil,
    appVersion: String? = nil,
    state: State = .open,
    userID: User.IDValue? = nil
  ) {
    self.id = id
    self.responseID = responseID
    self.notes = notes
    self.appVersion = appVersion
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

extension FieldKey {
  enum ChatMessageIssueReport {
    static let id = FieldKey("id")
    static let responseID = FieldKey("response_id")
    static let notes = FieldKey("notes")
    static let appVersion = FieldKey("app_version")
    static let state = FieldKey("state")
    static let userID = FieldKey("user_id")
    static let createdAt = FieldKey("created_at")
    static let updatedAt = FieldKey("updated_at")
  }
}