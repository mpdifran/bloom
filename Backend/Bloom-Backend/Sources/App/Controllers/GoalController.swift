//
//  GoalController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import Vapor
import BloomModel

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

    let assistantResponse = try await openAIService.startRunAndPollForResponse(
      request,
      assistantThread: assistantThread,
      tools: [.function(.suggestedGoal)],
      toolChoice: body.isConversation ? .auto : .function(.Function.suggestGoal)
    )
    let contents = assistantResponse.flatMap{ $0.content }

    var suggestedGoals = [SuggestedGoal]()
    for content in contents {
      switch content {
      case .text(let text):
        request.logger.info(text)
      case .refusal(let reason):
        request.logger.warning("Refusal: \(reason)")
      case .imageURL(_, _), .imageFile(_, _):
        request.logger.warning("Image returned")
      case .functionCall(_, let functionName, let arguments):
        request.logger.info("Function call")
        switch functionName {
        case .Function.suggestGoal:
          guard let data = arguments.data(using: .utf8) else { continue }

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
            request.logger.error(arguments)
          }
        default:
          request.logger.warning("Unknown function call: \(functionName) arguments: \(arguments)")
        }
      }
    }

    return SuggestGoalsResponse(goals: suggestedGoals)
  }
}
