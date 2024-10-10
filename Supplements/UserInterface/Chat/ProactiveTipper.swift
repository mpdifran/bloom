//
//  ProactiveTipper.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-07.
//

import Foundation
import HealthKit

final actor ProactiveTipper {
    static let shared = ProactiveTipper()

    private init() { }
}

extension ProactiveTipper {

    func sendProactiveTip() async {
        let chatHistory = ChatViewModel.shared.networkChatHistory

        let stressDetails = await VitalsCalculator.shared.stressSummary?.details

        let request = ProactiveTipRequestModel(
            stressMonthlySummary: nil,
            nutritionMonthlySummary: nil,
            sleepVitalsMonthlySummary: await VitalsCalculator.shared.sleepVitalsSummary,
            activityLevelMonthlySummary: await VitalsCalculator.shared.activityLevelSummary,
            chatHistory: chatHistory
        )

        guard let response = try? await NetworkRequester.shared.sendProactiveTip(request: request) else { return }

        await ChatViewModel.shared.appendAssistantMessage(message: response.message)
    }
}
