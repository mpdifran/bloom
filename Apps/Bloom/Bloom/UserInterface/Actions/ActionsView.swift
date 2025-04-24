//
//  ActionsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI

struct ActionsView: View {

  @State private var presentedCardSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    CardView {
      LargeTitleActionCard("Actions") {
        VStack {
          ActionInstanceCell(image: .logFoodIcon, title: "Food")
            .tint(.mutedGreen)
            .onTapGesture {
              EntitledPresent(presentedSheet: $presentedCardSheet) {
                FoodLoggingActionCardView {
                  dismiss()
                }
              }
            }

          ActionInstanceCell(image: .logWaterIcon, title: "Water")
            .tint(.mutedBlue)
            .onTapGesture {
              presentedCardSheet = WaterActionCardView {
                dismiss()
              }.asAny
            }

          if HealthManager.shared.sex() == .female {
            ActionInstanceCell(image: .logPeriodIcon, title: "Period")
              .tint(.mutedPink)
              .onTapGesture {
                presentedCardSheet = CycleTrackingActionCardView {
                  dismiss()
                }.asAny
              }
          }

          ActionInstanceCell(image: .logBowelIcon, title: "Bowel Movement")
            .tint(.brown)
            .onTapGesture {
              presentedCardSheet = BowelMovementActionCardView {
                dismiss()
              }.asAny
            }

          ActionInstanceCell(image: .logWeightIcon, title: "Weight")
            .tint(.mutedIndigo)
            .onTapGesture {
              presentedCardSheet = BodyWeightActionCardView {
                dismiss()
              }.asAny
            }

          ActionInstanceCell(image: .logBloodPressureIcon, title: "Blood Pressure")
            .tint(.mutedRed)
            .onTapGesture {
              presentedCardSheet = BloodPressureActionCardView {
                dismiss()
              }.asAny
            }
        }
      }
    }
    .sheet($presentedCardSheet)
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      ActionsView()
    }
  }
}
