//
//  MonitorStateBadge.swift
//  Bloom
//

import SwiftUI

/// A badge displaying a monitor state (Normal, Attention, Alert, etc.)
struct MonitorStateBadge: View {

  let state: MonitorStateValue

  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(textColor)
        .frame(square: 10)
      Text(state.displayName)
        .foregroundStyle(.text)
    }
    .font(.caption2)
    .fontWeight(.medium)
    .fontDesign(.rounded)
    .padding(.leading, 6)
    .padding(.trailing, 10)
    .padding(.vertical, 5)
    .background(textColor.tertiary, in: Capsule())
  }

  private var textColor: Color {
    switch state {
    case .good:
      return .monitorTypical
    case .attention:
      return .monitorLow
    case .alert:
      return .monitorHigh
    case .unavailable:
      return .gray
    case .encourage:
      return .mutedOrange
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        Text("Good")
        Spacer()
        MonitorStateBadge(state: .good)
      }

      HStack {
        Text("Attention")
        Spacer()
        MonitorStateBadge(state: .attention)
      }

      HStack {
        Text("Alert")
        Spacer()
        MonitorStateBadge(state: .alert)
      }

      HStack {
        Text("Encourage")
        Spacer()
        MonitorStateBadge(state: .encourage)
      }

      HStack {
        Text("Unavailable")
        Spacer()
        MonitorStateBadge(state: .unavailable)
      }
    }
  }
}
