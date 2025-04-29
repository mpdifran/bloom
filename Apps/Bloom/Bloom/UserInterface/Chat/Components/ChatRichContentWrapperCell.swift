//
//  ChatRichContentWrapperCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-13.
//

import SwiftUI
import AppUI
import HealthKit
import BloomModel
import DataContainer

struct ChatRichContentWrapperCell: View {
  let chatMessageID: String
  let data: Data
  let hasPerformedAction: Bool

  @State private var isLoading = true
  @State private var goals: [ProposedGoal]?
  @State private var foodItemsName: String?
  @State private var foodItemServings: [FoodItemServingAmount]?
  @State private var waterQuantity: HKQuantity?
  @State private var bristolStoolType: Int?
  @State private var duration: BowelMovement.Duration?
  @State private var weightQuantity: HKQuantity?
  @State private var systolic: Double?
  @State private var diastolic: Double?
  @State private var workoutTemplate: SocketMessage.WorkoutTemplate?

  private let modelActor = HabitModelActor.standard()

  var body: some View {
    Group {
      if isLoading {
        HStack {
          HStack {
            Spacer()
            ProgressView()
              .progressViewStyle(.circular)
              .padding()
            Spacer()
          }
          .cardContainer()
          .padding(.leading)

          Spacer(minLength: 60)
        }
      } else {
        if let goals {
          ChatGoalsCell(
            chatMessageID: chatMessageID,
            goals: goals,
            hasPerformedAction: hasPerformedAction
          )
        } else if let foodItemsName, let foodItemServings {
          ChatDetectedFoodCell(
            chatMessageID: chatMessageID,
            name: foodItemsName,
            servings: foodItemServings,
            hasPerformedAction: hasPerformedAction
          )
        } else if let waterQuantity {
          ChatLogWaterCell(
            chatMessageID: chatMessageID,
            waterQuantity: waterQuantity,
            hasPerformedAction: hasPerformedAction
          )
        } else if let bristolStoolType, let duration {
          ChatLogBowelMovementCell(
            chatMessageID: chatMessageID,
            bristolStoolType: bristolStoolType,
            duration: duration,
            hasPerformedAction: hasPerformedAction
          )
        } else if let weightQuantity {
          ChatLogWeightCell(
            chatMessageID: chatMessageID,
            weightQuantity: weightQuantity,
            hasPerformedAction: hasPerformedAction
          )
        } else if let systolic, let diastolic {
          ChatLogBloodPressureCell(
            chatMessageID: chatMessageID,
            systolic: systolic,
            diastolic: diastolic,
            hasPerformedAction: hasPerformedAction
          )
        } else if let workoutTemplate {
          ChatWorkoutTemplateCell(
            chatMessageID: chatMessageID,
            workoutTemplate: workoutTemplate,
            hasPerformedAction: hasPerformedAction
          )
        }
      }
    }
    .animation(.easeInOut, value: isLoading)
    .task {
      await loadContent()
    }
  }
}

private extension ChatRichContentWrapperCell {

  func loadContent() async {
    if let healthGoals = try? JSONDecoder.bloomModel.decode([SocketMessage.HealthMetricGoal].self, from: data) {

      var proposedGoals = [ProposedGoal]()
      for healthGoal in healthGoals {
        let habit = try? await modelActor.fetchActiveHabits(for: healthGoal.metric.targetMetric).first

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
        self.goals = proposedGoals
      }

    } else if let detectedFood = try? JSONDecoder.bloomModel.decode(SocketMessage.DetectedFood.self, from: data) {

      self.foodItemsName = detectedFood.name
      self.foodItemServings = detectedFood.foodItemServings.map { $0.asServing() }

    } else if let logWater = try? JSONDecoder.bloomModel.decode(SocketMessage.LogWaterConsumption.self, from: data) {

      self.waterQuantity = HKQuantity(
        unit: HKUnit(from: logWater.unit.rawValue),
        doubleValue: logWater.amount
      )

    } else if let logBowelMovement = try? JSONDecoder.bloomModel.decode(SocketMessage.LogBowelMovement.self, from: data) {

      self.bristolStoolType = logBowelMovement.bristolStoolType
      self.duration = switch logBowelMovement.duration {
      case .lessThan5Min:
          .lessThan5Min
      case .between5And10Min:
          .between5And10Min
      case .moreThan10Min:
          .moreThan10Min
      }

    } else if let logWeight = try? JSONDecoder.bloomModel.decode(SocketMessage.LogWeight.self, from: data) {

      self.weightQuantity = HKQuantity(
        unit: HKUnit(from: logWeight.unit.rawValue),
        doubleValue: logWeight.value
      )

    } else if let logBloodPressure = try? JSONDecoder.bloomModel.decode(SocketMessage.LogBloodPressure.self, from: data) {

      self.systolic = Double(logBloodPressure.systolic)
      self.diastolic = Double(logBloodPressure.diastolic)
      
    } else if let workoutTemplate = try? JSONDecoder.bloomModel.decode(SocketMessage.WorkoutTemplate.self, from: data) {

      self.workoutTemplate = workoutTemplate
    }

    self.isLoading = false
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatBubbleCell(
          message: "Here's some rich content",
          isDirect: false,
          isCurrentUser: false,
          showTail: true
        )
        ChatRichContentWrapperCell(
          chatMessageID: "123",
          data: Data(),
          hasPerformedAction: false
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
