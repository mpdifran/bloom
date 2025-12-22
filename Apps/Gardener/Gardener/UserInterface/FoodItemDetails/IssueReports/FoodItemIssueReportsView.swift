//
//  FoodItemIssueReportsView.swift
//  Gardener
//
//  Created by Claude on 2025-12-22.
//

import AdminBloomModel
import SwiftUI

struct FoodItemIssueReportsView: View {
  @ObservedObject var viewModel: FoodItemDetailViewModel
  let onDismiss: () -> Void

  @State private var currentReportIndex = 0
  @State private var isProcessing = false
  @State private var errorMessage: String?
  @State private var selectedFields: Set<String> = []

  private var currentReport: AdminFoodItemIssueReport? {
    guard currentReportIndex < viewModel.issueReports.count else { return nil }
    return viewModel.issueReports[currentReportIndex]
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        if viewModel.issueReports.isEmpty {
          ContentUnavailableView(
            "No Issue Reports",
            systemImage: "checkmark.circle",
            description: Text("There are no pending issue reports for this food item.")
          )
        } else if let report = currentReport {
          reportNavigationHeader

          Divider()

          userInfoSection(report)

          Divider()

          if let errorMessage {
            Text(errorMessage)
              .foregroundStyle(.red)
              .padding()
              .background(Color.red.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }

          if reportHasAnyChanges(report) {
            ScrollView {
              comparisonSection(report)
            }
          } else {
            ContentUnavailableView(
              "No Changes",
              systemImage: "checkmark.circle",
              description: Text("This report matches the current food item data.")
            )
            .horizontallyCentered()
          }
        }
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            onDismiss()
          }
        }

