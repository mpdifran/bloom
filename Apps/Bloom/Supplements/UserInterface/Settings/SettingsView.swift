//
//  SettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI

struct SettingsView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  
  @State private var presentedSheet: AnyView?

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        userSection
        healthGoalsSection
      }
      .padding()
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .sheet($presentedSheet)
  }
}

extension SettingsView {

  var userSection: some View {
    VStack(spacing: 16) {
      Circle()
        .fill(.fill)
        .frame(square: 140)
      TextField("", text: $healthManager.name, prompt: Text("Your Name"))
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 40)
  }

  var healthGoalsSection: some View {
    VStack {
      SectionTitleView("Health Goals")

      HStack {
        SettingsHealthGoalCell(
          image: Image(.logWeightIcon),
          value: healthManager.healthGaolAssociatedValueString(),
          subtitle: healthManager.healthGoalDisplayString()
        )
        .tint(.mutedIndigo)
        .onTapGesture {
          presentedSheet = HealthGoalEditCard().asAny
        }

        Group {
          if let activityLevel = healthManager.userReportedActivityLevel {
            SettingsHealthGoalCell(
              image: Image(systemName: activityLevel.systemImage),
              value: activityLevel.name,
              subtitle: "Activity level"
            )
            .tint(activityLevel.barColor)
          } else {
            SettingsHealthGoalCell(
              image: Image(systemName: "figure"),
              value: "No level set",
              subtitle: "Activity level"
            )
          }
        }
        .onTapGesture {
          presentedSheet = ActivityLevelEditCard().asAny
        }
      }
    }
  }
}

#Preview {
  PreviewSheetPresent {
    SettingsView()
  }
}
