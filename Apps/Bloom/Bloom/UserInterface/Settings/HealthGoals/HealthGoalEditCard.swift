//
//  HealthGoalEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SwiftUI
import AppUI
import SFSafeSymbols
import CoreHealth

struct HealthGoalEditCard: View {

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var presentedSheet: AnyView?
  @State private var saveToggle = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack {
        Text("Health Focus")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)

        focusTextField

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
    .animation(.easeInOut, value: healthManager.focus)
    .animation(.easeInOut, value: healthManager.weightLossSpeed)
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .tint(.mutedBlue)
    .sheet($presentedSheet)
  }
}

private extension HealthGoalEditCard {

  var focusTextField: some View {
    TextField(
      "",
      text: $healthManager.focus,
      prompt: Text("Describe your health focus"),
      axis: .vertical
    )
    .font(.title2)
    .fontDesign(.rounded)
    .bold()
    .multilineTextAlignment(.center)
    .cardContainer()
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
