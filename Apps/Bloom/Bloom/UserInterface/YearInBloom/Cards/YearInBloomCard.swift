//
//  YearInBloomCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-15.
//

import SwiftUI
import SFSafeSymbols

extension YearInBloomCard {
  enum Trend {
    case decreasing
    case neutral
    case increasing
  }
}

struct YearInBloomCard<FS, BS, Content>: View where FS: ShapeStyle, BS: ShapeStyle, Content: View {
  let title: String
  let focusStat: String
  let focusStatLabel: String
  let includePadding: Bool
  let includeDivider: Bool
  let foregroundFill: FS
  let backgroundFill: BS
  let content: () -> Content

  init(
    title: String,
    focusStat: String,
    focusStatLabel: String,
    includePadding: Bool = true,
    includeDivider: Bool = true,
    foregroundFill: FS = ForegroundStyle.foreground,
    backgroundFill: BS = BackgroundStyle.background,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.focusStat = focusStat
    self.focusStatLabel = focusStatLabel
    self.includePadding = includePadding
    self.includeDivider = includeDivider
    self.foregroundFill = foregroundFill
    self.backgroundFill = backgroundFill
    self.content = content
  }

  var body: some View {
    VStack {
      HStack {
        VStack(alignment: .leading) {
          Text(title)
            .font(.caption)
            .bold()
            .foregroundStyle(foregroundFill)

          VStack(alignment: .leading, spacing: 0) {
            Text(focusStat)
              .font(.system(size: 40))
            Text(focusStatLabel.uppercased())
              .font(.caption)
          }
          .fontWeight(.heavy)
        }

        Spacer()
      }
      .foregroundStyle(foregroundFill)
      .fontDesign(.rounded)
      .if(!includePadding) {
        $0.padding(.horizontal)
          .padding(.top)
      }

      if includeDivider {
        Divider()
      }

      content()
    }
    .cardContainer(fill: backgroundFill, includePadding: includePadding)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomCard(
        title: "Exercise Minutes",
        focusStat: "12,000",
        focusStatLabel: "Zone Minutes",
        foregroundFill: .black,
        backgroundFill: .mutedPink) {
          Text("Hello World")
            .frame(height: 160)
        }

      YearInBloomCard(
        title: "vO2 Max",
        focusStat: "38.1",
        focusStatLabel: "ML/KG/min",
        foregroundFill: .mutedRed,
        backgroundFill: .black) {
          Text("Hello World")
            .frame(height: 160)
        }
    }
  }
}
