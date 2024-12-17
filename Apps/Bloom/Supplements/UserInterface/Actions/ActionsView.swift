//
//  ActionsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI

struct ActionsView: View {

  @State private var showAllDataView = false
  @State private var presentedCardSheet: AnyView?

  @State private var viewModel = ViewModel()

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack {
        Text("Log")
          .font(.largeTitle)
          .fontDesign(.rounded)
          .bold()
          .padding(.top)

        ActionInstanceCell(image: .logFoodIcon, title: "Food")
          .tint(.mutedGreen)
          .onTapGesture {
            presentedCardSheet = FoodLoggingActionCardView {
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

        ActionInstanceCell(image: .logWaterIcon, title: "Water")
          .tint(.mutedBlue)
          .onTapGesture {
            presentedCardSheet = WaterActionCardView {
              dismiss()
            }.asAny
          }

        ActionInstanceCell(image: .logBowelIcon, title: "Bowel Movement")
          .tint(.brown)
          .onTapGesture {
            presentedCardSheet = BowelMovementActionCardView {
              dismiss()
            }.asAny
          }
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .sheet($presentedCardSheet)
    .onAppear {
      viewModel.observeData()
    }
  }
}

private extension ActionsView {

  func dismissAndRun(_ closure: () -> Void) async {
    dismiss()
    await Delay(500)
    closure()
  }

  func delayShowFoodSearch(for barcode: String) async {
    await Delay(500)

    presentedCardSheet = FoodLoggingActionCardView(initialBarcodeToSearch: barcode).asAny
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
            ActionsView()
          }
      }
  }
  return PreviewView()
}
