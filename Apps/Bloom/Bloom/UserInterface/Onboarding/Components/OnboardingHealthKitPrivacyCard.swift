//
//  OnboardingHealthKitPrivacyCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-30.
//

import SFSafeSymbols
import SwiftUI
import AppUI

struct OnboardingHealthKitPrivacyCard: View {
  let onContinue: () -> Void

  @State private var didContinue = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    CardView {
      LargeTitleActionCard("Personal Data Privacy") {
        VStack {
          Image(systemSymbol: .handRaisedCircleFill)
            .font(.system(size: 100))
            .foregroundStyle(.invertedText, .tint)

          Text("We'll only use your personal data anonymously to provide you insights and goals.")
            .font(.title3)
            .bold()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

          HStack {
            Link(destination: .privacyPolicy) {
              Text("Privacy Policy")
                .bold()
                .foregroundStyle(.tint)
            }
            .frame(minHeight: 44)

            Text("•")

            Link(destination: .emailBloom) {
              Text("Questions? Email Us!")
                .bold()
                .foregroundStyle(.tint)
            }
            .frame(minHeight: 44)
          }

          Button("Continue") {
            dismiss()
            didContinue.toggle()
            onContinue()
          }
          .buttonStyle(.onboarding)
          .padding(.top)
        }
      }
    }
    .fontDesign(.rounded)
    .sensoryFeedback(.selection, trigger: didContinue)
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      OnboardingHealthKitPrivacyCard { }
    }
  }
}
