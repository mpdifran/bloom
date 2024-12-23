//
//  HealthGoalPickerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SwiftUI

struct HealthGoalPickerView: View {

  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack {
        Text("Goals")
          .font(.title)
          .bold()
          .fontDesign(.rounded)
          .padding(.bottom, 20)
        ForEach(HealthGoal.allCases) { goal in
          HealthGoalCell(
            title: goal.name,
            image: goal.image,
            isSelected: healthManager.healthGoal == goal
          )
          .tint(goal.color)
          .onTapGesture {
            healthManager.healthGoal = goal
          }
          .sensoryFeedback(.impact, trigger: healthManager.healthGoal)
        }
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .animation(.easeInOut, value: healthManager.healthGoal)
    .onChange(of: healthManager.healthGoal) { oldValue, newValue in
      dismiss()
    }
  }
}

private struct HealthGoalCell: View {
  let title: String
  let image: Image
  let isSelected: Bool

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
    }
    .selectable()
    .cardContainer(
        fill: isSelected ? AnyShapeStyle(.tint.tertiary) : AnyShapeStyle(.background),
        stroke: isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear)
    )
  }
}

#Preview {
  HealthGoalPickerView()
}
