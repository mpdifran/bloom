//
//  YouHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-02.
//

import SwiftUI
import CoreHealth

struct YouHeaderView: View {
  @ObservedObject private var healthManager = HealthManager.shared
  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared

  var body: some View {
    HStack {
      profileGaugeView

      VStack(alignment: .leading) {
        Text(healthManager.name.isEmpty ? "User" : healthManager.name)
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)
        if let bioAge = biologicalAgeViewModel.currentBiologicalAge {
          NavigationLink {
            BiologicalAgeDetailsView()
          } label: {
            Text("Bio Age: \(Int(bioAge)) \(Image(systemSymbol: .chevronForward))")
              .font(.title3)
              .bold()
              .fontDesign(.rounded)
          }
          .buttonStyle(.plain)

          if let result = biologicalAgeViewModel.biologicalAgeResult {
            Text("Calculated \(result.lastCalculated, format: .relative(presentation: .named))")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text(result.confidence.displayName)
              .font(.caption)
              .foregroundStyle(result.confidence.color)
          }
        } else {
          Text("Age: \(healthManager.age())")
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
