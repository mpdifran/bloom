//
//  ActivityLevelEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-14.
//

import SwiftUI
import CoreHealth

struct ActivityLevelEditCard: View {

  @State private var vitalsViewModel = VitalsViewModel.shared

  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack {
        Text("Activity Level")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)

        ForEach(ActivityLevelSummary.ActivityLevel.allCases) { activityLevel in
          ActivityLevelSelectionCell(
            activityLevel: activityLevel,
            isRecommended: vitalsViewModel.activityLevelSummary?.details.activityLevel == activityLevel,
            isSelected: healthManager.userReportedActivityLevel == activityLevel
          )
          .selectable()
          .onTapGesture {
            healthManager.userReportedActivityLevel = activityLevel
            dismiss()
          }
        }
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .sensoryFeedback(.impact, trigger: healthManager.userReportedActivityLevel)
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .groupedBackground()
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      ActivityLevelEditCard()
    }
  }
}
