//
//  ActivityLevelEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-14.
//

import SwiftUI

struct ActivityLevelEditCard: View {

    @State private var selectedActivityLevel: ActivityLevelSummary.ActivityLevel?

    @State private var vitalsViewModel = VitalsViewModel.shared

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Activity Level"
        ) {
            healthManager.userReportedActivityLevel = selectedActivityLevel
            return true
        } content: { (_, handleSave) in
            ScrollView {
                VStack {
                    ForEach(ActivityLevelSummary.ActivityLevel.allCases) { activityLevel in
                        ActivityLevelSelectionCell(
                            activityLevel: .sedentary,
                            isRecommended: vitalsViewModel.activityLevelSummary?.details.activityLevel == activityLevel,
                            isSelected: selectedActivityLevel == activityLevel
                        )
                        .onTapGesture {
                            selectedActivityLevel = activityLevel
                        }
                    }
                }
                .padding()
            }
            .groupedBackground()
        }
        .tint(.mutedGreen)
        .onAppear {
            selectedActivityLevel = healthManager.userReportedActivityLevel
        }
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                ActivityLevelEditCard()
            }
        }
    }
    return PreviewView()
}
