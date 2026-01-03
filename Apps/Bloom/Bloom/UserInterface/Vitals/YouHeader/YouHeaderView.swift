//
//  YouHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-02.
//

import SwiftUI

struct YouHeaderView: View {
  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared

  var body: some View {
    HStack {
      profileGaugeView

      VStack(alignment: .leading) {
        Text("Mark")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)
        Text("Bio Age: 32")
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        if let summary = biologicalAgeViewModel.lastCalculatedResponse?.summary {
          Text(summary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(3)
          Text("Learn More")
            .font(.subheadline)
            .foregroundStyle(.tint)
        }
      }

      Spacer(minLength: 0)
    }
  }
}

private extension YouHeaderView {

  var profileGaugeView: some View {
    BiologicalAgeMeter(
      biologicalAge: biologicalAgeViewModel.currentBiologicalAge,
      centerContentKind: .profileImage
    )
    .frame(square: 150)
  }
}

#Preview {
  YouHeaderView()
}
