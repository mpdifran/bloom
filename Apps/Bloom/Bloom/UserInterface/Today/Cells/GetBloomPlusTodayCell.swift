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
    VStack(alignment: .leading, spacing: 0) {
      Image(.budLounging)
        .resizable()
        .scaledToFill()
        .frame(height: 200)
        .clipped()

      VStack {
        Text("Get personalized insights on what’s boosting (or bumming out) your health. It’s like x-ray vision for your wellness.")
          .font(.body)
          .foregroundStyle(.secondary)
          .padding(.bottom)

        Button {
          TelemetryDeck.signal("Today View Upsell")
          presentedSheet = BloomPlusPaywall(focus: .todayInsights, showDismiss: true).asAny
        } label: {
          Label("Unlock Insights", systemSymbol: .sparkles)
            .horizontallyCentered()
        }
        .buttonStyle(.tertiary)
      }
      .padding()
    }
    .overlay {
      Button {
        TelemetryDeck.signal("Today View Upsell Dismissed")
        hasDismissed = true
      } label: {
        Image(systemSymbol: .xmarkCircleFill)
          .font(.title)
          .foregroundStyle(.primary, .thickMaterial)
      }
      .frame(square: 44)
      .padding(8)
      .zStackAlignment(.topTrailing)
    }
    .cardContainer(includePadding: false)
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
