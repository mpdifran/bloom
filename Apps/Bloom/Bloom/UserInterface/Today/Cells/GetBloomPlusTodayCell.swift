//
//  GetBloomPlusTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import AppUI

struct GetBloomPlusTodayCell: View {

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      BudImage(.budCoach, dimension: 200)
        .horizontallyCentered()

      Text("See How Healthy You Really Are")
        .font(.title2)
        .fontDesign(.rounded)
        .bold()

      Text("Daily insights on your sleep, nutrition, and activity, so you know exactly what’s helping (and what’s holding you back).")
        .font(.body)
        .foregroundStyle(.secondary)
        .padding(.bottom)

      Button {
        presentedSheet = BloomPlusPaywall(showDismiss: true).asAny
      } label: {
        Label("Unlock Insights", systemSymbol: .sparkles)
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .cardContainer()
    .sheet($presentedSheet)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      GetBloomPlusTodayCell()
    }
  }
}
