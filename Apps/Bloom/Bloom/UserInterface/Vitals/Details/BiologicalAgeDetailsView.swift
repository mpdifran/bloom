//
//  BiologicalAgeDetailsView.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck
import CoreHealth
import BloomModel

struct BiologicalAgeDetailsView: View {

  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared

  var body: some View {
    Group {
      if let response = biologicalAgeViewModel.lastCalculatedResponse {
        contentView(response: response)
      } else {
        emptyView
      }
    }
    .groupedBackground()
    .navigationTitle("Biological Age")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      TelemetryDeck.viewScreen("Biological Age Details")
    }
  }
}

private extension BiologicalAgeDetailsView {

  func contentView(response: BiologicalAgeResponse) -> some View {
    BloomScrollView {
      // Biological Age Meter
      BiologicalAgeMeter(biologicalAge: response.biologicalAge)
        .frame(square: 250)
        .horizontallyCentered()
        .padding(.bottom)

      // Summary Card
      TodayCardCell(
        symbol: .heartTextSquare,
        title: "Summary",
        content: response.summary,
        color: .mutedBlue
      )

      // Positive Factors Card
      if response.positiveFactors.isNotEmpty {
        SectionTitleView("Positive Factors")

        ForEach(response.positiveFactors) { factor in
          FactorCell(symbol: .checkmarkCircleFill, factor: factor)
            .tint(.mutedGreen)
        }
      }

      // Negative Factors Card
      if response.negativeFactors.isNotEmpty {
        SectionTitleView("Negative Factors")

        ForEach(response.negativeFactors) { factor in
          FactorCell(symbol: .exclamationmarkTriangleFill, factor: factor)
            .tint(.mutedYellow)
        }
      }
    }
  }

  var emptyView: some View {
    BloomScrollView {
      VStack(spacing: 20) {
        Image(systemSymbol: .heartTextSquare)
          .font(.system(size: 60))
          .foregroundColor(.secondary.opacity(0.5))

        Text("No Biological Age Data")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Text("Your biological age will appear here once calculated. Check back after using the app for a few days.")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .cardContainer()
    }
  }

  func formatFactors(_ factors: [String]) -> String {
    factors.map { "• \($0)" }.joined(separator: "\n")
  }
}

struct FactorCell: View {

  let symbol: SFSymbol
  let factor: String

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
        .font(.title2)
        .foregroundStyle(.tint)

      Text(factor)
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.leading)

      Spacer(minLength: 0)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BiologicalAgeDetailsView()
    }
  }
}
