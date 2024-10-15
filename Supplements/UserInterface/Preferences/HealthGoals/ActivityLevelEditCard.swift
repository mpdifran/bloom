//
//  ActivityLevelEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-14.
//

import SwiftUI

struct ActivityLevelEditCard: View {

    @State private var activityLevel: ActivityLevelSummary.ActivityLevel?

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Activity Level"
        ) {
            healthManager.userReportedActivityLevel = activityLevel
            return true
        } content: { (_, handleSave) in
            ScrollView {
                VStack {
                    ActivityLevelSelectionCell(
                        isSelected: activityLevel == .sedentary,
                        title: "Sedentary",
                        subtitle: "Little to no exercise",
                        systemImage: "figure.stand"
                    )
                    .tint(.vitalWarning)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activityLevel = .sedentary
                    }

                    ActivityLevelSelectionCell(
                        isSelected: activityLevel == .light,
                        title: "Light",
                        subtitle: "Exercise 1 to 3 times a week",
                        systemImage: "figure.run"
                    )
                    .tint(.vitalGood)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activityLevel = .light
                    }

                    ActivityLevelSelectionCell(
                        isSelected: activityLevel == .high,
                        title: "High",
                        subtitle: "Exercise 4 to 7 times a week",
                        systemImage: "figure.tennis"
                    )
                    .tint(.vitalGreat)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activityLevel = .high
                    }
                }
                .padding()
            }
            .groupedBackground()
        }
        .tint(.mutedGreen)
        .onAppear {
            activityLevel = healthManager.userReportedActivityLevel
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
