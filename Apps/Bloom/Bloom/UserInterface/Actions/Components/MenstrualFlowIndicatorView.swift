//
//  MenstrualFlowIndicatorView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI
import HealthKit

struct MenstrualFlowIndicatorView: View {
  let flow: HKCategoryValueMenstrualFlow
  let isSelected: Bool

  var body: some View {
    VStack {
      Capsule()
        .fill(.background.secondary)
        .aspectRatio(0.7, contentMode: .fit)
        .frame(maxWidth: 45)
        .overlay {
          if isSelected {
            Capsule()
              .stroke(.mutedPink, lineWidth: 2)
          }
        }
        .overlay {
          VStack {
            switch flow {
            case .light:
              Circle()
                .fill(.mutedPink)
                .padding(8)
            case .medium:
              Circle()
                .fill(.mutedPink)
                .padding(4)
            case .heavy:
              Circle()
                .fill(.mutedPink)
            case .none, .unspecified:
              EmptyView()
            @unknown default:
              EmptyView()
            }

            Spacer()
          }
          .padding(6)
        }

      Text(flow.name)
        .font(.caption)
        .fontDesign(.rounded)
        .bold()
    }
  }
}

#Preview {
  HStack {
    MenstrualFlowIndicatorView(flow: .none, isSelected: false)
    MenstrualFlowIndicatorView(flow: .light, isSelected: true)
    MenstrualFlowIndicatorView(flow: .medium, isSelected: false)
    MenstrualFlowIndicatorView(flow: .heavy, isSelected: false)
  }
}
