import Foundation
import SwiftData
import DataContainer
import BloomFoundation
import UIKit
import HealthKit
import BloomModel

actor ChatHistoryModifier {
  static let shared = ChatHistoryModifier()
  
  @AsyncStreamable private(set) var cellModels: [ChatCellModel] = []
  
  private let modelActor: ChatMessageModelActor
  private let habitModelActor: HabitModelActor
  private var messages: [ChatMessageDTO] = []
  private var inProgressMessages: [ChatController.InProgressMessage] = []
  private var assistantTypingStatus: String?
  private var assistantIsTyping = false
  
  private static let defaultMessageLimit = 20
  
  private init() {
    self.modelActor = ChatMessageModelActor.standard()
    self.habitModelActor = HabitModelActor.standard()
    
    // Load initial messages with default limit
    Task {
      await loadMessages()
    }
    
    // Subscribe to ChatController updates
    Task {
      await subscribeToUpdates()
    }
  }
  
  private func loadMessages(limit: Int? = defaultMessageLimit) async {
    do {
      let fetchedMessages = try await modelActor.fetchMessages(limit: limit)
      // Reverse the messages so they're in chronological order (oldest first)
      self.messages = fetchedMessages.reversed()
      await buildCellModels()
    } catch {
      print("Failed to load chat messages: \(error)")
    }
  }
  
  private func subscribeToUpdates() async {
    // Subscribe to in-progress messages
    Task {
      for await messages in await ChatController.shared.$inProgressMessages {
        self.inProgressMessages = messages
        await buildCellModels()
      }
    }
    
    // Subscribe to typing status
    Task {
      for await status in await ChatController.shared.$assistantTypingStatus {
        self.assistantTypingStatus = status
        await buildCellModels()
      }
    }
    
    // Subscribe to typing indicator
    Task {
      for await isTyping in await ChatController.shared.$assistantIsTyping {
        self.assistantIsTyping = isTyping
        await buildCellModels()
      }
    }
  }
  
  private func buildCellModels() async {
    var cellModels: [ChatCellModel] = []
    
    // Handle empty state
    if messages.isEmpty && inProgressMessages.isEmpty && !assistantIsTyping {
      cellModels = [ChatCellModel(id: "prompts", contentType: .prompts)]
      self.cellModels = cellModels
      return
    }
    
    // Track responseIDs to determine which message should show report button
    var seenResponseIDs = Set<String>()
    
    // Process messages in reverse order to build cellModels efficiently
    for message in messages.reversed() {
      let showReportButton = !message.isCurrentUser && 
                           message.responseID != nil && 
                           !seenResponseIDs.contains(message.responseID!)
      
      if let responseID = message.responseID {
        seenResponseIDs.insert(responseID)
      }
      
      let metadata = ChatMessageMetadata(
        persistentID: message.persistentID,
        isCurrentUser: message.isCurrentUser,
        date: message.date,
        hasPerformedAction: message.hasPerformedAction,
        dbID: message.dbID,
        requestID: message.requestID,
        responseID: message.responseID,
        showReportButton: showReportButton
      )
      
      switch message.content {
      case .message(let text):
        print("Inserting completed text content: \(message.id)")
        cellModels.insert(
          ChatCellModel(
            id: message.id,
            contentType: .text(id: message.id, content: text, metadata: metadata)
          ),
          at: 0
        )
        
      case .imageData(let data):
        cellModels.insert(
          ChatCellModel(
            id: message.id,
            contentType: .image(id: message.id, imageData: data, metadata: metadata)
          ),
          at: 0
        )
        
      case .richContent(let data):
        let processedContent = await processRichContent(from: data, dbID: message.dbID) ?? .unknown
        print("Inserting completed rich content: \(message.id)")
        cellModels.insert(
          ChatCellModel(
            id: message.id,
            contentType: .richContent(
              id: message.id,
              content: processedContent,
              metadata: metadata
            )
          ),
          at: 0
        )

      @unknown default:
        cellModels.insert(
          ChatCellModel(
            id: message.id,
            contentType: .richContent(
              id: message.id,
              content: .unknown,
              metadata: metadata
            )
          ),
          at: 0
        )
      }
    }
    
    // Add in-progress messages (these go at the end)
    for inProgressMessage in inProgressMessages {
      // Skip if already exists as a regular message
      guard !messages.contains(where: { $0.id == inProgressMessage.id }) else { continue }

      // Check if this in-progress message has rich content
      if let data = inProgressMessage.data {
        let processedContent = await processRichContent(from: data, dbID: nil) ?? .unknown
        print("Appending in progress rich content: \(inProgressMessage.id)")
        cellModels.append(
          ChatCellModel(
            id: inProgressMessage.id,
            contentType: .richContent(
              id: inProgressMessage.id,
              content: processedContent,
              metadata: nil
            )
          )
        )
      } else {
        // Regular in-progress text message - only show if not empty after trimming
        let trimmedMessage = inProgressMessage.message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedMessage.isNotEmpty else { continue }
        
        print("Appending in progress text content: \(inProgressMessage.id)")
        cellModels.append(
          ChatCellModel(
            id: inProgressMessage.id,
            contentType: .text(
              id: inProgressMessage.id,
              content: trimmedMessage,
              metadata: nil
            )
          )
        )
      }
    }
    
    // Add status text if present
    if let statusText = assistantTypingStatus {
      cellModels.append(ChatCellModel(
        id: "status-text",
        contentType: .statusText(statusText)
      ))
    }
    
    // Add typing indicator
    if assistantIsTyping {
      cellModels.append(ChatCellModel(
        id: "typing-indicator",
        contentType: .typingIndicator
      ))
    }

    self.cellModels = cellModels
  }
  
  func addMessage(_ chatMessage: ChatMessage) async throws {
    // Convert to DTO
    let dto = chatMessage.asDTO()
    
    // Add to end of list (newest messages at the end)
    var updatedMessages = messages
    updatedMessages.append(dto)
    
    // Trim from the beginning if we exceed the limit
    if updatedMessages.count > Self.defaultMessageLimit {
      updatedMessages = Array(updatedMessages.suffix(Self.defaultMessageLimit))
    }
    
    self.messages = updatedMessages
    await buildCellModels()
    
    // Insert directly using model context
    let context = ModelContext(ContainerHolder.shared.container)
    context.insert(chatMessage)
    try context.save()
  }
  
  func updateMessageAction(id: String, hasPerformedAction: Bool) async throws {
    // Update in database and get the updated DTO
    guard let updatedDTO = try await modelActor.updateMessageAction(id: id, hasPerformedAction: hasPerformedAction) else {
      return
    }
    
    // Update in-memory list
    var updatedMessages = messages
    if let index = updatedMessages.firstIndex(where: { $0.id == id }) {
      updatedMessages[index] = updatedDTO
      self.messages = updatedMessages
      await buildCellModels()
    }
  }
  
  func deleteAllMessages() async throws {
    // Clear in-memory list
    self.messages = []
    await buildCellModels()
    
    // Delete from database
    let context = ModelContext(ContainerHolder.shared.container)
    try context.delete(model: ChatMessage.self)
    try context.save()
  }
  
  func refreshMessages() async {
    await loadMessages()
  }
  
  func loadMoreMessages() async {
    // Load all messages without limit to get more history
    await loadMessages(limit: nil)
  }
  
  // Process rich content data synchronously to avoid async loading in UI
  private func processRichContent(from data: Data, dbID: String?) async -> ProcessedRichContent? {
    if let healthGoals = try? JSONDecoder.bloomModel.decode([SocketMessage.HealthMetricGoal].self, from: data) {
      var proposedGoals = [ProposedGoal]()
      for healthGoal in healthGoals {
        let habit = try? await habitModelActor.fetchActiveHabits(for: healthGoal.metric.targetMetric).first
        
        let timePeriod: GoalTimePeriod = switch healthGoal.timePeriod {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        
        let proposedGoal = ProposedGoal(
          habitID: habit?.id,
          targetMetric: healthGoal.metric.targetMetric,
          timePeriod: timePeriod,
          value: healthGoal.value,
          suggestedValue: healthGoal.value,
          previousValue: habit?.value,
          unitString: healthGoal.unit.hkUnit.unitString,
          vitalKind: nil,
          context: "",
          hasUserEdited: habit?.isUserEdited == true
        )
        proposedGoals.append(proposedGoal)
      }
      if proposedGoals.isNotEmpty {
        return .goals(proposedGoals)
      }
      
    } else if let detectedFood = try? JSONDecoder.bloomModel.decode(SocketMessage.DetectedFood.self, from: data) {
      return .detectedFood(
        name: detectedFood.name,
        meal: detectedFood.meal.asMeal,
        servings: detectedFood.foodItemServings.map { $0.asServing() },
        date: detectedFood.date
      )
      
    } else if let logWater = try? JSONDecoder.bloomModel.decode(SocketMessage.LogWaterConsumption.self, from: data) {
      let waterQuantity = HKQuantity(
        unit: HKUnit(from: logWater.unit.rawValue),
        doubleValue: logWater.amount
      )
      return .logWater(waterQuantity)
      
    } else if let logBowelMovement = try? JSONDecoder.bloomModel.decode(SocketMessage.LogBowelMovement.self, from: data) {
      return .logBowelMovement(
        bristolStoolType: logBowelMovement.bristolStoolType,
        duration: logBowelMovement.duration.asBowelMovementDuration
      )
      
    } else if let logWeight = try? JSONDecoder.bloomModel.decode(SocketMessage.LogWeight.self, from: data) {
      let weightQuantity = HKQuantity(
        unit: HKUnit(from: logWeight.unit.rawValue),
        doubleValue: logWeight.value
      )
      return .logWeight(weightQuantity)
      
    } else if let logPeriod = try? JSONDecoder.bloomModel.decode(SocketMessage.LogPeriod.self, from: data) {
      return .logPeriod(logPeriod.flow.hkFlow)
      
    } else if let logBloodPressure = try? JSONDecoder.bloomModel.decode(SocketMessage.LogBloodPressure.self, from: data) {
      return .logBloodPressure(
        systolic: Double(logBloodPressure.systolic),
        diastolic: Double(logBloodPressure.diastolic)
      )
      
    } else if let workoutPlan = try? JSONDecoder.bloomModel.decode(SocketMessage.WorkoutPlan.self, from: data) {
      return .workoutPlan(workoutPlan)
      
    } else if let createReminder = try? JSONDecoder.bloomModel.decode(SocketMessage.CreateReminder.self, from: data) {
      // Extract the reminder ID to store in ProcessedRichContent
      let reminderID = dbID ?? createReminder.id ?? UUID().uuidString
      return .createReminder(reminderID: reminderID)
      
    } else if let deleteReminder = try? JSONDecoder.bloomModel.decode(SocketMessage.DeleteReminder.self, from: data) {
      // Use the reminder ID from the delete message
      return .deleteReminder(reminderID: deleteReminder.reminderID)
      
    } else if let createUserFacts = try? JSONDecoder.bloomModel.decode(SocketMessage.CreateUserFacts.self, from: data) {
      return .createUserFacts(createUserFacts)
      
    } else if let deleteUserFacts = try? JSONDecoder.bloomModel.decode(SocketMessage.DeleteUserFacts.self, from: data) {
      return .deleteUserFacts(deleteUserFacts)
    }
    
    return .unknown
  }
}

enum ChatMessageError: LocalizedError {
  case invalidMessage
  
  var errorDescription: String? {
    switch self {
    case .invalidMessage:
      return "Invalid chat message"
    }
  }
}
