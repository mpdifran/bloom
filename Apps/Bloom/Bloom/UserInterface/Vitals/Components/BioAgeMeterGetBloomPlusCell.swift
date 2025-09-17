//
//  BioAgeMeterGetBloomPlusCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-17.
//

import SwiftUI
import TelemetryDeck

struct BioAgeMeterGetBloomPlusCell: View {

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack(alignment: .leading) {
      BiologicalAgeMeter(biologicalAge: nil)
        .frame(square: 250)
        .horizontallyCentered()
        .premiumLocked("How old are you really?")

      Text("See how your lifestyle shapes your body’s biological age.")
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom)

      Button {
        TelemetryDeck.signal("Biological Age Upsell")
        presentedSheet = BloomPlusPaywall(focus: .biologicalAge, showDismiss: true).asAny
      } label: {
        Label("Unlock My True Age", systemSymbol: .sparkles)
          .horizontallyCentered()
      }
      .buttonStyle(.tertiary)
    }
    .cardContainer()
    .sheet($presentedSheet)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BioAgeMeterGetBloomPlusCell()
    }
  }
}
