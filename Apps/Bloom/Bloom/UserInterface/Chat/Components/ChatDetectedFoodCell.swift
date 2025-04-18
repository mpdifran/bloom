//
//  ChatDetectedFoodCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-17.
//

import SwiftUI
import AppUI
import BloomModel

struct ChatDetectedFoodCell: View {
  let chatMessageID: String
  let name: String
  let servings: [FoodItemServingAmount]

  init(
    chatMessageID: String,
    name: String,
    servings: [FoodItemServingAmount],
    hasPerformedAction: Bool
  ) {
    self.chatMessageID = chatMessageID
    self.name = name
    self.servings = servings
    self._hasAddedFood = State(initialValue: hasPerformedAction)
  }

  @State private var hasAddedFood: Bool
  @State private var saveComplete = false
  @State private var presentedSheet: AnyView?

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(name)
          .font(.title3)
          .fontWeight(.heavy)
          .fontDesign(.rounded)
          .lineLimit(3)
          .multilineTextAlignment(.leading)

        Divider()

        ForEachEnumerated(servings) { index, serving in
          if index != 0 {
            Divider()
          }
          ChatDetectedFoodItemCell(foodItemServing: serving)
            .onTapGesture {
              presentedSheet = FoodItemDetailsView(
                foodItem: serving.foodItem,
                existingFoodItemLog: nil,
                mode: .viewOnly
              ).asAny
            }
        }

        Divider()

        MealPicker()
          .horizontallyCentered()
          .disabled(hasAddedFood)

        logFoodButton
      }
      .cardContainer()

      Spacer(minLength: 60)
    }
    .padding(.horizontal)
    .sheet($presentedSheet)
  }
}

private extension ChatDetectedFoodCell {

  var logFoodButton: some View {
    AsyncButton {
      try await save()
    } label: {
      Group {
        if hasAddedFood {
          Label("Food Logged", systemSymbol: .checkmark)
        } else {
          Label("Log Food", systemSymbol: .forkKnife)
        }
      }
      .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .sensoryFeedback(.success, trigger: saveComplete)
    .disabled(hasAddedFood)
  }

  func save() async throws {
    try await nutritionViewModel.log(
      modelContext: modelContext,
      name: name,
      image: nil,
      numberOfServings: 1,
      foodItemServings: servings,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal
    )
    try modelContext.markChatMessageActionTaken(id: chatMessageID)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
    hasAddedFood = true

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatDetectedFoodCell(
          chatMessageID: "1234",
          name: "Crackers and Sliced Carrots",
          servings: [
            FoodItemServingAmount(
              serving: 2,
              foodItem: .Preview.ritzCrackers
            ),
            FoodItemServingAmount(
              serving: 4,
              foodItem: .Preview.slicedCarrots
            )
          ],
          hasPerformedAction: false
        )
        ChatDetectedFoodCell(
          chatMessageID: "1234",
          name: "Crackers and Sliced Carrots",
          servings: [
            FoodItemServingAmount(
              serving: 2,
              foodItem: .Preview.ritzCrackers
            ),
            FoodItemServingAmount(
              serving: 4,
              foodItem: .Preview.slicedCarrots
            )
          ],
          hasPerformedAction: true
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
