//
//  AIFoodScannerExplanationView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-07.
//

import SwiftUI

struct AIFoodScannerExplanationView: View {

  let onContinue: () -> Void

  @State private var showSoupReticule = false
  @State private var showPackageReticule = false
  @State private var sensoryFeedbackToggle = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    CardView {
      VStack {
        Text("Quickly scan\nfood & barcodes")
          .font(.title)
          .fontDesign(.rounded)
          .bold()
          .multilineTextAlignment(.center)

        HStack {
          Spacer()
          Image(.soup)
            .overlay {
              if showSoupReticule {
                CameraReticuleShapeView(lineWidth: 6, cornerRadius: 15)
              }
            }
          Spacer()
          Image(.barcodePackaging)
            .overlay {
              if showPackageReticule {
                CameraReticuleShapeView(lineWidth: 6, cornerRadius: 5)
                  .frame(width: 45, height: 40)
                  .padding(.bottom, 12)
                  .padding(.trailing, 12)
                  .zStackAlignment(.bottomTrailing)
              }
            }

          Spacer()
        }
        .padding(.vertical)

        Button {
          dismiss()
          onContinue()
        } label: {
          Text("Let's do it!")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
      .padding()
    }
    .animation(.easeOut(duration: 1), value: showSoupReticule)
    .animation(.easeOut(duration: 1), value: showPackageReticule)
    .sensoryFeedback(.impact, trigger: sensoryFeedbackToggle)
    .task {
      await animateReticules()
    }
  }
}

private extension AIFoodScannerExplanationView {

  func animateReticules() async {
    await Delay(300)

    await MainActor.run {
      showSoupReticule = true
      sensoryFeedbackToggle.toggle()
    }

    await Delay(1000)

    await MainActor.run {
      showPackageReticule = true
      sensoryFeedbackToggle.toggle()
    }
  }
}

#Preview {
  PreviewSheetPresent {
    AIFoodScannerExplanationView() { }
  }
}
