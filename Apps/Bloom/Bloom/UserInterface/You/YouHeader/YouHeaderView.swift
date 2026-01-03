//
//  YouHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-02.
//

import SwiftUI
import CoreHealth

struct YouHeaderView: View {
  @StateObject private var entitlementController = EntitlementController.shared
  @ObservedObject private var healthManager = HealthManager.shared
  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared

  @State private var presentedSheet: AnyView?

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

          if let lastCalculated = biologicalAgeViewModel.biologicalAgeResult?.lastCalculated {
            Text("Calculated \(lastCalculated, format: .relative(presentation: .named))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        } else {
          Text("Age: \(healthManager.age())")
        }

        if entitlementController.hasBloomPro != true {
          Button {
            EntitledAction(presentedSheet: $presentedSheet, focus: .biologicalAge) {
              // Do nothing
            }
          } label: {
            Text("Calculate Your Bio Age")
          }
          .buttonStyle(.secondary)
        }
      }

      Spacer(minLength: 0)
    }
    .sheet($presentedSheet)
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