        if currentReport != nil {
          ToolbarItem(placement: .destructiveAction) {
            Button("Discard", role: .destructive) {
              Task { await discardReport() }
            }
            .disabled(isProcessing)
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Apply Selected") {
              Task { await applyReport() }
            }
            .disabled(isProcessing || selectedFields.isEmpty)
          }
        }
      }
      .disabled(isProcessing)
      .overlay {
        if isProcessing {
          ZStack {
            Color.black.opacity(0.3)
            ProgressView("Processing...")
              .padding()
              .background(Color.gray.opacity(0.9))
              .clipShape(RoundedRectangle(cornerRadius: 10))
          }
        }
      }
    }
    .frame(minWidth: 700, minHeight: 600)
    .onChange(of: currentReportIndex) { _, _ in
      initializeSelectedFields()
    }
    .onAppear {
      initializeSelectedFields()
    }
  }

  private var reportNavigationHeader: some View {
    HStack {
      Button {
        if currentReportIndex > 0 {
          currentReportIndex -= 1
        }
      } label: {
        Image(systemName: "chevron.left")
      }
      .disabled(currentReportIndex == 0)

      Spacer()

      Text("Report \(currentReportIndex + 1) of \(viewModel.issueReports.count)")
        .font(.headline)

      Spacer()

      Button {
        if currentReportIndex < viewModel.issueReports.count - 1 {
          currentReportIndex += 1
        }
      } label: {
        Image(systemName: "chevron.right")
      }
      .disabled(currentReportIndex >= viewModel.issueReports.count - 1)
    }
    .padding(.horizontal)
  }

  private func userInfoSection(_ report: AdminFoodItemIssueReport) -> some View {
    HStack {
      Image(systemName: "person.circle.fill")
        .font(.title2)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading) {
        Text("Submitted by")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(report.userName ?? "Anonymous User")
          .font(.headline)
      }

      Spacer()

      if let createdAt = report.createdAt {
        Text(createdAt.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal)
  }

  private func comparisonSection(_ report: AdminFoodItemIssueReport) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      // Basic Information
      if hasChanges(in: report, for: ["name", "brandName", "flavour"]) {
        Text("Basic Information")
          .font(.headline)

        if let suggestedName = report.name, !suggestedName.isEmpty, suggestedName != viewModel.foodItem.name {
          IssueReportComparisonRow(
            label: "Name",
            currentValue: viewModel.foodItem.name ?? "—",
            suggestedValue: suggestedName,
            isSelected: binding(for: "name")
          )
        }

        if let suggestedBrand = report.brandName, !suggestedBrand.isEmpty, suggestedBrand != viewModel.foodItem.brandName {
          IssueReportComparisonRow(
            label: "Brand Name",
            currentValue: viewModel.foodItem.brandName ?? "—",
            suggestedValue: suggestedBrand,
            isSelected: binding(for: "brandName")
          )
        }

        if let suggestedFlavour = report.flavour, !suggestedFlavour.isEmpty, suggestedFlavour != viewModel.foodItem.flavour {
          IssueReportComparisonRow(
            label: "Flavour",
            currentValue: viewModel.foodItem.flavour ?? "—",
            suggestedValue: suggestedFlavour,
            isSelected: binding(for: "flavour")
          )
        }

        Divider()
      }

      // Serving Information
      if hasChanges(in: report, for: ["servingName", "servingValue", "servingUnit"]) {
        Text("Serving Information")
          .font(.headline)

        if let suggestedServingName = report.servingName, !suggestedServingName.isEmpty, suggestedServingName != viewModel.foodItem.servingName {
          IssueReportComparisonRow(
            label: "Serving Name",
            currentValue: viewModel.foodItem.servingName ?? "—",
            suggestedValue: suggestedServingName,
            isSelected: binding(for: "servingName")
          )
        }

        if let suggestedServingValue = report.servingValue, suggestedServingValue != viewModel.foodItem.servingValue {
          IssueReportComparisonRow(
            label: "Serving Value",
            currentValue: viewModel.foodItem.servingValue.map { "\($0)" } ?? "—",
            suggestedValue: "\(suggestedServingValue)",
            isSelected: binding(for: "servingValue")
          )
        }

        if let suggestedServingUnit = report.servingUnit, !suggestedServingUnit.isEmpty, suggestedServingUnit != viewModel.foodItem.servingUnit {
          IssueReportComparisonRow(
            label: "Serving Unit",
            currentValue: viewModel.foodItem.servingUnit ?? "—",
            suggestedValue: suggestedServingUnit,
            isSelected: binding(for: "servingUnit")
          )
        }

        Divider()
      }

      // Macros
      if hasChanges(in: report, for: ["calories", "protein", "carbohydrates", "fat"]) {
        Text("Macronutrients")
          .font(.headline)

        nutritionRow(report, field: "calories", label: "Calories", unit: "kcal")
        nutritionRow(report, field: "protein", label: "Protein", unit: "g")
        nutritionRow(report, field: "carbohydrates", label: "Carbohydrates", unit: "g")
        nutritionRow(report, field: "fat", label: "Fat", unit: "g")

        Divider()
      }

      // Fat Details
      if hasChanges(in: report, for: ["saturatedFat", "transFat", "polyunsaturatedFat", "monounsaturatedFat"]) {
        Text("Fat Details")
          .font(.headline)

        nutritionRow(report, field: "saturatedFat", label: "Saturated Fat", unit: "g")
        nutritionRow(report, field: "transFat", label: "Trans Fat", unit: "g")
        nutritionRow(report, field: "polyunsaturatedFat", label: "Polyunsaturated Fat", unit: "g")
        nutritionRow(report, field: "monounsaturatedFat", label: "Monounsaturated Fat", unit: "g")

        Divider()
      }

      // Carb Details
      if hasChanges(in: report, for: ["fiber", "sugar"]) {
        Text("Carbohydrate Details")
          .font(.headline)

        nutritionRow(report, field: "fiber", label: "Fiber", unit: "g")
        nutritionRow(report, field: "sugar", label: "Sugar", unit: "g")

        Divider()
      }

      // Minerals
      if hasChanges(in: report, for: ["cholesterol", "sodium", "calcium", "iron", "potassium", "magnesium", "zinc"]) {
        Text("Minerals")
          .font(.headline)

        nutritionRow(report, field: "cholesterol", label: "Cholesterol", unit: "mg")
        nutritionRow(report, field: "sodium", label: "Sodium", unit: "mg")
        nutritionRow(report, field: "calcium", label: "Calcium", unit: "mg")
        nutritionRow(report, field: "iron", label: "Iron", unit: "mg")
        nutritionRow(report, field: "potassium", label: "Potassium", unit: "mg")
        nutritionRow(report, field: "magnesium", label: "Magnesium", unit: "mg")
        nutritionRow(report, field: "zinc", label: "Zinc", unit: "mg")

        Divider()
      }

      // Vitamins
      if hasChanges(in: report, for: ["vitaminA", "vitaminB6", "vitaminB12", "vitaminC", "vitaminD", "vitaminE"]) {
        Text("Vitamins")
          .font(.headline)

        nutritionRow(report, field: "vitaminA", label: "Vitamin A", unit: "mg")
        nutritionRow(report, field: "vitaminB6", label: "Vitamin B6", unit: "mg")
        nutritionRow(report, field: "vitaminB12", label: "Vitamin B12", unit: "mg")
        nutritionRow(report, field: "vitaminC", label: "Vitamin C", unit: "mg")
        nutritionRow(report, field: "vitaminD", label: "Vitamin D", unit: "mg")
        nutritionRow(report, field: "vitaminE", label: "Vitamin E", unit: "mg")

        Divider()
      }

      // Images
      if report.nutritionLabelImage != nil || report.packagingImage != nil {
        Text("Images")
          .font(.headline)

        if let suggestedImage = report.nutritionLabelImage {
          IssueReportImageComparisonRow(
            label: "Nutrition Label",
            currentImageURL: viewModel.foodItem.nutritionLabelImage,
            suggestedImageURL: suggestedImage,
            isSelected: binding(for: "nutritionLabelImage")
          )
        }

        if let suggestedImage = report.packagingImage {
          IssueReportImageComparisonRow(
            label: "Packaging",
            currentImageURL: viewModel.foodItem.packagingImage,
            suggestedImageURL: suggestedImage,
            isSelected: binding(for: "packagingImage")
          )
        }

        Divider()
      }

      // Ingredients
      if let suggestedIngredients = report.ingredients, !suggestedIngredients.isEmpty, suggestedIngredients != viewModel.foodItem.ingredients {
        Text("Ingredients")
          .font(.headline)

        IssueReportComparisonRow(
          label: "Ingredients",
          currentValue: viewModel.foodItem.ingredients ?? "—",
          suggestedValue: suggestedIngredients,
          isSelected: binding(for: "ingredients")
        )

        Divider()
      }

      // Notes from user
      if let notes = report.notes, !notes.isEmpty {
        Text("User Notes")
          .font(.headline)

        Text(notes)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private func nutritionRow(_ report: AdminFoodItemIssueReport, field: String, label: String, unit: String) -> some View {
    let suggestedValue = nutritionValue(from: report, field: field)
    let currentValue = nutritionValue(from: viewModel.foodItem, field: field)

    if let suggested = suggestedValue, suggested != currentValue {
      IssueReportComparisonRow(
        label: label,
        currentValue: currentValue.map { "\($0) \(unit)" } ?? "—",
        suggestedValue: "\(suggested) \(unit)",
        isSelected: binding(for: field)
      )
    }
  }

  private func nutritionValue(from report: AdminFoodItemIssueReport, field: String) -> Double? {
    switch field {
    case "calories": return report.calories
    case "protein": return report.protein
    case "carbohydrates": return report.carbohydrates
    case "fat": return report.fat
    case "saturatedFat": return report.saturatedFat
    case "transFat": return report.transFat
    case "polyunsaturatedFat": return report.polyunsaturatedFat
    case "monounsaturatedFat": return report.monounsaturatedFat
    case "fiber": return report.fiber
    case "sugar": return report.sugar
    case "cholesterol": return report.cholesterol
    case "sodium": return report.sodium
    case "calcium": return report.calcium
    case "iron": return report.iron
    case "potassium": return report.potassium
    case "magnesium": return report.magnesium
    case "zinc": return report.zinc
    case "vitaminA": return report.vitaminA
    case "vitaminB6": return report.vitaminB6
    case "vitaminB12": return report.vitaminB12
    case "vitaminC": return report.vitaminC
    case "vitaminD": return report.vitaminD
    case "vitaminE": return report.vitaminE
    default: return nil
    }
  }

  private func nutritionValue(from item: AdminFoodItemRecord, field: String) -> Double? {
    switch field {
    case "calories": return item.calories
    case "protein": return item.protein
    case "carbohydrates": return item.carbohydrates
    case "fat": return item.fat
    case "saturatedFat": return item.saturatedFat
    case "transFat": return item.transFat
    case "polyunsaturatedFat": return item.polyunsaturatedFat
    case "monounsaturatedFat": return item.monounsaturatedFat
    case "fiber": return item.fiber
    case "sugar": return item.sugar
    case "cholesterol": return item.cholesterol
    case "sodium": return item.sodium
    case "calcium": return item.calcium
    case "iron": return item.iron
    case "potassium": return item.potassium
    case "magnesium": return item.magnesium
    case "zinc": return item.zinc
    case "vitaminA": return item.vitaminA
    case "vitaminB6": return item.vitaminB6
    case "vitaminB12": return item.vitaminB12
    case "vitaminC": return item.vitaminC
    case "vitaminD": return item.vitaminD
    case "vitaminE": return item.vitaminE
    default: return nil
    }
  }

  private func reportHasAnyChanges(_ report: AdminFoodItemIssueReport) -> Bool {
    // Check all field categories
    let allFieldGroups = [
      ["name", "brandName", "flavour"],
      ["servingName", "servingValue", "servingUnit"],
      ["calories", "protein", "carbohydrates", "fat"],
      ["saturatedFat", "transFat", "polyunsaturatedFat", "monounsaturatedFat"],
      ["fiber", "sugar"],
      ["cholesterol", "sodium", "calcium", "iron", "potassium", "magnesium", "zinc"],
      ["vitaminA", "vitaminB6", "vitaminB12", "vitaminC", "vitaminD", "vitaminE"]
    ]

    for fields in allFieldGroups {
      if hasChanges(in: report, for: fields) { return true }
    }

    // Check ingredients (with empty string handling)
    if let ingredients = report.ingredients, !ingredients.isEmpty, ingredients != viewModel.foodItem.ingredients {
      return true
    }

    // Check images
    if report.nutritionLabelImage != nil || report.packagingImage != nil {
      return true
    }

    return false
  }

  private func hasChanges(in report: AdminFoodItemIssueReport, for fields: [String]) -> Bool {
    for field in fields {
      switch field {
      case "name": if let v = report.name, !v.isEmpty, v != viewModel.foodItem.name { return true }
      case "brandName": if let v = report.brandName, !v.isEmpty, v != viewModel.foodItem.brandName { return true }
      case "flavour": if let v = report.flavour, !v.isEmpty, v != viewModel.foodItem.flavour { return true }
      case "servingName": if let v = report.servingName, !v.isEmpty, v != viewModel.foodItem.servingName { return true }
      case "servingValue": if report.servingValue != nil && report.servingValue != viewModel.foodItem.servingValue { return true }
      case "servingUnit": if let v = report.servingUnit, !v.isEmpty, v != viewModel.foodItem.servingUnit { return true }
      default:
        let suggestedValue = nutritionValue(from: report, field: field)
        let currentValue = nutritionValue(from: viewModel.foodItem, field: field)
        if suggestedValue != nil && suggestedValue != currentValue { return true }
      }
    }
    return false
  }

  private func binding(for field: String) -> Binding<Bool> {
    Binding(
      get: { selectedFields.contains(field) },
      set: { isSelected in
        if isSelected {
          selectedFields.insert(field)
        } else {
          selectedFields.remove(field)
        }
      }
    )
  }

  private func initializeSelectedFields() {
    // Initialize all changed fields as selected by default
    selectedFields.removeAll()

    guard let report = currentReport else { return }

    let allFields = [
      "name", "brandName", "flavour", "ingredients",
      "servingName", "servingValue", "servingUnit",
      "calories", "protein", "carbohydrates", "fat",
      "saturatedFat", "transFat", "polyunsaturatedFat", "monounsaturatedFat",
      "fiber", "sugar", "cholesterol", "sodium", "calcium", "iron",
      "potassium", "magnesium", "zinc",
      "vitaminA", "vitaminB6", "vitaminB12", "vitaminC", "vitaminD", "vitaminE",
      "nutritionLabelImage", "packagingImage"
    ]

    for field in allFields {
      if hasChanges(in: report, for: [field]) {
        selectedFields.insert(field)
      }
    }

    // Also check for images
    if report.nutritionLabelImage != nil {
      selectedFields.insert("nutritionLabelImage")
    }
    if report.packagingImage != nil {
      selectedFields.insert("packagingImage")
    }
  }

  private func applyReport() async {
    guard let report = currentReport else { return }

    isProcessing = true
    errorMessage = nil

    do {
      try await viewModel.applyIssueReport(report, fieldsToApply: Array(selectedFields))

      // Move to next report or dismiss if none left
      if viewModel.issueReports.isEmpty {
        onDismiss()
      } else if currentReportIndex >= viewModel.issueReports.count {
        currentReportIndex = max(0, viewModel.issueReports.count - 1)
      }
      initializeSelectedFields()
    } catch {
      errorMessage = "Failed to apply report: \(error.localizedDescription)"
    }

    isProcessing = false
  }

  private func discardReport() async {
    guard let report = currentReport else { return }

    isProcessing = true
    errorMessage = nil

    do {
      try await viewModel.discardIssueReport(report)

      // Move to next report or dismiss if none left
      if viewModel.issueReports.isEmpty {
        onDismiss()
      } else if currentReportIndex >= viewModel.issueReports.count {
        currentReportIndex = max(0, viewModel.issueReports.count - 1)
      }
      initializeSelectedFields()
    } catch {
      errorMessage = "Failed to discard report: \(error.localizedDescription)"
    }

    isProcessing = false
  }
}
