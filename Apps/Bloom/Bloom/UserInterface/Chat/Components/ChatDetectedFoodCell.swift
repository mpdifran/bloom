//
//  ChatDetectedFoodCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-17.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer

struct ChatDetectedFoodCell: View {
  let chatMessageID: String
  let name: String
  let servings: [FoodItemServingAmount]
  let dbID: String?

  init(
    chatMessageID: String,
    name: String,
    meal: FoodItemLog.Meal,
    servings: [FoodItemServingAmount],
    hasPerformedAction: Bool,
    dbID: String?
  ) {
    self.chatMessageID = chatMessageID
    self.name = name
    self.servings = servings
    self.dbID = dbID
    self._meal = State(initialValue: meal)
    self._hasAddedFood = State(initialValue: hasPerformedAction)

    loadMealIfLogged()
  }

  @State private var meal: FoodItemLog.Meal
  @State private var hasAddedFood: Bool
  @State private var saveComplete = false
  @State private var saveUndone = false
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

        MealBindingPicker(meal: $meal)
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
      if hasAddedFood {
        if let _ = dbID {
          try unsave()
        }
      } else {
        try await save()
      }
    } label: {
      Group {
        if hasAddedFood {
          if let _ = dbID {
            Label("Undo", systemSymbol: .arrowCounterclockwise)
          } else {
            Label("Food Logged", systemSymbol: .checkmark)
          }
        } else {
          Label("Log Food", systemSymbol: .forkKnife)
        }
      }
      .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .sensoryFeedback(.success, trigger: saveComplete)
    .sensoryFeedback(.stop, trigger: saveUndone)
    .disabled(hasAddedFood && dbID == nil)
  }

  func loadMealIfLogged() {
    guard
      let dbID,
      let log = try? modelContext.fetchFoodItemLog(id: dbID)
    else {
      return
    }

    self.meal = log.meal
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
    hasAddedFood = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasAddedFood)

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }
  }

  func unsave() throws {
    guard let dbID else { return }

    try modelContext.delete(
      model: FoodItemLog.self,
      where: #Predicate<FoodItemLog> { log in
        log.id == dbID
      }
    )
    hasAddedFood = false
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasAddedFood)

    saveUndone.toggle()
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatDetectedFoodCell(
          chatMessageID: "1234",
          name: "Crackers and Sliced Carrots",
          meal: .breakfast,
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
          hasPerformedAction: false,
          dbID: "1234"
        )
        ChatDetectedFoodCell(
          chatMessageID: "1234",
          name: "Crackers and Sliced Carrots",
          meal: .breakfast,
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
          hasPerformedAction: true,
          dbID: "1234"
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
