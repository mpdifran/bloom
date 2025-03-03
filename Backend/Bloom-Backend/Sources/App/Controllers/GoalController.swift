//
//  GoalController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import Vapor
import BloomModel
import OpenAIKit

struct GoalController {
  private let openAIService = OpenAIService()
  private let openAIAssistantService = OpenAIAssistantService()
}

extension GoalController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("goals") {
          $0.post("suggest", use: suggestGoals)
        }
      }
    }
  }
}

private extension GoalController {

  @Sendable
  func suggestGoals(_ request: Request) async throws -> SuggestGoalsResponse {
    let body = try request.content.decode(SuggestGoalsRequest.self)

    return try await openAIService.suggestGoals(
      request,
      healthData: body.healthData,
      currentGoals: body.currentGoals
    )

//    let assistantThread = try await openAIAssistantService.createOrFetchAssistantThread(
//      request,
//      assistantSpec: .healthGoalSetterSpec
//    )
//
//    try await openAIAssistantService.cancelCurrentlyActiveRuns(
//      request,
//      assistantThread: assistantThread
//    )
//
//    try await openAIAssistantService.sendUserContent(
//      request,
//      assistantThread: assistantThread,
//      content: [
//        .text("Here is my health data: \n\n```\n\(body.healthData)\n```"),
//        .text("Here are my current goals: \n\n```\n\(body.currentGoals)\n```"),
//        .text("""
//        Analyze my health data, and identify the main areas of my health that I should focus on. Ensure my goals 
//        align with those focus areas. Update my goals, or give me new goals to help improve my health.
//        """)
//      ]
//    )
//
//    let run = try await openAIAssistantService.createRun(
//      request,
//      assistantThread: assistantThread,
//      tools: [.function(.suggestedGoal)],
//      toolChoice: body.isConversation ? .auto : .function(.Function.suggestGoal)
//    )
//
//    return try await recursivelyPollRun(
//      request,
//      assistantThread: assistantThread,
//      run: run
//    )
  }

  func recursivelyPollRun(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    run: Run,
    suggestedGoals: [SuggestedGoal] = []
  ) async throws -> SuggestGoalsResponse {
    let assistantResponse = try await request.openAI.assistants.pollRunForAssistantResponse(
      threadID: assistantThread.threadID,
      runID: run.id,
      pollInterval: 1
    )

    var suggestedGoals = suggestedGoals

    switch assistantResponse {
    case .requiresAction(let run, let toolCalls):
      for toolCall in toolCalls {
        switch toolCall.function.name {
        case .Function.suggestGoal:
          guard let data = toolCall.function.arguments.data(using: .utf8) else { continue }

          let decoder = JSONDecoder()
          do {
            let suggestedGoal = try decoder.decode(SuggestedGoal.self, from: data)

            suggestedGoals.append(suggestedGoal)
          } catch {
            request.logger.error(error)
            request.logger.error(toolCall.function.arguments)
          }
        default:
          request.logger.warning("[\(Date())] Unknown function call: \(toolCall.function.name) arguments: \(toolCall.function.arguments)")
        }
      }

      let run = try await openAIAssistantService.submitSuccessfulToolOputput(
        request,
        threadID: assistantThread.threadID,
        runID: run.id,
        toolCalls: toolCalls
      )

      return try await recursivelyPollRun(
        request,
        assistantThread: assistantThread,
        run: run,
        suggestedGoals: suggestedGoals
      )
    case .messages(_, let messages):
      let message = messages.flatMap({ $0.content }).compactMap({ $0.text }).last
      return SuggestGoalsResponse(
        summary: message,
        goals: suggestedGoals
      )
    }
  }
}
