//
//  ActionsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI

struct ActionsView: View {
  @Binding var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    InsetCardView(background: .background.secondary) {
      LargeTitleActionCard("Log") {
        VStack {
          ActionInstanceCell(image: .logFoodIcon, title: "Food")
            .tint(.mutedGreen)
            .onTapGesture {
              dismissAndRun {
                presentedSheet = FoodLoggingActionCardView().asAny
              }
            }

          ActionInstanceCell(image: .logWaterIcon, title: "Water")
            .tint(.mutedBlue)
            .onTapGesture {
              dismissAndRun {
                presentedSheet = WaterActionCardView().asAny
              }
            }

          ActionInstanceCell(image: .logBowelIcon, title: "Bowel Movement")
            .tint(.brown)
            .onTapGesture {
              dismissAndRun {
                presentedSheet = BowelMovementActionCardView().asAny
              }
            }

          ActionInstanceCell(image: .logWeightIcon, title: "Weight")
            .tint(.mutedIndigo)
            .onTapGesture {
              dismissAndRun {
                presentedSheet = BodyWeightActionCardView().asAny
              }
            }

          ActionInstanceCell(image: .logBloodPressureIcon, title: "Blood Pressure")
            .tint(.mutedRed)
            .onTapGesture {
              dismissAndRun {
                presentedSheet = BloodPressureActionCardView().asAny
              }
            }
        }
      }
    }
  }
}

private extension ActionsView {

  func dismissAndRun(_ closure: @escaping () -> Void) {
    Task {
      dismiss()
      await Delay(200)
      MainTask {
        closure()
      }
    }
  }
}

#Preview {
  struct PreviewView: View {
    @State private var presentedSheet: AnyView?

    var body: some View {
      Button {
        presentedSheet = ActionsView(presentedSheet: $presentedSheet).asAny
      } label: {
        Text("Show Sheet")
      }
      .sheet($presentedSheet)
      .onAppear {
        presentedSheet = ActionsView(presentedSheet: $presentedSheet).asAny
      }
    }
  }
  return PreviewView()
}
