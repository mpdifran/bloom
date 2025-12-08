//
//  PrivacyAIFeatureOptInCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-01.
//

import SwiftUI

struct PrivacyAIFeatureOptInCell<IconView: View>: View {

  let title: String
  let subtitle: String
  @Binding var isEnabled: Bool
  let iconBuilder: () -> IconView

  init(
    title: String,
    subtitle: String,
    isEnabled: Binding<Bool>,
    @ViewBuilder iconBuilder: @escaping () -> IconView
  ) {
    self.title = title
    self.subtitle = subtitle
    self._isEnabled = isEnabled
    self.iconBuilder = iconBuilder
  }

  var body: some View {
    Toggle(isOn: $isEnabled) {
      HStack {
        iconBuilder()
          .padding(.trailing, 8)

        VStack(alignment: .leading) {
          Text(title)
            .font(.body)
            .bold()
            .fontDesign(.rounded)
            .minimumScaleFactor(0.7)
            .lineLimit(2)

          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
      }
      .frame(minHeight: 60)
    }
    .fixedSize(horizontal: false, vertical: true)
    .animation(.default, value: isEnabled)
  }
}

#Preview {
  @Previewable @State var isEnabled = false

  PreviewEnvironment {
    BloomScrollView {
      PrivacyAIFeatureOptInCell(
        title: "Today Insights",
        subtitle: "Personalized daily insights from your data.",
        isEnabled: $isEnabled) {
          TodayInsightsIcon(isEnabled: true)
            .frame(width: 40)
        }
        .cardContainer()
    }
  }
}
