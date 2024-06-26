//
//  SleepProgramCoordinator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import SwiftUI
import ScreenControl
import OpenAPIClient

private extension String {
    static let sleepProgramStartDate = "SleepProgramCoordinator.startDate"
    static let sleepEnvironmentTemperature = "SleepProgramCoordinator.sleepEnvironmentTemperature"
    static let sleepEnvironmentSound = "SleepProgramCoordinator.sleepEnvironmentSound"
    static let sleepEnvironmentDarkness = "SleepProgramCoordinator.sleepEnvironmentDarkness"
    static let automatedIds = "automatedIds"
}

@MainActor
final class SleepProgramCoordinator: ObservableObject {
    static let shared = SleepProgramCoordinator()

    @Published private(set) var startDate: Date? {
        didSet {
            UserDefaults.group.set(startDate, forKey: .sleepProgramStartDate)
        }
    }
    @Published private(set) var assistantResponse: PostSleepAssistantResponse?

    @AppStorage(.sleepEnvironmentTemperature, store: .group) var environmentTemperature = SleepEnvironmentTemperature.cold
    @AppStorage(.sleepEnvironmentSound, store: .group) var environmentSound = SleepEnvironmentSound.quiet
    @AppStorage(.sleepEnvironmentDarkness, store: .group) var environmentDarkness = SleepEnvironmentDarkness.dark

    @AppStorage(.automatedIds, store: .group) private var automatedIDs = ""

    private init() { 
        if let date = UserDefaults.group.object(forKey: .sleepProgramStartDate) as? Date {
            self.startDate = date
        }
    }
}

extension SleepProgramCoordinator {

    func startProgram() {
        startDate = .now
    }

    func stopProgram() {
        startDate = nil
        ScreenUseController.shared.stopMonitoring()
    }
}

extension SleepProgramCoordinator {

    func sleepProgramUpdate() async throws {
        let userInfo = HealthManager.shared.userInfoModel
        let viewModel = InsightsViewModel.shared
        let request = PostSleepAssistantRequest(
            automatedIds: automatedIDs,
            userInfo: UserInfo(
                name: userInfo?.name,
                age: userInfo?.age,
                sex: userInfo?.sex,
                location: userInfo?.location?.location
            ),
            sleepHealthSnapshot: SleepHealthSnapshot(
                timeInDaylight: viewModel.timeInDaylight.map { $0.healthMetricSample },
                restingHeartRate: viewModel.restingHeartRate.map { $0.healthMetricSample },
                meditation: viewModel.meditationMinutes.map { $0.healthMetricSample },
                workouts: viewModel.workoutSummary.map { $0.healthWorkout },
                sleepSummaries: viewModel.sleepAnalysis.map { $0.sleepSummary }
            )
        )

//        if let data = try? JSONEncoder.main.encode(request) {
//            print(String(data: data, encoding: .utf8) ?? "")
//        }

        let response = try await AssistantAPI.postSleepAssistant(postSleepAssistantRequest: request)

        self.automatedIDs = response.automatedIds
        self.assistantResponse = response
    }

    func resetAssistant() {
        automatedIDs = ""
    }
}
