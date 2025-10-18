//
//  LogMealWidgetView.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import SwiftUI
import WidgetKit
import SFSafeSymbols
import AppFoundations
import AppIntents
import CoreHealth
internal import BloomFoundation

struct LogMealToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      Image(systemSymbol: configuration.isOn ? .checkmark : .plus)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.regular)
  }
}

struct LogMealWidgetView: View {
  let entry: LogMealEntry
  @Environment(\.redactionReasons) var redactionReasons
  @Environment(\.widgetFamily) var widgetFamily

  var body: some View {
    VStack(alignment: .leading) {

      HStack(alignment: .top) {
        Text(entry.displayName)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()

        Image(.logFoodIcon)
          .foregroundStyle(.tint)
      }

      // Calories and macro bar
      if let caloriesText = entry.caloriesText {
        if widgetFamily == .systemSmall {
          MacroDistributionBar(
            proteinGrams: entry.proteinGrams,
            carbsGrams: entry.carbsGrams,
            fatGrams: entry.fatGrams
          )

          Text(caloriesText)
            .font(.caption)
            .bold()
            .fontDesign(.rounded)
        } else {
          HStack {
            MacroDistributionBar(
              proteinGrams: entry.proteinGrams,
              carbsGrams: entry.carbsGrams,
              fatGrams: entry.fatGrams
            )
            .frame(maxWidth: 100)

            Text(caloriesText)
              .font(.caption)
              .bold()
              .fontDesign(.rounded)
          }
        }
      } else if redactionReasons.isEmpty {
        Text("Edit widget to add food items")
          .font(.caption)
          .bold()
          .fontDesign(.rounded)
      }

      // Food item names (for multi-item display, medium+ only)
      if let foodItemNames = entry.foodItemNames, widgetFamily != .systemSmall {
        Text(foodItemNames)
          .font(.subheadline)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      Spacer()

      HStack {
        Group {
          if widgetFamily == .systemSmall {
            VStack(alignment: .leading) {
              Text(entry.servingsDescription)
              Text(entry.mealName)
            }
          } else {
            Text("\(entry.servingsDescription) • \(entry.mealName)")
          }
        }
        .font(.caption)
        .bold()
        .foregroundStyle(.secondary)

        Spacer()

        Toggle(isOn: false, intent: entry.intent) {
          EmptyView()
        }
        .toggleStyle(LogMealToggleStyle())
      }
    }
    .unredacted()
    .tint(.mutedGreen)
  }
}
