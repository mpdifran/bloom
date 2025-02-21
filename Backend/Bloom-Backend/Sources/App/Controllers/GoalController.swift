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
  private let openAIService = OpenAIAssistantService()
}

extension GoalController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("goals") {
          $0.post("suggest-goals", use: suggestGoals)
        }
      }
    }
  }
}

private extension GoalController {

  @Sendable
  func suggestGoals(_ request: Request) async throws -> SuggestGoalsResponse {
    let body = try request.content.decode(SuggestGoalsRequest.self)

    let assistantThread = try await openAIService.createOrFetchAssistantThread(
      request,
      assistantSpec: .healthGoalSetterSpec
    )

    try await openAIService.reportHealthData(
      request,
      assistantThread: assistantThread,
      healthData: body.healthData
    )

    try await openAIService.sendChatMessage(
      request,
      assistantThread: assistantThread,
      message: "Please take a look at my current goals and health metrics, and suggest edits to my goals, or suggest new goals. "
    )

    let run = try await openAIService.createRun(
      request,
      assistantThread: assistantThread,
      tools: [.function(.suggestedGoal)],
      toolChoice: body.isConversation ? .auto : .function(.Function.suggestGoal)
    )

    return try await recursivelyPollRun(
      request,
      assistantThread: assistantThread,
      run: run
    )
  }

  func recursivelyPollRun(
    _ request: Request,
    assistantThread: OpenAIAssistantThread,
    run: Run,
    suggestedGoals: [SuggestedGoal] = []
  ) async throws -> SuggestGoalsResponse {
    let assistantResponse = try await request.openAI.assistants.pollRunForAssistantResponse(
      threadID: assistantThread.threadID,
      runID: run.id
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
            let typedArguments = try decoder.decode(SuggestGoalArguments.self, from: data)

            suggestedGoals.append(
              SuggestedGoal(
                metric: typedArguments.metric,
                value: typedArguments.value,
                unit: typedArguments.unit
              )
            )
          } catch {
            request.logger.error(error)
            request.logger.error(toolCall.function.arguments)
          }
        default:
          request.logger.warning("Unknown function call: \(toolCall.function.name) arguments: \(toolCall.function.arguments)")
        }
      }

      let run = try await openAIService.submitSuccessfulToolOputput(
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
      // This means the run completed.
      return SuggestGoalsResponse(goals: suggestedGoals)
    }
  }
}
