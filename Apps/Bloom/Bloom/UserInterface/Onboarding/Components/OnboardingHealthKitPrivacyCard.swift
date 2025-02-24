//
//  OnboardingHealthKitPrivacyCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-30.
//

import SwiftUI
import AppUI

struct OnboardingHealthKitPrivacyCard: View {
  let onContinue: () -> Void

  @State private var didContinue = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 25) {
      Text("Health Data Privacy")
        .font(.title)
        .bold()

      Image(systemName: "hand.raised.circle.fill")
        .font(.system(size: 100))
        .foregroundStyle(.invertedText, .tint)

      Text("Your health data is stored securely on your device. We don’t collect or share any of your health information — only you have access to it.")
        .font(.title3)
        .bold()
        .multilineTextAlignment(.center)

      Link(destination: .privacyPolicy) {
        HStack {
          Text("Privacy Policy")
          Image(systemName: "arrow.up.right.square.fill")
        }
        .bold()
        .foregroundStyle(.mutedBlue)
      }

      Button("Continue") {
        dismiss()
        didContinue.toggle()
        onContinue()
      }
      .buttonStyle(.onboarding)
      .padding(.top)
    }
    .fontDesign(.rounded)
    .sensoryFeedback(.selection, trigger: didContinue)
    .padding()
    .presentationCornerRadius(50)
    .presentationDetentSelfSizing()
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
        OnboardingHealthKitPrivacyCard { }
      }
    }
  }
  return PreviewView()
}
