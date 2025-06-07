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
    var models: [ChatCellModel] = []
    
    // Handle empty state
    if messages.isEmpty && inProgressMessages.isEmpty && !assistantIsTyping {
      models = [ChatCellModel(id: "prompts", contentType: .prompts)]
      self.cellModels = models
      return
    }
    
    // Add regular messages
    for message in messages {
      // Check if this message has rich content
      if case .richContent(let data) = message.content {
        // Process rich content and create appropriate cell model
        if let processedContent = await processRichContent(from: data) {
          models.append(ChatCellModel(
            id: message.id,
            contentType: .richContent(
              chatMessageID: message.id,
              content: processedContent,
              hasPerformedAction: message.hasPerformedAction,
              dbID: message.dbID
            )
          ))
        } else {
          // Fallback to regular message if processing fails
          models.append(ChatCellModel(
            id: message.id,
            contentType: .message(message)
          ))
        }
      } else {
        // Regular message
        models.append(ChatCellModel(
          id: message.id,
          contentType: .message(message)
        ))
      }
    }
    
    // Add in-progress messages
    for inProgressMessage in inProgressMessages {
      // Skip if already exists as a regular message
      if !messages.contains(where: { $0.id == inProgressMessage.id }) {
        // Check if this in-progress message has rich content
        if let data = inProgressMessage.data {
          if let processedContent = await processRichContent(from: data) {
            models.append(ChatCellModel(
              id: inProgressMessage.id,
              contentType: .richContent(
                chatMessageID: inProgressMessage.id,
                content: processedContent,
                hasPerformedAction: false,
                dbID: nil
              )
            ))
          } else {
            // Fallback to regular in-progress message
            models.append(ChatCellModel(
              id: inProgressMessage.id,
              contentType: .inProgress(inProgressMessage)
            ))
          }
        } else {
          // Regular in-progress message
          models.append(ChatCellModel(
            id: inProgressMessage.id,
            contentType: .inProgress(inProgressMessage)
          ))
        }
      }
    }
    
    // Add status text if present
    if let statusText = assistantTypingStatus {
      models.append(ChatCellModel(
        id: "status-text",
        contentType: .statusText(statusText)
      ))
    }
    
    // Add typing indicator
    if assistantIsTyping {
      models.append(ChatCellModel(
        id: "typing-indicator",
        contentType: .typingIndicator
      ))
    }
    
    self.cellModels = models
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
  private func processRichContent(from data: Data) async -> ProcessedRichContent? {
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
        servings: detectedFood.foodItemServings.map { $0.asServing() }
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
      let reminderID = createReminder.id ?? UUID().uuidString
      return .createReminder(reminderID: reminderID)
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
