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
    dbID: String?,
    date: Date? = nil
  ) {
    self.chatMessageID = chatMessageID
    self.name = name
    self.servings = servings
    self.dbID = dbID
    self._date = State(initialValue: date ?? .now)
    self._meal = State(initialValue: meal)
    self._hasAddedFood = State(initialValue: hasPerformedAction)
  }

  @State private var meal: FoodItemLog.Meal
  @State private var date: Date
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

        HStack {
          FoodDateBindingPicker(date: $date)
          MealBindingPicker(meal: $meal)
        }
        .horizontallyCentered()
        .disabled(hasAddedFood)

        logFoodButton
      }
      .cardContainer()
    }
    .animation(.default, value: hasAddedFood)
    .padding(.horizontal)
    .sheet($presentedSheet)
    .onAppear {
      loadMealIfLogged()
    }
  }
}

private extension ChatDetectedFoodCell {

  var logFoodButton: some View {
    Group {
      if hasAddedFood, let _ = dbID {
        AsyncButton {
          try unsave()
        } label: {
          HStack {
            Image(systemSymbol: .arrowCounterclockwise)
            Text("Undo")
          }
          .horizontallyCentered()
        }
        .foregroundStyle(.tint)
        .bold()
      } else {
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
        .disabled(hasAddedFood)
      }
    }
    .sensoryFeedback(.impact, trigger: saveUndone)
    .sensoryFeedback(.success, trigger: saveComplete)
  }

  func loadMealIfLogged() {
    guard let dbID else { return }

    if let log = try? modelContext.fetchFoodItemLog(id: dbID) {
      self.meal = log.meal
      self.date = log.date
    } else {
      hasAddedFood = false
      try? modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: false)
    }
  }

  func save() async throws {
    let foodLogID = try await nutritionViewModel.log(
      modelContext: modelContext,
      name: name,
      image: nil,
      numberOfServings: 1,
      foodItemServings: servings,
      date: date,
      meal: meal
    )

    hasAddedFood = true
    try modelContext.markChatMessageActionTaken(id: chatMessageID, hasPerformedAction: hasAddedFood)
    try modelContext.storeDBID(id: chatMessageID, dbID: foodLogID)

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
          chatMessageID: "5678",
          name: "Crackers and Sliced Carrots",
          meal: .lunch,
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
          dbID: "5678"
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
