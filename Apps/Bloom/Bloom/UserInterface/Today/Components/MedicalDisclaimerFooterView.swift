//
//  MedicalDisclaimerFooterView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import SwiftUI

struct MedicalDisclaimerFooterView: View {
  var body: some View {
    Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .bold()
      .fontDesign(.rounded)
      .multilineTextAlignment(.center)
      .padding(.top)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MedicalDisclaimerFooterView()
    }
  }
}
