//
//  HealthGoalEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SwiftUI
import AppUI
import SFSafeSymbols

struct HealthGoalEditCard: View {

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var presentedSheet: AnyView?
  @State private var saveToggle = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack {
        Text("Health Goal")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)

        healthGoalSection

        if healthManager.healthGoal.isWeightRelated {
          weightSection

          if healthManager.healthGoal.supportsWeightChangeSpeed {
            weightSpeedSection
          }
        }

        Button {
          dismiss()
        } label: {
          Text("Done")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .padding(.top)
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .animation(.easeInOut, value: healthManager.healthGoal)
    .animation(.easeInOut, value: healthManager.weightLossSpeed)
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .tint(.mutedBlue)
    .sheet($presentedSheet)
  }
}

private extension HealthGoalEditCard {

  var healthGoalSection: some View {
    VStack {
      HealthGoalCell(
        title: healthManager.healthGoal.name,
        image: healthManager.healthGoal.image
      )
      .tint(healthManager.healthGoal.color)
      .onTapGesture {
        presentedSheet = HealthGoalPickerView().asAny
      }
    }
  }

  var weightSection: some View {
    HStack {
      Text("Target Weight")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      Text(healthManager.targetWeightQuantity().displayString(for: .pound(), formatter: .oneDecimalPlace))
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
      DisclosureIndicator()
    }
    .cardContainer()
    .selectable()
    .tint(.mutedIndigo)
    .onTapGesture {
      presentedSheet = TargetWeightEditCard().asAny
    }
  }

  var weightSpeedSection: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Speed")
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Spacer()

        Menu {
          ForEach(WeightLossSpeed.allCases) { speed in
            Button(speed.name, systemImage: speed == healthManager.weightLossSpeed ? "checkmark" : "") {
              healthManager.weightLossSpeed = speed
            }
          }
        } label: {
          HStack {
            Text(healthManager.weightLossSpeed.name)
            Image(systemSymbol: .chevronUpChevronDown)
          }
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
        }
      }

      Divider()

      Text(healthManager.weightLossSpeed.weightLossDescription)
        .font(.body)
        .foregroundStyle(.secondary)
        .bold()
        .fontDesign(.rounded)
        .contentTransition(.numericText())
    }
    .cardContainer()
    .selectable()
    .tint(.mutedIndigo)
  }
}

private struct HealthGoalCell: View {
  let title: String
  let image: Image

  var body: some View {
    HStack {
      Text(title)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)

      Spacer()

      image
        .font(.title2)
        .bold()
        .foregroundStyle(.tint)

      DisclosureIndicator()
    }
    .cardContainer()
    .selectable()
  }
}

#Preview {
  PreviewSheetPresent {
    HealthGoalEditCard()
  }
}
