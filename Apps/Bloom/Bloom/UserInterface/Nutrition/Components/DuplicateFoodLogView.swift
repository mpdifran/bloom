//
//  DuplicateFoodLogView.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import SwiftUI
import DataContainer
import AppUI
import BloomFoundation
import SFSafeSymbols
import CoreHealth

struct DuplicateFoodLogView: View {
  let foodItemLog: FoodItemLog
  let performDismiss: (() -> Void)?
  
  @State private var error: Error?
  @State private var hasCompleted = false
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  
  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  
  var body: some View {
    CardView {
      LargeTitleActionCard("Copy Food Log") {
        VStack(spacing: 16) {
          HStack {
            if let image = foodItemLog.image {
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(foodItemLog.displayName)
              .font(.title2)
              .bold()
              .fontDesign(.rounded)
              .lineLimit(2)
            Spacer(minLength: 0)
          }
          .cardContainer()
          
          // Date Picker
          VStack {
            LabeledContent("Date") {
              DatePicker(
                "",
                selection: $nutritionViewModel.date,
                displayedComponents: .date
              )
              .datePickerStyle(.compact)
              .labelsHidden()
            }

            Divider()

            LabeledContent("Meal") {
              Picker("Meal", selection: $nutritionViewModel.suggestedMeal) {
                ForEach(FoodItemLog.Meal.allCases, id: \.self) { meal in
                  Text(meal.name)
                    .tag(meal)
                }
              }
              .pickerStyle(.menu)
            }
          }
          .cardContainer()
          
          // Duplicate Button
          AsyncButton {
            await duplicateFoodLog()
          } label: {
            Group {
              if hasCompleted {
                Image(systemSymbol: .checkmark)
              } else {
                Text("Copy")
              }
            }
            .bold()
            .horizontallyCentered()
          }
          .buttonStyle(.primary)
          .padding(.top)
          .sensoryFeedback(.success, trigger: hasCompleted)
        }
      }
    }
    .alert(error: $error)
    .animation(.easeInOut, value: hasCompleted)
  }
}

// MARK: - Actions

private extension DuplicateFoodLogView {
  
  func duplicateFoodLog() async {
    do {
      try await nutritionViewModel.duplicate(
        modelContext: modelContext,
        foodItemLog: foodItemLog,
        toDate: nutritionViewModel.date,
        toMeal: nutritionViewModel.suggestedMeal
      )
      
      await MainActor.run {
        SoundPlayer.playLogHealthData()
        hasCompleted = true
      }
      
      await MainActor.run {
        if let performDismiss {
          performDismiss()
        } else {
          dismiss()
        }
      }
    } catch {
      self.error = error
    }
  }
}

// MARK: - Helpers

private extension FoodItemLog {
  var displayName: String {
    if let name = name, name.isNotEmpty {
      return name
    } else if let firstServing = foodItemServings?.first,
              let foodItem = firstServing.foodItem {
      return foodItem.name
    } else {
      return "Food Item"
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      DuplicateFoodLogView(
        foodItemLog: FoodItemLog(
          id: "123",
          name: "Crackers with Cheese",
          date: .now,
          meal: .snack,
          numberOfServings: 2,
          imageData: UIImage(named: "CrackersAndCheese")?.pngData(),
          foodItemServings: [
            FoodItemServing(
              numberOfServings: 2,
              foodItem: .Preview.ritzCrackers
            )
          ]
        ),
        performDismiss: nil
      )
    }
  }
}
