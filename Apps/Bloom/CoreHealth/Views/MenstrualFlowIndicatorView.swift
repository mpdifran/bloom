//
//  MenstrualFlowIndicatorView.swift
//  CoreHealth
//
//  Created by Mark DiFranco on 2025-02-03.
//

import SwiftUI
import HealthKit
import BloomFoundation

public struct MenstrualFlowIndicatorView: View {
  public let flow: HKCategoryValueVaginalBleeding
  public let isSelected: Bool

  public init(flow: HKCategoryValueVaginalBleeding, isSelected: Bool) {
    self.flow = flow
    self.isSelected = isSelected
  }

  public var body: some View {
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
