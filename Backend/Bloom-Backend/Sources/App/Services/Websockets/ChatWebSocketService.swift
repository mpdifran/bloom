//
//  ChatWebSocketService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-01.
//

import Vapor
import WebSocketKit
import OpenAIKit
import BloomModel

struct ChatWebSocketService: Sendable {
  let user: User
  let socket: WebSocket
  let assistantService: OpenAIAssistantService
  let logger: Logger

  init(
    user: User,
    socket: WebSocket,
    assistantService: OpenAIAssistantService,
    logger: Logger
  ) {
    self.user = user
    self.socket = socket
    self.assistantService = assistantService
    self.logger = logger
  }

  private let decoder = JSONDecoder.bloomModel
}

extension ChatWebSocketService {

  func parse(data: Data) async throws -> Bool {
    if let message = try? decoder.decode(SocketMessage.MessageRequest.self, from: data) {
      try await on(message: message)
    } else if let queryRequest = try? decoder.decode(SocketMessage.DataQueryRequest.self, from: data) {
      try await onDataQuery(queryRequest: queryRequest)
    } else {
      return false
    }
    return true
  }

  func onClose() async throws {
    let thread = try await assistantService.createOrFetchAssistantThread(
      user: user,
      assistantSpec: .healthCoach
    )
    try await assistantService.cancelCurrentlyActiveRuns(assistantThread: thread)
  }

  func on(message: SocketMessage.MessageRequest) async throws {
    let thread = try await assistantService.createOrFetchAssistantThread(
      user: user,
      assistantSpec: .healthCoach
    )

    try await assistantService.sendChatMessage(
      assistantThread: thread,
      messages: [
        "Here are some details about me:\n\n\(message.userInfo)",
        message.text
      ]
    )

    try await performRun(thread: thread)
  }

  func onDataQuery(queryRequest: SocketMessage.DataQueryRequest) async throws {
    let thread = try await assistantService.createOrFetchAssistantThread(
      user: user,
      assistantSpec: .healthCoach
    )

    let toolOutputs = queryRequest.queryData.map { ToolOutput(toolCallID: $0.id, output: $0.data) }

    let run = try await assistantService.submitSuccessfulToolOputput(
      threadID: thread.threadID,
      runID: queryRequest.id,
      toolOutputs: toolOutputs
    )

    try await performRun(thread: thread, existingRun: run)
  }
}

private extension ChatWebSocketService {

  func performRun(thread: OpenAIAssistantThread, existingRun: Run? = nil) async throws {
    try sendIsAssistantTyping(isTyping: true)

    let assistantResponse = try await assistantService.startRunAndPollForResponse(
      assistantThread: thread,
      tools: [
        Assistant.Tool.function(.queryUserHealthData)
      ],
//      toolChoice: .function(.Function.queryUserHealthData),
      existingRun: existingRun
    )

    switch assistantResponse {
    case .requiresAction(let run, let toolCalls):
      var queries = [SocketMessage.Query]()
      for toolCall in toolCalls {
        switch toolCall.function.name {
        case .Function.queryUserHealthData:
          let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthDataArguments.self, using: decoder)
          let query = SocketMessage.Query(
            id: toolCall.id,
            startDate: queryArguments.startDate,
            endDate: queryArguments.endDate,
            dataType: queryArguments.dataType
          )
          queries.append(query)
        default:
          throw Abort(.internalServerError, reason: "Unsupported tool function: \(toolCall.function.name)")
        }
      }
      try sendDataQueryResponse(run: run, queries: queries)
    case .messages(_, let messages):
      let textMessages = messages.flatMap { message in
        message.content.compactMap({ $0.text })
      }

      let messagesResponse = SocketMessage.MessagesResponse(texts: textMessages)
      try sendIsAssistantTyping(isTyping: false)
      try socket.sendContent(messagesResponse)
    }
  }

  func sendDataQueryResponse(run: Run, queries: [SocketMessage.Query]) throws {
    let dataQueryResponse = SocketMessage.DataQueryResponse(
      id: run.id,
      queries: queries
    )
    try socket.sendContent(dataQueryResponse)
  }

  func sendIsAssistantTyping(isTyping: Bool) throws {
    let typingIndicator = SocketMessage.TypingIndicator(isTyping: isTyping)
    try socket.sendContent(typingIndicator)
  }
}
