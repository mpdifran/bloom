//
//  AIFoodTextGenerationView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-06.
//

import SwiftUI
import AppUI
import CoreHealth

struct AIFoodTextGenerationView: View {

  @State private var viewModel = ViewModel()

  @State private var text = ""
  @State private var didSearchToggle = false
  @State private var isSwipingItem = false
  @State private var saveComplete = false
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @FocusState private var isFocused: Bool
  @FocusState private var focusedIndex: Int?

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isEstimating {
          VStack {
            Spacer()
            ProgressView()
              .progressViewStyle(.circular)
            Spacer()
          }
          .horizontallyCentered()
        } else {
          ScrollView {
            VStack(spacing: 20) {
              servingsSection
            }
            .horizontallyCentered()
            .padding()
          }
        }
      }
      .groupedBackground()
      .scrollDisabled(isSwipingItem)
      .shelf(backgroundFill: .background.secondary) {
        if focusedIndex != nil {
          textEditorButton
        } else {
          textField
          if (viewModel.servings.isNotEmpty || viewModel.suggestedServings.isNotEmpty) && !isFocused {
            saveButton
          }
        }
      }
      .navigationTitle("Text")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .alert(error: $error)
    .sheet($presentedSheet)
    .sensoryFeedback(.success, trigger: saveComplete)
    .animation(.default, value: viewModel.servings)
    .animation(.default, value: viewModel.suggestedServings)
    .animation(.default, value: viewModel.isEstimating)
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      isFocused = true
    }
  }
}

private extension AIFoodTextGenerationView {

  var servingsSection: some View {
    VStack {
      if viewModel.servings.isNotEmpty {
        SectionTitleView("\(viewModel.servings.count) \(viewModel.servings.count == 1 ? "Food Item" : "Food Items")")
          .padding(.horizontal)
        ForEachEnumerated(viewModel.servings) { (index, serving) in
          Swipeable(
            isSwipingItem: $isSwipingItem,
            actions: [
              SwipeAction(
                title: "Delete",
                symbol: .trash,
                tint: .mutedRed
              ) {
                viewModel.suggestedServings.insert(serving, at: 0)
                viewModel.servings.remove(at: index)
              }
            ]
          ) {
            Group {
              if viewModel.servings.count > index { // Fixes dumb bug where viewModel.servings is empty but we try and load a cell.
                AIScanFoodItemCell(foodItemServing: $viewModel.servings[index])
                  .focused($focusedIndex, equals: index)
                  .transition(.blurReplace)
                  .onTapGesture {
                    presentedSheet = FoodItemDetailsView(
                      foodItem: serving.foodItem,
                      existingFoodItemLog: nil,
                      mode: .viewOnly
                    ).asAny
                  }
              }
            }
          }
        }
      }

      if viewModel.suggestedServings.isNotEmpty {
        SectionTitleView("Suggestions")
          .padding(.horizontal)
        ForEachEnumerated(viewModel.suggestedServings) { (index, serving) in
          if viewModel.suggestedServings.count > index { // Fixes dumb bug where viewModel.servings is empty but we try and load a cell.
            AIScanFoodItemSuggetionCell(foodItemServing: serving) {
              viewModel.servings.append(serving)
              viewModel.suggestedServings.remove(at: index)
            }
            .transition(.blurReplace)
            .onTapGesture {
              presentedSheet = FoodItemDetailsView(
                foodItem: serving.foodItem,
                existingFoodItemLog: nil,
                mode: .viewOnly
              ).asAny
            }
          }
        }
      }
    }
  }

  var textField: some View {
    HStack {
      Image(systemSymbol: .quoteBubble)
        .foregroundStyle(.tint)
        .font(.title3)

      TextField(
        "",
        text: $text,
        prompt: Text("Describe your meal")
      )
      .focused($isFocused)
      .scrollDismissesKeyboard(.interactively)

      if text.isNotEmpty {
        Button {
          text = ""
          viewModel.resetResults()
        } label: {
          Image(systemSymbol: .xmarkCircleFill)
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.white, .gray)
        }
        .buttonStyle(.plain)
        .transition(.scale)
      } else if isFocused {
        Button {
          isFocused = false
        } label: {
          Image(systemSymbol: .chevronDownCircleFill)
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.white, .gray)
        }
        .buttonStyle(.plain)
        .transition(.scale)
      }
    }
    .submitLabel(.search)
    .sensoryFeedback(.impact, trigger: didSearchToggle)
    .onSubmit {
      performSearch()
    }
    .selectAllTextOnBeginEditing()
    .cardContainer()
  }

  var textEditorButton: some View {
    Button {
      focusedIndex = nil
    } label: {
      Text("Done")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  var saveButton: some View {
    AsyncButton {
      try await save()
      dismiss()
    } label: {
      Group {
        if viewModel.servings.isNotEmpty {
          Text("Log \(viewModel.servings.count) \(viewModel.servings.count == 1 ? "Food Item" : "Food Items")")
        } else {
          Text("Log")
        }
      }
      .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .disabled(viewModel.servings.isEmpty)
  }
}

private extension AIFoodTextGenerationView {

  func performSearch() {
    isFocused = false
    ThrowingUserTask(error: $error) {
      try await viewModel.estimateFood(for: text)
    }
  }

  func save() async throws {
    try await nutritionViewModel.log(
      modelContext: modelContext,
      name: viewModel.foodName ?? "My Meal",
      imageData: nil,
      numberOfServings: 1,
      foodItemServings: viewModel.servings,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal
    )

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview {
  PreviewEnvironment {
    AIFoodTextGenerationView()
  }
}
