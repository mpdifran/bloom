//
//  AddCustomDrinkView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomUI
import AppUI
import CoreHealth

struct AddCustomDrinkView: View {
  let onAdd: (DrinkType) -> Void

  @State private var name = ""
  @State private var category: DrinkCategory = .custom
  @State private var hydrationCoefficient: Double = 0.9
  @State private var hasCaffeine = false
  @State private var caffeinePer250ML: Double = 0
  @State private var isAlcoholic = false
  @State private var abv: Double = 5.0

  @Environment(\.dismiss) private var dismiss

  private var isValid: Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        VStack(spacing: 16) {
          // Name
          nameSection

          // Category
          categorySection

          // Hydration
          hydrationSection

          // Caffeine
          caffeineSection

          // Alcohol
          alcoholSection
        }
        .padding(.horizontal)
      }
      .navigationTitle("Add Custom Drink")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .shelf {
        Button {
          addDrink()
        } label: {
          Text("Add Drink")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(!isValid)
      }
    }
  }

  private var nameSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Name")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      TextField("My Drink", text: $name)
        .textFieldStyle(.plain)
        .padding()
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(.fill)
        }
    }
  }

  private var categorySection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Category")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      Picker("Category", selection: $category) {
        ForEach(DrinkCategory.allCases, id: \.self) { cat in
          Text(cat.displayName).tag(cat)
        }
      }
      .pickerStyle(.segmented)
    }
  }

  private var hydrationSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Hydration Level")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(Int(hydrationCoefficient * 100))%")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.tint)
      }

      Slider(value: $hydrationCoefficient, in: 0.1...1.0, step: 0.05)

      Text("How much this drink contributes to hydration. Water is 100%, caffeinated drinks are typically 80-90%, alcoholic drinks are lower.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .cardContainer()
  }

  private var caffeineSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Toggle("Contains Caffeine", isOn: $hasCaffeine)
        .fontWeight(.medium)

      if hasCaffeine {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Caffeine per 250mL")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(caffeinePer250ML)) mg")
              .font(.subheadline)
              .fontWeight(.semibold)
          }

          Slider(value: $caffeinePer250ML, in: 0...300, step: 5)
        }
      }
    }
    .cardContainer()
  }

  private var alcoholSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Toggle("Contains Alcohol", isOn: $isAlcoholic)
        .fontWeight(.medium)

      if isAlcoholic {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Alcohol by Volume (ABV)")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            Spacer()

            Text("\(String(format: "%.1f", abv))%")
              .font(.subheadline)
              .fontWeight(.semibold)
          }

          Slider(value: $abv, in: 0.5...40, step: 0.5)
        }
      }
    }
    .cardContainer()
    .onChange(of: isAlcoholic) { _, newValue in
      if newValue {
        category = .alcohol
        // Adjust hydration based on ABV
        updateHydrationForAlcohol()
      }
    }
    .onChange(of: abv) { _, _ in
      if isAlcoholic {
        updateHydrationForAlcohol()
      }
    }
  }

  private func updateHydrationForAlcohol() {
    // Approximate hydration reduction based on ABV
    hydrationCoefficient = max(0.1, 1.0 - (abv * 0.06))
  }

  private func addDrink() {
    let drink = DrinkType(
      name: name.trimmingCharacters(in: .whitespacesAndNewlines),
      category: isAlcoholic ? .alcohol : category,
      symbolName: "drop.fill",
      colorHex: "#4A90D9", // Default blue
      hydrationCoefficient: hydrationCoefficient,
      containerShapeType: .glass,
      isCustom: true,
      abv: isAlcoholic ? abv : nil,
      caffeinePer250ML: hasCaffeine ? caffeinePer250ML : nil
    )

    onAdd(drink)
    dismiss()
  }
}

#Preview {
  AddCustomDrinkView { drink in
    print("Added: \(drink.name)")
  }
}
