//
//  GetBloomPlusTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct GetBloomPlusTodayCell: View {

  @AppStorage("GetBloomPlusTodayCell.hasDismissed") private var hasDismissed = false
  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        iconView

        Text("See How Healthy You Really Are")
          .font(.title3)
          .fontDesign(.rounded)
          .bold()

        Spacer()

        Button {
          TelemetryDeck.signal("Today View Upsell Dismissed")
          hasDismissed = true
        } label: {
          Image(systemSymbol: .xmarkCircleFill)
            .font(.title)
            .foregroundStyle(.white, .fill)
        }
        .frame(square: 44)
      }

      Text("Daily insights on your sleep, nutrition, and activity, so you know exactly what’s helping (and what’s holding you back).")
        .font(.body)
        .foregroundStyle(.secondary)
        .padding(.bottom)

      Button {
        TelemetryDeck.signal("Today View Upsell")
        presentedSheet = BloomPlusPaywall(showDismiss: true).asAny
      } label: {
        Label("Unlock Insights", systemSymbol: .sparkles)
          .horizontallyCentered()
      }
      .buttonStyle(.tertiary)
    }
    .cardContainer()
    .sheet($presentedSheet)
  }
}

private extension GetBloomPlusTodayCell {

  var iconView: some View {
    Image(systemSymbol: .sparkles)
      .font(.title3)
      .foregroundStyle(.white)
      .frame(square: 30)
      .padding(6)
      .background {
        RoundedRectangle(cornerRadius: 13)
          .fill(.tint)
      }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      GetBloomPlusTodayCell()
    }
  }
}
