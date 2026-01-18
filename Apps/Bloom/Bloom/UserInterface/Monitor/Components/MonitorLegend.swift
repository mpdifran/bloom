//
//  MonitorLegend.swift
//  Bloom
//

import SwiftUI
import AppUI

/// A legend explaining the visual elements in the monitor summary bars.
struct MonitorLegend: View {

  var body: some View {
    VStack(alignment: .leading) {
      Text("Legend")
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)

      HStack {
        // Current value legend item
        HStack(spacing: 8) {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.monitorLow, Color.monitorTypical, Color.monitorHigh],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(square: 18)
            .overlay {
              Circle()
                .fill(Color.black)
                .frame(square: 12)
            }

          Text("Current Value")
            .font(.caption)
            .bold()
        }

        // 7-day range legend item
        HStack(spacing: 8) {
          Capsule()
            .fill(LinearGradient(
              colors: [Color.monitorLow, Color.monitorTypical, Color.monitorHigh],
              startPoint: .leading,
              endPoint: .trailing
            ))
            .frame(width: 36, height: 16)
          Text("7-Day Range")
            .font(.caption)
            .bold()
        }

        Spacer()
      }
    }
    .horizontalAlignment(.leading)
    .cardContainer()
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MonitorLegend()
    }
  }
}
